import PomoPetCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: PomodoroEngine
    @Binding var isPresented: Bool

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.1.1"
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    isPresented = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Spacer()

                Color.clear.frame(width: 44, height: 1)
            }

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    stepperRow("Focus duration", value: $engine.settings.focusMinutes, range: 1...90, suffix: "min")
                    stepperRow("Short break", value: $engine.settings.shortBreakMinutes, range: 1...30, suffix: "min")
                    stepperRow("Long break", value: $engine.settings.longBreakMinutes, range: 5...60, suffix: "min")
                    stepperRow("Sessions / long break", value: $engine.settings.sessionsBeforeLongBreak, range: 2...8, suffix: "")

                    Divider().padding(.vertical, 2)

                    Toggle("Full-screen break overlay", isOn: $engine.settings.showFullScreenBreakOverlay)
                    Toggle("Show timer in menu bar", isOn: $engine.settings.showTimerInMenuBar)
                    Toggle("Play sound chime", isOn: $engine.settings.playSoundChime)
                    Toggle("Auto-start focus after break", isOn: $engine.settings.autoStartNextPhase)

                    Divider().padding(.vertical, 2)

                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("PomoPet v\(appVersion)")
                            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 12.5, design: .rounded))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Stepper(value: value, in: range) {
                Text(suffix.isEmpty ? "\(value.wrappedValue)" : "\(value.wrappedValue) \(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 48, alignment: .trailing)
            }
        }
    }
}
