import StoreKit
import SwiftUI

/// Presents an `OnboardingFlow`. When the last step completes, `onFinish`
/// receives the answers keyed by step key: present your paywall there and
/// set your own `hasCompletedOnboarding`.
public struct OnboardingView: View {
    @State private var controller: OnboardingController
    private let theme: OnboardingTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.requestReview) private var requestReview

    public init(flow: OnboardingFlow, onFinish: @escaping @MainActor (OnboardingAnswers) -> Void) {
        _controller = State(initialValue: OnboardingController(flow: flow, onFinish: onFinish))
        theme = flow.theme
    }

    init(controller: OnboardingController, theme: OnboardingTheme) {
        _controller = State(initialValue: controller)
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            OnboardingBackground()
            if controller.isReady, let step = controller.currentStep {
                VStack(spacing: 0) {
                    topBar(step)
                    ZStack {
                        content(step)
                            .id(step.key)
                            .transition(transition)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    bottomBar(step)
                }
                .padding(.horizontal, 24)
            }
        }
        .environment(\.onboardingTheme, theme)
        .preferredColorScheme(theme.colorScheme)
        .animation(stepAnimation, value: controller.currentIndex)
        // The condition closures are evaluated during SwiftUI's update, which
        // can run off the main thread on iOS 26: keep them `@Sendable` and
        // free of main-actor state.
        .sensoryFeedback(.impact(weight: .light), trigger: controller.currentIndex) { @Sendable [hapticsEnabled = hapticsEnabled] _, _ in
            hapticsEnabled
        }
        .sensoryFeedback(.selection, trigger: controller.answers) { @Sendable [hapticsEnabled = hapticsEnabled] _, _ in
            hapticsEnabled
        }
        .task { await controller.start() }
    }

    private var hapticsEnabled: Bool { controller.options.hapticsEnabled }

    // MARK: Chrome

    private func topBar(_ step: OnboardingStep) -> some View {
        ZStack {
            if controller.options.showsProgress && controller.stepCount > 1 {
                OnboardingProgressIndicator(index: controller.currentIndex, count: controller.stepCount)
                    .animation(stepAnimation, value: controller.currentIndex)
            }
            HStack {
                if controller.canGoBack {
                    Button {
                        controller.back()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L10n.back)
                }
                Spacer()
                if controller.canSkip {
                    Button {
                        controller.skip()
                    } label: {
                        Text(L10n.skip)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func bottomBar(_ step: OnboardingStep) -> some View {
        if showsButton(step) {
            VStack(spacing: 14) {
                Button {
                    primaryAction(step)
                } label: {
                    Text(buttonTitle(step))
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .disabled(!controller.canContinue)
                .accessibilityIdentifier("onboarding.primary")

                if let footnote = step.footnoteValue {
                    footnoteView(footnote)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }

    private func footnoteView(_ footnote: OnboardingFootnote) -> some View {
        HStack(spacing: 6) {
            if let symbol = footnote.systemImage {
                Image(systemName: symbol).accessibilityHidden(true)
            }
            Text(footnote.text)
        }
        .font(theme.typography.footnote)
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private func showsButton(_ step: OnboardingStep) -> Bool {
        switch step.kind {
        case .loading: false
        case .custom(let custom): custom.showsContinueButton
        default: true
        }
    }

    private func buttonTitle(_ step: OnboardingStep) -> String {
        if let custom = step.customButtonTitle {
            return String(localized: custom)
        }
        return controller.isLastStep ? L10n.getStarted : L10n.continueButton
    }

    private func primaryAction(_ step: OnboardingStep) {
        switch step.kind {
        case .permission:
            Task { await controller.requestPermission() }
        case .reviewPrePrompt(let review):
            if let request = review.request {
                request()
            } else {
                requestReview()
            }
            controller.next()
        default:
            controller.next()
        }
    }

    // MARK: Steps

    @ViewBuilder
    private func content(_ step: OnboardingStep) -> some View {
        switch step.kind {
        case .hero(let hero):
            HeroStepView(hero: hero)
        case .benefits(let benefits):
            BenefitsStepView(benefits: benefits)
        case .question(let question):
            QuestionStepView(question: question, selected: controller.answer(for: step.key)) { optionID in
                controller.toggle(optionID: optionID)
                if question.autoAdvance, question.selection == .single, !voiceOverEnabled {
                    Task {
                        try? await Task.sleep(for: .milliseconds(350))
                        if controller.currentStep?.key == step.key { controller.next() }
                    }
                }
            }
        case .permission(let permission):
            PermissionStepView(permission: permission)
        case .reviewPrePrompt(let review):
            ReviewPrePromptStepView(review: review)
        case .custom(let custom):
            custom.content(controller.context(for: step))
        case .loading(let loading):
            LoadingStepView(loading: loading) {
                if controller.currentStep?.key == step.key { controller.next() }
            }
        }
    }

    private var stepAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.88)
    }

    private var transition: AnyTransition {
        if reduceMotion { return .opacity }
        let forward = controller.direction == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}
