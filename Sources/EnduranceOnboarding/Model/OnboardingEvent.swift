import Foundation

/// Analytics hooks. Map them to Firebase with `event.name` and
/// `event.parameters` (snake_case, Firebase-safe values).
public enum OnboardingEvent: Sendable, Equatable {
    case stepViewed(key: String, index: Int)
    case stepCompleted(key: String, index: Int)
    /// Fired on every selection change with the current values for `key`.
    case answerSelected(key: String, values: [String])
    /// `wasPrompted` is false when the step was skipped because the
    /// permission was already decided.
    case permissionResult(key: String, status: OnboardingPermissionStatus, wasPrompted: Bool)
    case skipped(key: String, index: Int)
    /// Seconds from the first step to the end of the flow.
    case finished(duration: TimeInterval)

    /// Firebase event name, e.g. `onboarding_step_viewed`.
    public var name: String {
        switch self {
        case .stepViewed: "onboarding_step_viewed"
        case .stepCompleted: "onboarding_step_completed"
        case .answerSelected: "onboarding_answer_selected"
        case .permissionResult: "onboarding_permission_result"
        case .skipped: "onboarding_step_skipped"
        case .finished: "onboarding_finished"
        }
    }

    /// Firebase parameters (values are `String`, `Int` or `Double`).
    public var parameters: [String: Any] {
        switch self {
        case .stepViewed(let key, let index),
             .stepCompleted(let key, let index),
             .skipped(let key, let index):
            ["step_key": key, "step_index": index]
        case .answerSelected(let key, let values):
            ["step_key": key, "values": values.joined(separator: ",")]
        case .permissionResult(let key, let status, let wasPrompted):
            ["step_key": key, "status": status.rawValue, "was_prompted": wasPrompted ? 1 : 0]
        case .finished(let duration):
            ["duration_seconds": (duration * 10).rounded() / 10]
        }
    }
}
