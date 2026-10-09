import SwiftUI
import ViewUtils

@available(iOS 18.0, *)
struct DantaFlowingBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let isPaused = reduceMotion || scenePhase != .active

        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: isPaused)) { timeline in
            let phase = isPaused ? 0 : (sin(timeline.date.timeIntervalSinceReferenceDate * .pi / 4) + 1) / 2
            gradient(phase: phase)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func gradient(phase: Double) -> some View {
        LinearGradient(
            colors: [.blue, .purple, .pink, .cyan, .blue],
            startPoint: UnitPoint(x: -0.8 * phase, y: 0),
            endPoint: UnitPoint(x: 1.8 - 0.8 * phase, y: 1))
            .overlay {
                RadialGradient(
                    colors: [.purple.opacity(0.6), .clear],
                    center: UnitPoint(x: 0.85 - 0.7 * phase, y: 0.2 + 0.6 * phase),
                    startRadius: 0,
                    endRadius: 90)
            }
    }
}

@available(iOS 18.0, *)
struct DantaEnableButton: View {
    var isActivating: Bool
    var action: () async -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activationTrigger = 0

    var body: some View {
        let reduceMotion = reduceMotion

        AsyncButton {
            activationTrigger += 1
            await action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : activationTrigger)
                    .accessibilityHidden(true)
                Text(isActivating ? "Preparing instance…" : "Enable Danta Intelligence", bundle: .module)
                    .multilineTextAlignment(.center)
                if isActivating {
                    ProgressView()
                        .tint(.white)
                        .accessibilityHidden(true)
                }
            }
            .font(.body.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
        }
        .buttonStyle(DantaEnableButtonStyle(isActivating: isActivating))
        .disabled(isActivating)
        .sensoryFeedback(.impact(weight: .light), trigger: activationTrigger)
        .keyframeAnimator(initialValue: 0.0, trigger: activationTrigger) { content, progress in
            content.overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.cyan, .blue, .purple, .pink],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2)
                    .scaleEffect(1 + progress * 0.45)
                    .opacity(reduceMotion || progress == 0 ? 0 : 1 - progress)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        } keyframes: { _ in
            LinearKeyframe(0, duration: 0.01)
            CubicKeyframe(1, duration: 0.85)
        }
    }
}

@available(iOS 18.0, *)
private struct DantaEnableButtonStyle: ButtonStyle {
    var isActivating: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.gradient)
                    .overlay {
                        if isActivating {
                            DantaFlowingBackground()
                                .opacity(0.65)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
            .opacity(isEnabled || isActivating ? 1 : 0.5)
    }
}
