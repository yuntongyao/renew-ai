import UIKit
import UserNotifications

extension Notification.Name {
    /// 点通知进入决策页（需求 12.1 验收用例 3）
    static let openDecisionFromNotification = Notification.Name("shouldRenew.openDecision")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 前台时也以横幅展示，方便验收「能收到一条通知」
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let idString = response.notification.request.content.userInfo["subscriptionID"] as? String,
           let id = UUID(uuidString: idString) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .openDecisionFromNotification, object: id)
            }
        }
        completionHandler()
    }
}
