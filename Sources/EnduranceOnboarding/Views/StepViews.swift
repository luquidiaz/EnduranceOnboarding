import SwiftUI

// MARK: - Hero

struct HeroStepView: View {
    let hero: OnboardingStep.Hero
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(spacing: 24) {
                    visual.frame(height: 240)
                    StepHeader(title: hero.title, subtitle: hero.subtitle)
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        } else {
            VStack(spacing: 28) {
                visual
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
                StepHeader(title: hero.title, subtitle: hero.subtitle)
            }
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder private var visual: some View {
        if let content = hero.visual {
            content()
        } else if let symbol = hero.symbol {
            SymbolBadge(systemImage: symbol, size: 128)
        } else {
            Color.clear
        }
    }
}

// MARK: - Benefits

struct BenefitsStepView: View {
    let benefits: OnboardingStep.Benefits
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        FittingScroll {
            VStack(spacing: 28) {
                StepHeader(title: benefits.title, subtitle: benefits.subtitle)
                VStack(spacing: 0) {
                    ForEach(Array(benefits.items.enumerated()), id: \.element.id) { offset, item in
                        if offset > 0 {
                            Divider().overlay(theme.separator).padding(.leading, 64)
                        }
                        row(item)
                    }
                }
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius + 4, style: .continuous)
                        .fill(theme.surface)
                )
            }
        }
    }

    private func row(_ item: OnboardingBenefit) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.accent.opacity(0.14))
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.textPrimary)
                if let detail = item.detail {
                    Text(detail)
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Question

struct QuestionStepView: View {
    let question: OnboardingStep.Question
    let selected: [String]
    let onSelect: (String) -> Void
    @Environment(\.onboardingTheme) private var theme

    private var isMultiple: Bool { question.selection != .single }

    var body: some View {
        FittingScroll {
            VStack(spacing: 28) {
                StepHeader(
                    title: question.title,
                    subtitle: question.subtitle,
                    subtitleFallback: isMultiple ? L10n.selectAllThatApply : nil
                )
                VStack(spacing: 10) {
                    ForEach(question.options) { option in
                        optionRow(option)
                    }
                }
            }
        }
    }

    private func optionRow(_ option: OnboardingOption) -> some View {
        let isSelected = selected.contains(option.id)
        return Button {
            onSelect(option.id)
        } label: {
            HStack(spacing: 14) {
                if let emoji = option.emoji {
                    Text(verbatim: emoji)
                        .font(.title2)
                        .accessibilityHidden(true)
                } else if let symbol = option.systemImage {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? theme.primary : theme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                }
                Text(option.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                indicator(isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(isSelected ? theme.primary.opacity(0.12) : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? theme.primary : theme.separator, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func indicator(_ isSelected: Bool) -> some View {
        let name: String
        if isMultiple {
            name = isSelected ? "checkmark.square.fill" : "square"
        } else {
            name = isSelected ? "checkmark.circle.fill" : "circle"
        }
        return Image(systemName: name)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(isSelected ? theme.primary : theme.textTertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Permission

struct PermissionStepView: View {
    let permission: OnboardingStep.Permission

    var body: some View {
        FittingScroll {
            VStack(spacing: 40) {
                if let visual = permission.visual {
                    visual()
                } else {
                    SymbolBadge(systemImage: permission.symbol)
                }
                StepHeader(title: permission.title, subtitle: permission.subtitle)
            }
        }
    }
}

// MARK: - Review pre-prompt

struct ReviewPrePromptStepView: View {
    let review: OnboardingStep.ReviewPrePrompt
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        FittingScroll {
            VStack(spacing: 36) {
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 26)
                .background(Capsule().fill(theme.accent.opacity(0.14)))
                .accessibilityHidden(true)
                StepHeader(title: review.title, subtitle: review.subtitle)
            }
        }
    }
}

// MARK: - Loading

struct LoadingStepView: View {
    let loading: OnboardingStep.Loading
    let onComplete: () -> Void
    @Environment(\.onboardingTheme) private var theme
    @Environment(\.onboardingSnapshotMode) private var snapshotMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: Double = 0

    private var checkedCount: Int {
        Int((progress * Double(loading.messages.count)).rounded(.down))
    }

    var body: some View {
        FittingScroll {
            VStack(spacing: 36) {
                ring
                Text(loading.title)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !loading.messages.isEmpty {
                    checklist
                }
            }
        }
        .task {
            if snapshotMode {
                progress = 0.68
                return
            }
            await run()
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(theme.separator, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(theme.typography.number)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(width: 168, height: 168)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(loading.title))
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(loading.messages.enumerated()), id: \.offset) { offset, message in
                let isDone = offset < checkedCount
                HStack(spacing: 12) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle.dotted")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isDone ? theme.primary : theme.textTertiary)
                        .accessibilityHidden(true)
                    Text(message)
                        .font(theme.typography.callout)
                        .foregroundStyle(isDone ? theme.textPrimary : theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(offset <= checkedCount ? 1 : 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private func run() async {
        let ticks = 50
        let interval = loading.duration / Double(ticks)
        for tick in 1...ticks {
            try? await Task.sleep(for: .seconds(interval))
            if Task.isCancelled { return }
            withAnimation(reduceMotion ? nil : .linear(duration: interval)) {
                progress = Double(tick) / Double(ticks)
            }
        }
        try? await Task.sleep(for: .milliseconds(350))
        if Task.isCancelled { return }
        onComplete()
    }
}
