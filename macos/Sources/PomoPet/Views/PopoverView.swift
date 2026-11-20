import AppKit
import PomoPetCore
import SwiftUI

struct PopoverView: View {
    @ObservedObject var engine: PomodoroEngine
    let catalog: PixelSpriteCatalog
    @ObservedObject var clock: AnimationClock

    private var phaseGradient: LinearGradient {
        switch engine.phase {
        case .focus:
            return LinearGradient(
                colors: [Color(red: 0.96, green: 0.56, blue: 0.34), Color(red: 0.94, green: 0.36, blue: 0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shortBreak:
            return LinearGradient(
                colors: [Color(red: 0.32, green: 0.78, blue: 0.65), Color(red: 0.25, green: 0.62, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .longBreak:
            return LinearGradient(
                colors: [Color(red: 0.46, green: 0.55, blue: 0.92), Color(red: 0.64, green: 0.46, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if clock.showingSettings {
                SettingsView(engine: engine, isPresented: $clock.showingSettings)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                mainSessionView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 430)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: clock.showingSettings)
    }

    private var mainSessionView: some View {
        VStack(spacing: 16) {
            headerBar
            liveSessionRing
            controlButtons
            petSwitcherBar
            footerBar
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(phaseGradient)
                    .frame(width: 8, height: 8)
                Text(engine.phase.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06), in: Capsule())

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<engine.settings.sessionsBeforeLongBreak, id: \.self) { idx in
                    Circle()
                        .fill(idx < engine.completedFocusInCycle ? AnyShapeStyle(phaseGradient) : AnyShapeStyle(Color.primary.opacity(0.14)))
                        .frame(width: 7, height: 7)
                }
            }
            .help("Focus sessions until long break")

            Button {
                clock.showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private var liveSessionRing: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                    .frame(width: 174, height: 174)

                Circle()
                    .trim(from: 0, to: max(0.015, engine.progress))
                    .stroke(
                        phaseGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 174, height: 174)
                    .animation(.easeInOut(duration: 0.45), value: engine.progress)

                VStack(spacing: 4) {
                    AnimatedPetView(
                        catalog: catalog,
                        pet: engine.settings.selectedPet,
                        state: engine.petAnimationState,
                        size: 62,
                        frameTick: clock.tick,
                        bobbing: clock.bobbing
                    )

                    Text(engine.formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            Text(engine.statusSubtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var controlButtons: some View {
        HStack(spacing: 10) {
            Button {
                engine.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Reset current phase")

            Button {
                engine.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(engine.isRunning ? "Pause" : "Start")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(phaseGradient, in: Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            Button {
                engine.skipPhase()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Skip to next phase")
        }
    }

    private var petSwitcherBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Companion")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    engine.triggerBreakPreview()
                } label: {
                    Label("Preview Break", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(PetKind.allCases) { pet in
                    let isSelected = engine.settings.selectedPet == pet
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            engine.selectPet(pet)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let frame = catalog.frame(for: pet, state: .idle, tick: clock.tick),
                               let img = PixelImageRenderer.swiftUIImage(from: frame, scale: 3) {
                                img
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            }
                            Text(pet.displayName)
                                .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            isSelected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(isSelected ? Color.primary.opacity(0.24) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footerBar: some View {
        HStack {
            Text("Today: \(engine.totalCompletedToday) focus \(engine.totalCompletedToday == 1 ? "session" : "sessions")")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
    }
}
