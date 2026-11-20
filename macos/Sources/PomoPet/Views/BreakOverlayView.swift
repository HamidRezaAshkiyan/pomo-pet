import PomoPetCore
import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var engine: PomodoroEngine
    let catalog: PixelSpriteCatalog
    @ObservedObject var clock: AnimationClock

    var body: some View {
        ZStack {
            // Calm translucent gradient backdrop
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.86),
                    Color(red: 0.11, green: 0.18, blue: 0.22).opacity(0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated breathing aura behind the pet
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.36, green: 0.80, blue: 0.72).opacity(0.32),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 240
                        )
                    )
                    .frame(width: 440, height: 440)
                    .scaleEffect(clock.isInhaling ? 1.18 : 0.82)

                Circle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .scaleEffect(clock.isInhaling ? 1.14 : 0.88)
            }
            .animation(.easeInOut(duration: 3.6), value: clock.isInhaling)

            VStack(spacing: 24) {
                Text(engine.phase == .longBreak ? "LONG BREAK • UNWIND" : "TIME TO REST")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(Color(red: 0.56, green: 0.90, blue: 0.82))

                AnimatedPetView(
                    catalog: catalog,
                    pet: engine.settings.selectedPet,
                    state: engine.petAnimationState,
                    size: 120,
                    frameTick: clock.tick,
                    bobbing: clock.bobbing
                )

                Text(engine.formattedTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                // Desk stretch & eye-rest prompt card
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: engine.currentStretchPrompt.iconName)
                            .foregroundStyle(Color(red: 0.56, green: 0.90, blue: 0.82))
                        Text(engine.currentStretchPrompt.title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text(engine.currentStretchPrompt.subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )

                Text(clock.isInhaling ? "Breathe in slowly…" : "Breathe out gently…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 14) {
                    Button {
                        engine.snoozeBreak(minutes: 5)
                    } label: {
                        Label("Snooze 5 min", systemImage: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.skipPhase()
                    } label: {
                        Label("Skip Break", systemImage: "forward.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)

                Text("Press Esc to close overlay")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(40)
        }
    }
}
