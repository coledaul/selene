import Foundation
import Security

/// 编译并调用实际锁定的插件实现，而不是模拟 MethodChannel 成功。
@main
enum MacOSKeychainTest {
    static func main() {
        let storage = FlutterSecureStorage()
        let service = "org.moontechlab.selene.test.\(UUID().uuidString)"
        let key = "credential-regression"
        let params = KeychainQueryParameters(
            key: key,
            service: service,
            isSynchronizable: false,
            accessibilityLevel: "unlocked",
            usesDataProtectionKeychain: false,
            shouldReturnData: true
        )
        var failures = 0
        func check(_ condition: Bool, _ label: String) {
            print("\(condition ? "PASS" : "FAIL"): \(label)")
            if !condition { failures += 1 }
        }
        func checkStatus(_ status: OSStatus, _ label: String) {
            check(status == errSecSuccess, "\(label) (\(status))")
        }

        // 只使用随机服务名下的测试值，绝不读取真实登录密码。
        checkStatus(storage.delete(params: params).status, "delete missing password")
        let missing = storage.read(params: params)
        check(missing.status == errSecSuccess && missing.value == nil, "read missing password")
        checkStatus(storage.write(params: params, value: "test-first").status, "save password")
        let first = storage.read(params: params)
        check(first.status == errSecSuccess && first.value as? String == "test-first", "read back password")
        checkStatus(storage.write(params: params, value: "test-second").status, "replace password")
        let second = FlutterSecureStorage().read(params: params)
        check(second.status == errSecSuccess && second.value as? String == "test-second", "read from new instance")
        checkStatus(storage.delete(params: params).status, "delete password")
        checkStatus(storage.delete(params: params).status, "delete password again")
        let removed = storage.read(params: params)
        check(removed.status == errSecSuccess && removed.value == nil, "password is gone")

        // 插件回归失败时也精确清理本次测试项，不使用 deleteAll 或操作用户钥匙串设置。
        let cleanup: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: service,
            kSecAttrSynchronizable: false,
        ]
        let status = SecItemDelete(cleanup as CFDictionary)
        check(status == errSecSuccess || status == errSecItemNotFound, "clean up test item")
        exit(failures == 0 ? 0 : 1)
    }
}
