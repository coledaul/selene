#!/bin/bash

# Selene 构建脚本
# 用于构建 Android、iOS 无签名版本和 macOS universal 版本，并整理构建产物

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本信息
APP_VERSION=""

# 读取版本号
read_version() {
    log_info "读取项目版本号..."
    
    # 从 pubspec.yaml 中提取版本号
    if [ -f "pubspec.yaml" ]; then
        APP_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | tr -d ' ')
        if [ -z "$APP_VERSION" ]; then
            log_error "无法从 pubspec.yaml 中读取版本号"
            exit 1
        fi
        APP_VERSION=$(echo "$APP_VERSION" | cut -d'+' -f1)
        if [ -z "$APP_VERSION" ]; then
            log_error "无法从 pubspec.yaml 中读取版本号"
            exit 1
        fi
        log_success "项目版本号: $APP_VERSION"
    else
        log_error "pubspec.yaml 文件不存在"
        exit 1
    fi
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Flutter 环境
check_flutter() {
    log_info "检查 Flutter 环境..."
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未安装或未添加到 PATH"
        exit 1
    fi
    
    flutter --version
    log_success "Flutter 环境检查通过"
}

# 清理之前的构建
clean_build() {
    log_info "清理之前的构建..."
    flutter clean
    
    # 清理自定义构建目录
    rm -rf ios-build
    rm -rf dist
    rm -rf build-macos-universal
    
    log_success "构建清理完成"
}

# 获取依赖
get_dependencies() {
    log_info "获取项目依赖..."
    pub_hosted_url="$(sed -n 's/^[[:space:]]*url: "\([^"]*\)"/\1/p' pubspec.lock | sort -u)"
    if [ -z "$pub_hosted_url" ] || [ "$(printf '%s\n' "$pub_hosted_url" | wc -l | tr -d ' ')" -ne 1 ]; then
        log_error "pubspec.lock 必须只包含一个托管依赖源"
        exit 1
    fi
    PUB_HOSTED_URL="$pub_hosted_url" flutter pub get --enforce-lockfile
    log_success "依赖获取完成"
}

# 构建安卓版本
build_android() {
    if [ "$BUILD_ANDROID" = true ] && [ "$BUILD_ANDROID_ARMV7" = true ]; then
        log_info "开始构建安卓 armv8 和 armv7a 版本..."
    else
        log_info "开始构建安卓 armv8 版本..."
    fi
    
    # 确保安卓构建目录存在
    mkdir -p build/android
    
    # 构建 APK，添加优化参数
    flutter build apk --release \
        --target-platform "$ANDROID_TARGET_PLATFORMS" \
        --split-per-abi \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols
    
    log_success "安卓构建完成"
}

# 构建并验证 macOS universal 版本
build_macos() {
    log_info "开始构建 macOS universal 版本..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "macOS 构建只能在 macOS 上进行"
        return 1
    fi
    
    flutter build macos --release

    local app_path="build/macos/Build/Products/Release/Selene.app"
    if [ ! -d "$app_path" ]; then
        log_error "macOS 应用构建失败"
        return 1
    fi

    local executable_name
    executable_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$app_path/Contents/Info.plist")
    local executable_path="$app_path/Contents/MacOS/$executable_name"
    local architectures
    architectures=$(lipo -archs "$executable_path")
    for architecture in arm64 x86_64; do
        if [[ " $architectures " != *" $architecture "* ]]; then
            log_error "macOS 可执行文件缺少 $architecture 架构，实际为: $architectures"
            return 1
        fi
    done

    mkdir -p build-macos-universal
    ditto "$app_path" build-macos-universal/Selene.app
    
    log_success "macOS universal 构建完成（$architectures）"
}

# 构建 iOS 无签名版本
build_ios() {
    log_info "开始构建 iOS 无签名版本..."
    
    # 检查是否在 macOS 上
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "iOS 构建只能在 macOS 上进行，跳过 iOS 构建"
        return
    fi
    
    # 确保 iOS 构建目录存在
    mkdir -p build/ios
    
    # 构建 iOS 无签名版本
    flutter build ios --release --no-codesign
    
    # 检查构建是否成功
    if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
        log_error "iOS 应用构建失败"
        return 1
    fi
    
    # 创建 .ipa 文件
    log_info "创建 iOS .ipa 文件..."
    
    # 确保 ios-build 目录存在
    mkdir -p ios-build
    
    cd build/ios/iphoneos
    
    # 创建 Payload 目录
    mkdir -p Payload
    cp -r Runner.app Payload/
    
    # 创建 .ipa 文件
    zip -r "../../../ios-build/Runner.ipa" Payload/
    
    # 清理临时文件
    rm -rf Payload
    
    cd ../../..
    
    log_success "iOS 构建完成"
}

# 复制构建产物到根目录
copy_artifacts() {
    log_info "复制构建产物到根目录..."
    
    # 创建输出目录
    mkdir -p dist
    
    # 复制安卓 APK
    if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
        cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "dist/selene-${APP_VERSION}-armv8.apk"
        log_success "安卓 arm64 APK 已复制到 dist/selene-${APP_VERSION}-armv8.apk"
    elif [ "$BUILD_ANDROID" = true ]; then
        log_error "安卓 arm64 APK 文件未找到"
        return 1
    fi
    if [ "$BUILD_ANDROID_ARMV7" = true ]; then
        if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
            cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "dist/selene-${APP_VERSION}-armv7a.apk"
            log_success "安卓 armv7a APK 已复制到 dist/selene-${APP_VERSION}-armv7a.apk"
        else
            log_error "安卓 armv7a APK 文件未找到"
            return 1
        fi
    fi

    # 复制 iOS 构建产物
    if [ "$BUILD_IOS" = true ]; then
        if [ -f "ios-build/Runner.ipa" ]; then
            cp ios-build/Runner.ipa "dist/selene-${APP_VERSION}.ipa"
            log_success "iOS .ipa 文件已复制到 dist/selene-${APP_VERSION}.ipa"
        else
            log_error "iOS .ipa 文件未找到"
            return 1
        fi
    fi
    
    # 打包已验证的 macOS universal 应用
    if [ "$BUILD_MACOS" = true ] && [ -d "build-macos-universal/Selene.app" ]; then
        log_info "打包 macOS universal 应用为 DMG..."
        
        DMG_NAME="selene-${APP_VERSION}-macos-universal.dmg"
        DMG_PATH="dist/${DMG_NAME}"
        
        TMP_DMG_DIR=$(mktemp -d)
        ditto build-macos-universal/Selene.app "$TMP_DMG_DIR/Selene.app"
        
        if ! hdiutil create -volname "Selene" \
                -srcfolder "$TMP_DMG_DIR" \
                -ov -format UDZO \
                "$DMG_PATH"; then
            rm -rf "$TMP_DMG_DIR"
            log_error "macOS DMG 创建失败"
            return 1
        fi
        
        rm -rf "$TMP_DMG_DIR"
        
        log_success "macOS universal 应用已打包到 ${DMG_PATH}"
    elif [ "$BUILD_MACOS" = true ]; then
        log_error "macOS universal 应用文件未找到"
        return 1
    fi
    
    log_success "构建产物复制完成"
}

# 显示构建结果
show_results() {
    log_info "构建结果:"
    echo ""
    
    if [ -d "dist" ]; then
        echo "📁 构建产物目录:"
        ls -la dist/
        echo ""
        
        echo "📊 文件大小:"
        du -h dist/*
        echo ""
        
        log_success "所有构建产物已保存到 dist/ 目录"
    else
        log_warning "未找到构建产物"
    fi
}

# 主函数
main() {
    echo "🚀 Selene 构建脚本启动"
    echo "=================================="
    
    # 检查参数
    BUILD_ANDROID=true
    BUILD_IOS=true
    BUILD_MACOS=true
    BUILD_ANDROID_ARMV7=true
    ANDROID_TARGET_PLATFORMS="android-arm64,android-arm"
    PARALLEL_BUILD=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --android-only)
                BUILD_IOS=false
                BUILD_MACOS=false
                shift
                ;;
            --android-arm64-only)
                BUILD_IOS=false
                BUILD_MACOS=false
                BUILD_ANDROID_ARMV7=false
                ANDROID_TARGET_PLATFORMS="android-arm64"
                shift
                ;;
            --ios-only)
                BUILD_ANDROID=false
                BUILD_MACOS=false
                shift
                ;;
            --macos-only)
                BUILD_ANDROID=false
                BUILD_IOS=false
                PARALLEL_BUILD=false
                shift
                ;;
            --apple-only)
                BUILD_ANDROID=false
                PARALLEL_BUILD=false
                shift
                ;;
            --sequential)
                PARALLEL_BUILD=false
                shift
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  --android-only         只构建 Android ARM64 与 ARMv7 版本"
                echo "  --android-arm64-only   只构建 Android ARM64 版本"
                echo "  --ios-only             只构建 iOS 版本"
                echo "  --macos-only           构建并验证 macOS universal 版本"
                echo "  --apple-only           构建所有 Apple 平台版本（iOS 和 macOS）"
                echo "  --sequential           顺序构建（默认为并行构建）"
                echo "  --help                 显示此帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done

    # CocoaPods 与 Apple 平台生成目录存在共享写入，Apple 构建必须顺序执行。
    if [ "$BUILD_IOS" = true ] || [ "$BUILD_MACOS" = true ]; then
        PARALLEL_BUILD=false
    fi
    
    # 执行构建流程
    read_version
    check_flutter
    clean_build
    get_dependencies
    
    # 并行构建模式
    if [ "$PARALLEL_BUILD" = true ]; then
        log_info "启用并行构建模式..."
        
        # 使用后台进程并行构建
        pids=()
        
        if [ "$BUILD_ANDROID" = true ]; then
            build_android &
            pids+=($!)
        fi
        
        if [ "$BUILD_IOS" = true ]; then
            build_ios &
            pids+=($!)
        fi
        
        if [ "$BUILD_MACOS" = true ]; then
            build_macos &
            pids+=($!)
        fi
        
        # 等待所有后台进程完成
        log_info "等待所有构建任务完成..."
        failed=0
        for pid in "${pids[@]}"; do
            if ! wait "$pid"; then
                log_warning "构建进程 $pid 失败"
                failed=1
            fi
        done

        if [ "$failed" -ne 0 ]; then
            log_error "至少一个并行构建任务失败"
            exit 1
        fi
        
        log_success "所有并行构建任务已完成"
    else
        # 顺序构建模式
        if [ "$BUILD_ANDROID" = true ]; then
            build_android
        fi
        
        if [ "$BUILD_IOS" = true ]; then
            build_ios
        fi
        
        if [ "$BUILD_MACOS" = true ]; then
            build_macos
        fi
    fi
    
    copy_artifacts
    show_results
    
    # 清理临时构建目录
    log_info "清理临时构建目录..."
    rm -rf build
    rm -rf build-macos-universal
    log_success "临时构建目录已清理"
    
    echo "=================================="
    log_success "构建完成！"
}

# 运行主函数
main "$@"
