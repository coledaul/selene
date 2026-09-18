# macOS 钥匙串回归

先执行 `flutter pub get`，再在 macOS 上运行：

```bash
bash test/macos_secure_storage_test.sh
```

测试直接编译当前依赖中的官方 Swift 实现，验证传统钥匙串的空读取、写入、覆盖、跨实例读取与重复删除。只使用随机服务名下的测试值，结束时清理，不访问真实账号。

Dart 参数与错误传播由 `test/credential_service_test.dart` 覆盖。原生测试不替代安装包签名、跨版本升级和各平台真机验收。
