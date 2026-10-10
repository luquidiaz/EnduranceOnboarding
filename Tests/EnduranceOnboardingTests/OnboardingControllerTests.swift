import Foundation
import SwiftUI
import Testing
@testable import EnduranceOnboarding

@MainActor
final class Recorder {
    var events: [OnboardingEvent] = []
    var finished: [OnboardingAnswers] = []
}

@MainActor
private func makeController(
    _ steps: [OnboardingStep],
    options: OnboardingOptions = OnboardingOptions(),
    recorder: Recorder,
    clock: @escaping @MainActor () -> Date = { Date(timeIntervalSince1970: 0) }
) -> OnboardingController {
    let flow = OnboardingFlow(steps: steps, options: options) { recorder.events.append($0) }
    return OnboardingController(flow: flow, now: clock) { recorder.finished.append($0) }
}

private let colorQuestion = OnboardingStep.question(
    key: "color",
    title: "Favorite color?",
    options: [
        OnboardingOption(id: "red", title: "Red"),
        OnboardingOption(id: "green", title: "Green"),
        OnboardingOption(id: "blue", title: "Blue")
    ]
)

private let goalsQuestion = OnboardingStep.question(
    key: "goals",
    title: "Goals?",
    selection: .multiple(minimum: 2, maximum: 2),
    options: [
        OnboardingOption(id: "sleep", title: "Sleep"),
        OnboardingOption(id: "focus", title: "Focus"),
        OnboardingOption(id: "relax", title: "Relax")
    ]
)

private func permission(_ status: OnboardingPermissionStatus, result: OnboardingPermissionStatus = .granted) -> OnboardingStep {
    .permission(
        key: "notifications",
        title: "Notifications",
        permission: OnboardingPermission(status: { status }, request: { result })
    )
}

@MainActor
@Suite("Navigation")
struct NavigationTests {

    @Test func nextAndBackMoveThroughSteps() async {
        let recorder = Recorder()
        let controller = makeController([
            .hero(key: "a", title: "A"),
            .hero(key: "b", title: "B"),
            .hero(key: "c", title: "C")
        ], recorder: recorder)
        await controller.start()

        #expect(controller.currentIndex == 0)
        #expect(!controller.canGoBack)
        controller.next()
        controller.next()
        #expect(controller.currentStep?.key == "c")
        #expect(controller.isLastStep)
        #expect(controller.progress == 1)
        controller.back()
        #expect(controller.currentStep?.key == "b")
        controller.next()
        controller.next()
        #expect(controller.isFinished)
        #expect(recorder.finished.count == 1)
    }

    @Test func backIsDisabledByOption() async {
        let recorder = Recorder()
        let controller = makeController(
            [.hero(key: "a", title: "A"), .hero(key: "b", title: "B")],
            options: OnboardingOptions(allowsBack: false),
            recorder: recorder
        )
        await controller.start()
        controller.next()
        #expect(!controller.canGoBack)
        controller.back()
        #expect(controller.currentIndex == 1)
    }

    @Test func backSkipsLoadingSteps() async {
        let recorder = Recorder()
        let controller = makeController([
            .hero(key: "a", title: "A"),
            .loading(title: "Loading"),
            .hero(key: "b", title: "B")
        ], recorder: recorder)
        await controller.start()
        controller.next()
        #expect(controller.currentStep?.type == .loading)
        #expect(!controller.canGoBack)
        controller.next()
        controller.back()
        #expect(controller.currentStep?.key == "a")
    }

    @Test func singleStepFlow() async {
        let recorder = Recorder()
        let controller = makeController([.hero(key: "only", title: "Only")], recorder: recorder)
        await controller.start()
        #expect(controller.stepCount == 1)
        #expect(controller.progress == 1)
        #expect(controller.isLastStep)
        #expect(!controller.canGoBack)
        controller.next()
        #expect(controller.isFinished)
        #expect(recorder.finished == [[:]])
    }

    @Test func emptyFlowFinishesOnStart() async {
        let recorder = Recorder()
        let controller = makeController([], recorder: recorder)
        #expect(controller.progress == 1)
        await controller.start()
        #expect(controller.isFinished)
        #expect(recorder.finished.count == 1)
    }

    @Test func finishIsReportedOnce() async {
        let recorder = Recorder()
        let controller = makeController([.hero(key: "a", title: "A")], recorder: recorder)
        await controller.start()
        controller.next()
        controller.next()
        controller.skip()
        #expect(recorder.finished.count == 1)
    }
}

@MainActor
@Suite("Answers")
struct AnswerTests {

    @Test func singleChoiceReplacesByKey() async {
        let recorder = Recorder()
        let controller = makeController([colorQuestion], recorder: recorder)
        await controller.start()

        #expect(!controller.canContinue)
        controller.toggle(optionID: "red")
        controller.toggle(optionID: "blue")
        #expect(controller.answers == ["color": ["blue"]])
        #expect(controller.canContinue)
        controller.next()
        #expect(recorder.finished == [["color": ["blue"]]])
    }

    @Test func multipleChoiceKeepsDeclaredOrderAndLimits() async {
        let recorder = Recorder()
        let controller = makeController([goalsQuestion], recorder: recorder)
        await controller.start()

        controller.toggle(optionID: "relax")
        #expect(!controller.canContinue) // minimum 2
        controller.toggle(optionID: "sleep")
        controller.toggle(optionID: "focus") // maximum 2: ignored
        #expect(controller.answer(for: "goals") == ["sleep", "relax"])
        #expect(controller.canContinue)
        controller.toggle(optionID: "relax")
        #expect(controller.answer(for: "goals") == ["sleep"])
        #expect(!controller.canContinue)
    }

    @Test func unknownOptionIsIgnored() async {
        let recorder = Recorder()
        let controller = makeController([colorQuestion], recorder: recorder)
        await controller.start()
        controller.toggle(optionID: "purple")
        #expect(controller.answers.isEmpty)
    }

    @Test func answersSurviveBackNavigation() async {
        let recorder = Recorder()
        let controller = makeController([colorQuestion, .hero(key: "end", title: "End")], recorder: recorder)
        await controller.start()
        controller.toggle(optionID: "green")
        controller.next()
        controller.back()
        #expect(controller.answer(for: "color") == ["green"])
    }

    @Test func customStepStoresAnswerThroughContext() async {
        let recorder = Recorder()
        let custom = OnboardingStep.custom(key: "bedtime", requiresAnswer: true) { _ in EmptyView() }
        let controller = makeController([custom], recorder: recorder)
        await controller.start()

        #expect(!controller.canContinue)
        let context = controller.context(for: custom)
        context.setAnswer(["22:30"])
        #expect(controller.canContinue)
        controller.context(for: custom).advance()
        #expect(recorder.finished == [["bedtime": ["22:30"]]])
    }
}

@MainActor
@Suite("Skip")
struct SkipTests {

    @Test func skipAdvancesWithoutAnswer() async {
        let recorder = Recorder()
        let controller = makeController([colorQuestion.skippable(), .hero(key: "end", title: "End")], recorder: recorder)
        await controller.start()

        controller.toggle(optionID: "red")
        #expect(controller.canSkip)
        controller.skip()
        #expect(controller.currentStep?.key == "end")
        #expect(controller.answers["color"] == nil)
        #expect(recorder.events.contains(.skipped(key: "color", index: 0)))
    }

    @Test func nonSkippableStepIgnoresSkip() async {
        let recorder = Recorder()
        let controller = makeController([colorQuestion, .hero(key: "end", title: "End")], recorder: recorder)
        await controller.start()
        #expect(!controller.canSkip)
        controller.skip()
        #expect(controller.currentIndex == 0)
    }

    @Test func permissionAndLoadingAreNeverSkippable() {
        #expect(!permission(.notDetermined).skippable().isSkippable)
        #expect(!OnboardingStep.loading(title: "L").skippable().isSkippable)
        #expect(OnboardingStep.hero(key: "h", title: "H").skippable().isSkippable)
    }

    @Test func skippingLastStepFinishes() async {
        let recorder = Recorder()
        let controller = makeController([.hero(key: "a", title: "A").skippable()], recorder: recorder)
        await controller.start()
        controller.skip()
        #expect(controller.isFinished)
    }
}

@MainActor
@Suite("Permissions")
struct PermissionTests {

    @Test func undecidedPermissionRequestsAndAdvances() async {
        let recorder = Recorder()
        let controller = makeController(
            [permission(.notDetermined, result: .denied), .hero(key: "end", title: "End")],
            recorder: recorder
        )
        await controller.start()
        #expect(controller.currentStep?.type == .permission)
        await controller.requestPermission()
        #expect(controller.currentStep?.key == "end")
        #expect(controller.answer(for: "notifications") == ["denied"])
        #expect(recorder.events.contains(.permissionResult(key: "notifications", status: .denied, wasPrompted: true)))
    }

    @Test(arguments: [OnboardingPermissionStatus.granted, .denied])
    func decidedPermissionIsSkipped(status: OnboardingPermissionStatus) async {
        let recorder = Recorder()
        let controller = makeController(
            [.hero(key: "a", title: "A"), permission(status), .hero(key: "b", title: "B")],
            recorder: recorder
        )
        #expect(!controller.isReady)
        await controller.start()
        #expect(controller.isReady)
        #expect(controller.steps.map(\.key) == ["a", "b"])
        #expect(controller.answer(for: "notifications") == [status.rawValue])
        #expect(recorder.events.first == .permissionResult(key: "notifications", status: status, wasPrompted: false))
    }

    @Test func requestOutsidePermissionStepDoesNothing() async {
        let recorder = Recorder()
        let controller = makeController([.hero(key: "a", title: "A")], recorder: recorder)
        await controller.start()
        await controller.requestPermission()
        #expect(controller.currentIndex == 0)
        #expect(!controller.isFinished)
    }
}

@MainActor
@Suite("Events")
struct EventTests {

    @Test func eventsAreEmittedInOrder() async {
        let recorder = Recorder()
        var now = Date(timeIntervalSince1970: 1_000)
        let controller = makeController(
            [
                .hero(key: "welcome", title: "Hi"),
                colorQuestion,
                goalsQuestion.skippable(),
                permission(.notDetermined)
            ],
            recorder: recorder,
            clock: { now }
        )

        await controller.start()
        controller.next()
        controller.toggle(optionID: "green")
        controller.next()
        controller.skip()
        now = now.addingTimeInterval(42)
        await controller.requestPermission()

        #expect(recorder.events == [
            .stepViewed(key: "welcome", index: 0),
            .stepCompleted(key: "welcome", index: 0),
            .stepViewed(key: "color", index: 1),
            .answerSelected(key: "color", values: ["green"]),
            .stepCompleted(key: "color", index: 1),
            .stepViewed(key: "goals", index: 2),
            .skipped(key: "goals", index: 2),
            .stepViewed(key: "notifications", index: 3),
            .permissionResult(key: "notifications", status: .granted, wasPrompted: true),
            .stepCompleted(key: "notifications", index: 3),
            .finished(duration: 42)
        ])
        #expect(recorder.finished == [["color": ["green"], "notifications": ["granted"]]])
    }

    @Test func eventNamesAndParametersAreFirebaseFriendly() {
        let viewed = OnboardingEvent.stepViewed(key: "welcome", index: 0)
        #expect(viewed.name == "onboarding_step_viewed")
        #expect(viewed.parameters["step_key"] as? String == "welcome")
        #expect(viewed.parameters["step_index"] as? Int == 0)

        let answer = OnboardingEvent.answerSelected(key: "goals", values: ["sleep", "focus"])
        #expect(answer.parameters["values"] as? String == "sleep,focus")

        let finished = OnboardingEvent.finished(duration: 12.345)
        #expect(finished.parameters["duration_seconds"] as? Double == 12.3)

        let all: [OnboardingEvent] = [
            viewed, .stepCompleted(key: "a", index: 0), answer,
            .permissionResult(key: "n", status: .granted, wasPrompted: true),
            .skipped(key: "a", index: 0), finished
        ]
        for event in all {
            #expect(event.name.range(of: "^[a-z_]+$", options: .regularExpression) != nil)
            #expect(event.name.count <= 40)
        }
    }
}

@MainActor
@Suite("Persistence")
struct PersistenceTests {

    @Test func progressIsRestoredByKeyAndClearedOnFinish() async throws {
        let suite = "onboarding-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let options = OnboardingOptions(persistence: .userDefaults(key: "progress", store: defaults))
        let steps: [OnboardingStep] = [.hero(key: "a", title: "A"), colorQuestion, .hero(key: "c", title: "C")]

        let first = makeController(steps, options: options, recorder: Recorder())
        await first.start()
        first.next()
        first.toggle(optionID: "red")

        // A new version inserts a step before: restore still lands on "color".
        let recorder = Recorder()
        let resumed = makeController([.hero(key: "new", title: "New")] + steps, options: options, recorder: recorder)
        await resumed.start()
        #expect(resumed.currentStep?.key == "color")
        #expect(resumed.answer(for: "color") == ["red"])
        #expect(recorder.events == [.stepViewed(key: "color", index: 2)])

        resumed.next()
        resumed.next()
        #expect(resumed.isFinished)
        #expect(defaults.data(forKey: "progress") == nil)
    }
}

@Suite("Localization")
struct LocalizationTests {

    static let languages = ["en", "es", "pt-BR", "de", "fr", "it", "ja", "ko"]
    static let keys = [
        "button.continue", "button.get_started", "button.skip", "button.back",
        "question.select_all", "progress.short", "progress.accessibility"
    ]

    @Test(arguments: languages)
    func everyPackageStringIsTranslated(language: String) throws {
        let path = try #require(
            L10n.bundle.path(forResource: language, ofType: "lproj")
                ?? L10n.bundle.path(forResource: language.replacingOccurrences(of: "-", with: "_"), ofType: "lproj"),
            "missing \(language).lproj"
        )
        let bundle = try #require(Bundle(path: path))
        for key in Self.keys {
            let value = bundle.localizedString(forKey: key, value: "__missing__", table: nil)
            #expect(value != "__missing__" && value != key, "\(language): \(key)")
        }
    }

    @Test func englishFallbacks() {
        #expect(L10n.progress(1, 3).contains("1"))
        #expect(L10n.progress(1, 3).contains("3"))
        #expect(!L10n.continueButton.isEmpty)
    }
}
