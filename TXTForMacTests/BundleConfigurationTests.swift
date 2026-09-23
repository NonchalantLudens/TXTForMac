import XCTest

@testable import TXTForMac

/// 守护 Info.plist 中的关键声明：Bundle 标识、最低系统版本与双语声明。
/// 这些值一旦回归会直接影响分发与本地化，属于必须被测试锁住的事实。
final class BundleConfigurationTests: XCTestCase {
    func testAppBundleDeclaresExpectedIdentifier() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "online.nonchalantludens.txtformac")
    }

    func testAppBundleDeclaresMinimumSystemVersion() {
        let minimumSystemVersion = Bundle.main.object(
            forInfoDictionaryKey: "LSMinimumSystemVersion"
        ) as? String

        XCTAssertEqual(minimumSystemVersion, "15.0")
    }

    func testAppBundleDeclaresBothLocalizations() {
        let localizations = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleLocalizations"
        ) as? [String]

        XCTAssertEqual(Set(localizations ?? []), ["en", "zh-Hans"])
    }
}
