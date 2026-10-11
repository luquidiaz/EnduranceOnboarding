import EnduranceOnboarding
import SwiftUI

/// Host app for the UI tests (and for trying the package by hand).
/// Runs a flow with every built-in step type, ordered so that questions
/// follow static screens: the iOS 26 async-renderer case fixed in 0.1.1.
@main
struct OnboardingExampleApp: App {
    @State private var finishedAnswers: OnboardingAnswers?

    var body: some Scene {
        WindowGroup {
            if let finishedAnswers {
                FinishedView(answers: finishedAnswers) {
                    self.finishedAnswers = nil
                }
            } else {
                OnboardingView(flow: ExampleFlow.make()) { answers in
                    finishedAnswers = answers
                }
            }
        }
    }
}

private struct FinishedView: View {
    let answers: OnboardingAnswers
    let restart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding finished")
                .font(.title.bold())
                .accessibilityIdentifier("example.finished")
            Text(answers.keys.sorted().map { "\($0)=\(answers[$0]!.joined(separator: ","))" }.joined(separator: "\n"))
                .font(.footnote.monospaced())
                .accessibilityIdentifier("example.answers")
            Button("Restart", action: restart)
        }
        .padding()
    }
}

enum ExampleFlow {
    static func make() -> OnboardingFlow {
        OnboardingFlow(
            steps: [
                // Static screen (nothing animating) right before a question.
                .hero(
                    key: "welcome",
                    title: "Sleep better tonight",
                    subtitle: "A calm, steady sound that masks the noise around you.",
                    systemImage: "moon.zzz.fill"
                )
                .footnote("No account needed", systemImage: "lock.fill"),

                .question(
                    key: "goal",
                    title: "What brings you here?",
                    subtitle: "We'll tune the app to it.",
                    options: [
                        OnboardingOption(id: "fall_asleep", title: "Falling asleep", subtitle: "Drift off faster", systemImage: "bed.double.fill"),
                        OnboardingOption(id: "focus", title: "Focus", subtitle: "Block out distractions", systemImage: "brain.head.profile"),
                        OnboardingOption(id: "baby", title: "Baby sleep", emoji: "👶"),
                        OnboardingOption(id: "tinnitus", title: "Tinnitus relief", subtitle: "Mask the ringing", systemImage: "ear")
                    ]
                ),

                .question(
                    key: "when",
                    title: "When do you listen?",
                    selection: .multiple(minimum: 1),
                    options: [
                        OnboardingOption(id: "night", title: "At night", systemImage: "moon.fill"),
                        OnboardingOption(id: "nap", title: "Naps", systemImage: "sun.max.fill"),
                        OnboardingOption(id: "work", title: "While working", subtitle: "Home or office", systemImage: "laptopcomputer")
                    ]
                )
                .skippable(),

                .benefits(
                    key: "benefits",
                    title: "Everything you need",
                    items: [
                        OnboardingBenefit(systemImage: "infinity", title: "Plays all night", detail: "No loops, no gaps."),
                        OnboardingBenefit(systemImage: "timer", title: "Sleep timer", detail: "Fades out when you're asleep."),
                        OnboardingBenefit(systemImage: "slider.horizontal.3", title: "Mix your sound", detail: "Fan, rain and more.")
                    ]
                ),

                // Another static screen followed by a question, with auto-advance.
                .hero(
                    key: "almost",
                    title: "Almost there",
                    systemImage: "sparkles"
                ),

                .question(
                    key: "volume",
                    title: "How loud do you like it?",
                    options: [
                        OnboardingOption(id: "soft", title: "Soft", subtitle: "Barely there"),
                        OnboardingOption(id: "medium", title: "Medium"),
                        OnboardingOption(id: "loud", title: "Loud", subtitle: "Drown everything out")
                    ],
                    autoAdvance: true
                ),

                .loading(
                    title: "Setting up your sound",
                    messages: ["Picking a sound", "Setting the timer"],
                    duration: 1.5
                )
            ]
        )
    }
}
