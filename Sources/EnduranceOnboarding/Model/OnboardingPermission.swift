import Foundation
import UserNotifications

public enum OnboardingPermissionStatus: String, Sendable, Equatable {
    case notDetermined = "not_determined"
    case granted
    case denied
}

/// How to read and request a permission. The package never fakes a request:
/// `request` must show the real system prompt.
public struct OnboardingPermission: Sendable {
    public var status: @MainActor @Sendable () async -> OnboardingPermissionStatus
    public var request: @MainActor @Sendable () async -> OnboardingPermissionStatus

    public init(
        status: @escaping @MainActor @Sendable () async -> OnboardingPermissionStatus,
        request: @escaping @MainActor @Sendable () async -> OnboardingPermissionStatus
    ) {
        self.status = status
        self.request = request
    }

    /// Local/push notifications through `UNUserNotificationCenter`.
    /// Provisional and ephemeral authorization count as granted.
    public static func notifications(
        options: UNAuthorizationOptions = [.alert, .sound, .badge]
    ) -> OnboardingPermission {
        OnboardingPermission(
            status: {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                switch settings.authorizationStatus {
                case .notDetermined: return .notDetermined
                case .denied: return .denied
                default: return .granted
                }
            },
            request: {
                let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
                return granted ? .granted : .denied
            }
        )
    }
}
