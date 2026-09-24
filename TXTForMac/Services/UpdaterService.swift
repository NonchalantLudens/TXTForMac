import Foundation
import Sparkle

/// 更新服务（T-044/T-045）：Sparkle 的唯一封装点。
///
/// 安全边界（ADR-003）：更新包经 EdDSA 签名校验，公钥在 Info.plist，
/// 私钥只存本机钥匙串；校验失败 Sparkle 会拒绝安装。
@MainActor
final class UpdaterService {
    static let shared = UpdaterService()

    private let controller: SPUStandardUpdaterController

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        applyScheduledInterval(SettingsStore.shared.settings.updateCheckFrequency)
    }

    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    /// 手动检查更新（应用菜单入口）。
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    /// 把设置页的检查频率映射到 Sparkle 的调度间隔。
    func applyScheduledInterval(_ frequency: CheckUpdateFrequency) {
        let seconds: TimeInterval = switch frequency {
        case .daily: 86400
        case .weekly: 7 * 86400
        case .monthly: 30 * 86400
        case .never: 0
        }
        controller.updater.updateCheckInterval = seconds
    }
}
