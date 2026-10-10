import Foundation
import Observation

/// Navigation, answers and events of a flow. `OnboardingView` owns one; it is
/// public so the logic can be driven and tested without UI.
@MainActor
@Observable
public final class OnboardingController {

    enum Direction { case forward, backward }

    /// Steps the user will actually see (permission steps that were already
    /// decided are removed by `start()`).
    public private(set) var steps: [OnboardingStep]
    public private(set) var currentIndex = 0
    public private(set) var answers: OnboardingAnswers = [:]
    public private(set) var isFinished = false
    /// False until `start()` resolved permission statuses.
    public private(set) var isReady: Bool
    public private(set) var isRequestingPermission = false
    private(set) var direction: Direction = .forward

    let options: OnboardingOptions
    private let onEvent: @MainActor (OnboardingEvent) -> Void
    private let onFinish: @MainActor (OnboardingAnswers) -> Void
    private let now: @MainActor () -> Date
    private var startDate: Date?
    private var hasStarted = false

    public init(
        flow: OnboardingFlow,
        now: @escaping @MainActor () -> Date = { Date() },
        onFinish: @escaping @MainActor (OnboardingAnswers) -> Void
    ) {
        steps = flow.steps
        options = flow.options
        onEvent = flow.analytics
        self.onFinish = onFinish
        self.now = now
        isReady = !flow.steps.contains { $0.type == .permission }
    }

    // MARK: State

    public var currentStep: OnboardingStep? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    public var stepCount: Int { steps.count }
    public var isLastStep: Bool { currentIndex >= steps.count - 1 }

    /// 0...1, safe for single-step and empty flows.
    public var progress: Double {
        guard !steps.isEmpty else { return 1 }
        return Double(min(currentIndex + 1, steps.count)) / Double(steps.count)
    }

    public var canGoBack: Bool {
        guard options.allowsBack, !isFinished, let step = currentStep, step.type != .loading else { return false }
        return previousIndex() != nil
    }

    public var canSkip: Bool {
        !isFinished && (currentStep?.isSkippable ?? false)
    }

    public var canContinue: Bool {
        guard isReady, !isFinished, let step = currentStep else { return false }
        switch step.kind {
        case .question(let question):
            return answer(for: step.key).count >= question.selection.minimum
        case .custom(let custom):
            return !custom.requiresAnswer || !answer(for: step.key).isEmpty
        case .permission:
            return !isRequestingPermission
        default:
            return true
        }
    }

    public func answer(for key: String) -> [String] {
        answers[key] ?? []
    }

    // MARK: Lifecycle

    /// Restores saved progress, skips permissions that were already decided
    /// and reports the first step. Safe to call more than once.
    public func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        startDate = now()

        if let saved = options.persistence?.load(),
           let index = steps.firstIndex(where: { $0.key == saved.stepKey }) {
            answers = saved.answers
            currentIndex = index
        }

        await resolveDecidedPermissions()
        isReady = true

        if steps.isEmpty {
            finish()
        } else {
            onEvent(.stepViewed(key: steps[currentIndex].key, index: currentIndex))
        }
    }

    private func resolveDecidedPermissions() async {
        let currentKey = currentStep?.key
        var removed: Set<String> = []
        for step in steps {
            guard case .permission(let payload) = step.kind else { continue }
            let status = await payload.permission.status()
            guard status != .notDetermined else { continue }
            removed.insert(step.key)
            answers[step.key] = [status.rawValue]
            onEvent(.permissionResult(key: step.key, status: status, wasPrompted: false))
        }
        guard !removed.isEmpty else { return }

        let original = steps
        steps.removeAll { removed.contains($0.key) }
        // Keep the user on the same step, or on the next visible one.
        if let currentKey, let start = original.firstIndex(where: { $0.key == currentKey }) {
            let nextKey = original[start...].first { !removed.contains($0.key) }?.key
            currentIndex = nextKey.flatMap { key in steps.firstIndex { $0.key == key } } ?? max(0, steps.count - 1)
        }
    }

    // MARK: Navigation

    /// Completes the current step and moves forward (or finishes).
    public func next() {
        guard canContinue, let step = currentStep else { return }
        onEvent(.stepCompleted(key: step.key, index: currentIndex))
        advance()
    }

    /// Skips the current step without storing an answer.
    public func skip() {
        guard isReady, canSkip, let step = currentStep else { return }
        answers[step.key] = nil
        onEvent(.skipped(key: step.key, index: currentIndex))
        advance()
    }

    public func back() {
        guard isReady, canGoBack, let target = previousIndex() else { return }
        direction = .backward
        currentIndex = target
        save()
        onEvent(.stepViewed(key: steps[target].key, index: target))
    }

    private func advance() {
        if currentIndex + 1 < steps.count {
            direction = .forward
            currentIndex += 1
            save()
            onEvent(.stepViewed(key: steps[currentIndex].key, index: currentIndex))
        } else {
            finish()
        }
    }

    /// Going back skips loading steps and permissions already answered.
    private func previousIndex() -> Int? {
        var index = currentIndex - 1
        while index >= 0 {
            let step = steps[index]
            let isAnsweredPermission = step.type == .permission && answers[step.key] != nil
            if step.type != .loading && !isAnsweredPermission { return index }
            index -= 1
        }
        return nil
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        options.persistence?.clear()
        let duration = startDate.map { now().timeIntervalSince($0) } ?? 0
        onEvent(.finished(duration: max(0, duration)))
        onFinish(answers)
    }

    private func save() {
        guard let persistence = options.persistence, let step = currentStep else { return }
        persistence.save(.init(stepKey: step.key, answers: answers))
    }

    // MARK: Answers

    /// Selects (single) or toggles (multiple) an option of the current question.
    public func toggle(optionID: String) {
        guard isReady, !isFinished, let step = currentStep, case .question(let question) = step.kind,
              question.options.contains(where: { $0.id == optionID }) else { return }

        var selected = Set(answer(for: step.key))
        switch question.selection {
        case .single:
            selected = [optionID]
        case .multiple(_, let maximum):
            if selected.contains(optionID) {
                selected.remove(optionID)
            } else if maximum.map({ selected.count < $0 }) ?? true {
                selected.insert(optionID)
            } else {
                return
            }
        }
        let values = question.options.map(\.id).filter(selected.contains)
        answers[step.key] = values.isEmpty ? nil : values
        save()
        onEvent(.answerSelected(key: step.key, values: values))
    }

    /// Stores a value for any step key (used by `.custom` steps).
    public func setAnswer(_ values: [String], for key: String) {
        answers[key] = values.isEmpty ? nil : values
        save()
        onEvent(.answerSelected(key: key, values: values))
    }

    /// Shows the real system prompt for the current permission step, stores
    /// the result and moves on whatever the user chose.
    public func requestPermission() async {
        guard isReady, !isFinished, !isRequestingPermission, let step = currentStep,
              case .permission(let payload) = step.kind else { return }
        isRequestingPermission = true
        let status = await payload.permission.request()
        isRequestingPermission = false
        guard !isFinished, currentStep?.key == step.key else { return }
        answers[step.key] = [status.rawValue]
        onEvent(.permissionResult(key: step.key, status: status, wasPrompted: true))
        onEvent(.stepCompleted(key: step.key, index: currentIndex))
        advance()
    }

    func context(for step: OnboardingStep) -> OnboardingStepContext {
        OnboardingStepContext(
            key: step.key,
            answer: answer(for: step.key),
            advanceAction: { [weak self] in
                guard let self, self.currentStep?.key == step.key else { return }
                self.next()
            },
            setAnswerAction: { [weak self] values in
                self?.setAnswer(values, for: step.key)
            }
        )
    }

    /// Jumps without events (previews and screenshots only).
    func jump(to index: Int) {
        guard steps.indices.contains(index) else { return }
        currentIndex = index
    }
}
