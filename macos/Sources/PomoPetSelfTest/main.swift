import Foundation
import PomoPetCore

private final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    var stored: PomoSettings
    init(_ settings: PomoSettings = PomoSettings()) { self.stored = settings }
    func load() -> PomoSettings { stored }
    func save(_ settings: PomoSettings) { stored = settings }
}

private func check(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct PomoPetSelfTest {
    @MainActor
    static func main() throws {
        // 1. Sprite catalog validation
        let catalog = try PixelSpriteCatalog.loadBundled()
        for pet in PetKind.allCases {
            guard let sheet = catalog.sheet(for: pet) else {
                check(false, "Missing sheet for \(pet)")
                return
            }
            check(!sheet.displayName.isEmpty, "Empty displayName for \(pet)")
            for state in PetAnimationState.allCases {
                guard let anim = catalog.animation(for: pet, state: state) else {
                    check(false, "Missing state \(state) for \(pet)")
                    return
                }
                check(anim.frames.count >= 2, "Expected >=2 frames for \(pet)/\(state)")
                for frame in anim.frames {
                    check(frame.width == 16 && frame.height == 16 && frame.pixels.count == 256,
                          "Invalid 16x16 frame for \(pet)/\(state)")
                }
            }
        }
        print("PASS: PixelSpriteCatalog (3 pets x 4 states x 16x16 frames)")

        // 2. Focus -> Short Break -> Long Break cadence
        let store = InMemorySettingsStore(
            PomoSettings(focusMinutes: 1, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLongBreak: 2)
        )
        let engine = PomodoroEngine(settingsStore: store)
        var now = Date(timeIntervalSince1970: 1_000)
        check(engine.phase == .focus && engine.formattedTime == "01:00", "Initial state mismatch")

        engine.start(now: now)
        check(engine.petAnimationState == .focusing, "Expected focusing state")
        now = now.addingTimeInterval(60)
        engine.tick(now: now)
        check(engine.phase == .shortBreak && engine.isBreakOverlayPresented, "Expected short break + overlay")
        check(engine.completedFocusInCycle == 1 && engine.totalCompletedToday == 1, "Expected 1 completed focus")

        engine.skipPhase(now: now)
        check(engine.phase == .focus && !engine.isBreakOverlayPresented, "Expected return to focus")

        engine.start(now: now)
        now = now.addingTimeInterval(60)
        engine.tick(now: now)
        check(engine.phase == .longBreak && engine.remainingSeconds == 15 * 60, "Expected long break after 2 sessions")
        check(engine.petAnimationState == .napping, "Expected napping state in long break")
        print("PASS: PomodoroEngine phase & long-break cadence")

        // 3. Snooze & Break Preview
        engine.snoozeBreak(minutes: 5, now: now)
        check(engine.phase == .focus && engine.remainingSeconds == 300 && !engine.isBreakOverlayPresented,
              "Snooze should resume focus for 5 min")

        engine.reset()
        engine.triggerBreakPreview(now: now)
        check(engine.isBreakOverlayPresented && engine.phase == .shortBreak, "Preview should show overlay")
        engine.dismissOverlayOnly()
        check(!engine.isBreakOverlayPresented && engine.phase == .focus, "Dismissing preview should restore focus")
        print("PASS: Snooze & Break Preview")
        print("ALL MACOS SELF-TESTS PASSED!")
    }
}
