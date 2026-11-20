import Foundation
import XCTest
@testable import PomoPetCore

private final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    var stored: PomoSettings
    init(_ settings: PomoSettings = PomoSettings()) { self.stored = settings }
    func load() -> PomoSettings { stored }
    func save(_ settings: PomoSettings) { stored = settings }
}

@MainActor
final class PomodoroEngineTests: XCTestCase {
    func testInitialState() {
        let store = InMemorySettingsStore(PomoSettings(focusMinutes: 25, shortBreakMinutes: 5))
        let engine = PomodoroEngine(settingsStore: store)

        XCTAssertEqual(engine.phase, .focus)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertEqual(engine.formattedTime, "25:00")
        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.petAnimationState, .idle)
    }

    func testFocusToShortBreak() {
        let store = InMemorySettingsStore(
            PomoSettings(focusMinutes: 1, shortBreakMinutes: 5, sessionsBeforeLongBreak: 4, showFullScreenBreakOverlay: true)
        )
        let engine = PomodoroEngine(settingsStore: store)
        var breakCallbackFired = false
        engine.onBreakStarted = { phase, _ in
            if phase == .shortBreak { breakCallbackFired = true }
        }

        let start = Date(timeIntervalSince1970: 1_000)
        engine.start(now: start)
        XCTAssertEqual(engine.petAnimationState, .focusing)

        engine.tick(now: start.addingTimeInterval(30))
        XCTAssertEqual(engine.remainingSeconds, 30)

        engine.tick(now: start.addingTimeInterval(60))
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.completedFocusInCycle, 1)
        XCTAssertEqual(engine.totalCompletedToday, 1)
        XCTAssertTrue(engine.isBreakOverlayPresented)
        XCTAssertEqual(engine.petAnimationState, .stretching)
        XCTAssertTrue(breakCallbackFired)
    }

    func testLongBreakCadence() {
        let store = InMemorySettingsStore(
            PomoSettings(focusMinutes: 1, shortBreakMinutes: 1, longBreakMinutes: 15, sessionsBeforeLongBreak: 2)
        )
        let engine = PomodoroEngine(settingsStore: store)
        var now = Date(timeIntervalSince1970: 2_000)

        engine.start(now: now)
        now = now.addingTimeInterval(60)
        engine.tick(now: now)
        XCTAssertEqual(engine.phase, .shortBreak)

        engine.skipPhase(now: now)
        XCTAssertEqual(engine.phase, .focus)

        engine.start(now: now)
        now = now.addingTimeInterval(60)
        engine.tick(now: now)
        XCTAssertEqual(engine.phase, .longBreak)
        XCTAssertEqual(engine.remainingSeconds, 15 * 60)
        XCTAssertEqual(engine.petAnimationState, .napping)
        XCTAssertEqual(engine.completedFocusInCycle, 0)
        XCTAssertEqual(engine.totalCompletedToday, 2)
    }

    func testSnoozeBehavior() {
        let store = InMemorySettingsStore(PomoSettings(focusMinutes: 1, shortBreakMinutes: 5))
        let engine = PomodoroEngine(settingsStore: store)
        let start = Date(timeIntervalSince1970: 3_000)

        engine.start(now: start)
        engine.tick(now: start.addingTimeInterval(60))
        XCTAssertTrue(engine.isBreakOverlayPresented)

        engine.snoozeBreak(minutes: 5, now: start.addingTimeInterval(61))
        XCTAssertFalse(engine.isBreakOverlayPresented)
        XCTAssertEqual(engine.phase, .focus)
        XCTAssertEqual(engine.remainingSeconds, 300)
        XCTAssertTrue(engine.isRunning)
    }

    func testBreakPreviewRestoresState() {
        let store = InMemorySettingsStore(PomoSettings(focusMinutes: 25))
        let engine = PomodoroEngine(settingsStore: store)
        let now = Date(timeIntervalSince1970: 4_000)

        engine.triggerBreakPreview(now: now)
        XCTAssertTrue(engine.isBreakOverlayPresented)
        XCTAssertEqual(engine.phase, .shortBreak)

        engine.dismissOverlayOnly()
        XCTAssertFalse(engine.isBreakOverlayPresented)
        XCTAssertEqual(engine.phase, .focus)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertFalse(engine.isRunning)
    }
}
