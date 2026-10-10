import SwiftUI
import Testing
import UIKit
@testable import EnduranceOnboarding

/// Renders every step of the demo flow in both sample themes, light and dark,
/// to PNGs for visual review. Runs only when a directory is given:
///
///     TEST_RUNNER_ONBOARDING_SCREENSHOT_DIR=/path xcodebuild test …
@MainActor
@Suite("Screenshots")
struct ScreenshotRenderTests {

    /// iPhone Air, in points.
    static let size = CGSize(width: 420, height: 912)

    @Test func renderDemoFlow() async throws {
        guard let directory = ProcessInfo.processInfo.environment["ONBOARDING_SCREENSHOT_DIR"] else { return }
        let root = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        var written = 0
        for (name, theme) in OnboardingDemo.themes {
            for scheme in [ColorScheme.light, .dark] {
                let controller = OnboardingController(flow: OnboardingDemo.flow(theme: theme, analytics: { _ in }), onFinish: { _ in })
                await controller.start()

                for index in controller.steps.indices {
                    controller.jump(to: index)
                    let step = controller.steps[index]
                    // Show questions answered, like a user mid-flow.
                    if step.key == "who", controller.answer(for: "who").isEmpty {
                        controller.toggle(optionID: "family")
                    }
                    if step.key == "reminder_timing", controller.answer(for: "reminder_timing").isEmpty {
                        controller.toggle(optionID: "day_before")
                        controller.toggle(optionID: "on_the_day")
                    }

                    let image = try render(controller: controller, theme: theme, scheme: scheme)
                    let file = root.appendingPathComponent(
                        String(format: "%@-%@-%02d-%@.png", name, scheme == .dark ? "dark" : "light", index + 1, step.key)
                    )
                    try #require(image.pngData()).write(to: file)
                    written += 1
                }
            }
        }
        #expect(written == 28)
    }

    private func render(controller: OnboardingController, theme: OnboardingTheme, scheme: ColorScheme) throws -> UIImage {
        let content = OnboardingView(controller: controller, theme: theme)
            .safeAreaPadding(.top, 62)
            .safeAreaPadding(.bottom, 34)
            .frame(width: Self.size.width, height: Self.size.height)
            .environment(\.colorScheme, scheme)
            .environment(\.onboardingSnapshotMode, true)
            .environment(\.locale, Locale(identifier: "en_US"))
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(Self.size)
        return try #require(renderer.uiImage)
    }
}
