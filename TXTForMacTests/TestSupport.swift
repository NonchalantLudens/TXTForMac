import Foundation
@testable import TXTForMac

/// 测试用广播器：记录配置变更通知次数，不触达真实系统通知。
final class SpyBroadcaster: SettingsChangeBroadcaster, @unchecked Sendable {
    private(set) var changeCount = 0

    func postChange() {
        changeCount += 1
    }
}
