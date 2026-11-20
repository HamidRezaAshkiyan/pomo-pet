import AppKit
import Foundation
import PomoPetCore
import UserNotifications

@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()

    private var isBundledApp: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil
    }

    private init() {}

    public func requestAuthorizationIfAvailable() {
        guard isBundledApp else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func notifyBreakStarted(phase: TimerPhase, prompt: StretchPrompt, playSound: Bool) {
        if playSound {
            NSSound(named: NSSound.Name("Glass"))?.play()
        }
        guard isBundledApp else { return }

        let content = UNMutableNotificationContent()
        content.title = phase == .longBreak ? "Time for a Long Break" : "Time to Rest Your Eyes"
        content.body = "\(prompt.title) — \(prompt.subtitle)"
        content.sound = playSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: "pomopet.break.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    public func notifyFocusReady(playSound: Bool) {
        if playSound {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
        guard isBundledApp else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Complete"
        content.body = "Refreshed and ready for your next focus session!"
        content.sound = playSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: "pomopet.focus.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
