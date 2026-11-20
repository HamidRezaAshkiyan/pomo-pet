import Foundation
import Combine

@MainActor
public final class PomodoroEngine: ObservableObject {
    @Published public private(set) var phase: TimerPhase = .focus
    @Published public private(set) var remainingSeconds: Int
    @Published public private(set) var totalPhaseSeconds: Int
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var completedFocusInCycle: Int = 0
    @Published public private(set) var totalCompletedToday: Int = 0
    @Published public private(set) var isBreakOverlayPresented: Bool = false
    @Published public private(set) var currentStretchPrompt: StretchPrompt = StretchPrompt.defaults[0]
    @Published public var settings: PomoSettings {
        didSet {
            settingsStore.save(settings)
            if !isRunning {
                let updated = settings.durationSeconds(for: phase)
                if remainingSeconds == totalPhaseSeconds {
                    remainingSeconds = updated
                }
                totalPhaseSeconds = updated
            }
        }
    }

    public var onBreakStarted: ((TimerPhase, StretchPrompt) -> Void)?
    public var onFocusStarted: (() -> Void)?
    public var onOverlayDismissed: (() -> Void)?

    private let settingsStore: SettingsStore
    private var promptIndex: Int = 0
    private var targetEndDate: Date?
    private var isPreviewingBreak: Bool = false
    private var savedBeforePreview: (phase: TimerPhase, remaining: Int, total: Int, wasRunning: Bool)?

    public init(settingsStore: SettingsStore = UserDefaultsSettingsStore()) {
        self.settingsStore = settingsStore
        let loaded = settingsStore.load()
        self.settings = loaded
        let initialDuration = loaded.durationSeconds(for: .focus)
        self.remainingSeconds = initialDuration
        self.totalPhaseSeconds = initialDuration
    }

    // MARK: - Computed Properties

    public var progress: Double {
        guard totalPhaseSeconds > 0 else { return 0 }
        let elapsed = Double(totalPhaseSeconds - remainingSeconds)
        return min(max(elapsed / Double(totalPhaseSeconds), 0), 1)
    }

    public var formattedTime: String {
        let clamped = max(0, remainingSeconds)
        let mins = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var petAnimationState: PetAnimationState {
        if isBreakOverlayPresented {
            return phase == .longBreak ? .napping : .stretching
        }
        if !isRunning {
            return .idle
        }
        switch phase {
        case .focus:
            return .focusing
        case .shortBreak:
            return .stretching
        case .longBreak:
            return .napping
        }
    }

    public var statusSubtitle: String {
        let name = settings.selectedPet.displayName
        if isBreakOverlayPresented {
            return "\(name) says: time to stretch & breathe"
        }
        if !isRunning {
            return "\(name) is waiting for your next session"
        }
        switch phase {
        case .focus:
            return "\(name) is focusing with you"
        case .shortBreak:
            return "\(name) is stretching — rest your eyes"
        case .longBreak:
            return "\(name) is taking a cozy nap"
        }
    }

    // MARK: - Controls

    public func start(now: Date = Date()) {
        guard !isRunning else { return }
        isRunning = true
        targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
    }

    public func pause(now: Date = Date()) {
        guard isRunning else { return }
        syncRemaining(now: now)
        isRunning = false
        targetEndDate = nil
    }

    public func toggle(now: Date = Date()) {
        if isRunning {
            pause(now: now)
        } else {
            start(now: now)
        }
    }

    public func reset() {
        isRunning = false
        targetEndDate = nil
        dismissOverlayIfNeeded()
        totalPhaseSeconds = settings.durationSeconds(for: phase)
        remainingSeconds = totalPhaseSeconds
    }

    public func selectPet(_ pet: PetKind) {
        settings.selectedPet = pet
    }

    public func skipPhase(now: Date = Date()) {
        if isPreviewingBreak {
            endBreakPreview(now: now)
            return
        }
        dismissOverlayIfNeeded()
        advancePhase(completedNaturally: false, now: now)
    }

    public func snoozeBreak(minutes: Int = 5, now: Date = Date()) {
        if isPreviewingBreak {
            endBreakPreview(now: now)
            return
        }
        dismissOverlayIfNeeded()
        phase = .focus
        let snoozeSecs = max(1, minutes) * 60
        totalPhaseSeconds = snoozeSecs
        remainingSeconds = snoozeSecs
        isRunning = true
        targetEndDate = now.addingTimeInterval(TimeInterval(snoozeSecs))
    }

    public func triggerBreakPreview(now: Date = Date()) {
        guard !isBreakOverlayPresented else { return }
        savedBeforePreview = (phase, remainingSeconds, totalPhaseSeconds, isRunning)
        isPreviewingBreak = true
        isRunning = true
        phase = .shortBreak
        totalPhaseSeconds = 60
        remainingSeconds = 60
        targetEndDate = now.addingTimeInterval(60)
        advanceStretchPrompt()
        isBreakOverlayPresented = true
        onBreakStarted?(.shortBreak, currentStretchPrompt)
    }

    public func dismissOverlayOnly() {
        if isPreviewingBreak {
            endBreakPreview(now: Date())
            return
        }
        dismissOverlayIfNeeded()
    }

    public func tick(now: Date = Date()) {
        guard isRunning else { return }
        syncRemaining(now: now)
        if remainingSeconds <= 0 {
            if isPreviewingBreak {
                endBreakPreview(now: now)
            } else {
                advancePhase(completedNaturally: true, now: now)
            }
        }
    }

    // MARK: - Internal Helpers

    private func syncRemaining(now: Date) {
        guard let end = targetEndDate else { return }
        let diff = Int(ceil(end.timeIntervalSince(now)))
        remainingSeconds = max(0, diff)
    }

    private func endBreakPreview(now: Date) {
        isPreviewingBreak = false
        dismissOverlayIfNeeded()
        if let saved = savedBeforePreview {
            phase = saved.phase
            remainingSeconds = saved.remaining
            totalPhaseSeconds = saved.total
            isRunning = saved.wasRunning
            targetEndDate = saved.wasRunning ? now.addingTimeInterval(TimeInterval(saved.remaining)) : nil
            savedBeforePreview = nil
        }
    }

    private func dismissOverlayIfNeeded() {
        if isBreakOverlayPresented {
            isBreakOverlayPresented = false
            onOverlayDismissed?()
        }
    }

    private func advanceStretchPrompt() {
        let prompts = StretchPrompt.defaults
        currentStretchPrompt = prompts[promptIndex % prompts.count]
        promptIndex += 1
    }

    private func advancePhase(completedNaturally: Bool, now: Date) {
        let nextPhase: TimerPhase
        if phase == .focus {
            if completedNaturally {
                completedFocusInCycle += 1
                totalCompletedToday += 1
            }
            if completedFocusInCycle >= settings.sessionsBeforeLongBreak {
                completedFocusInCycle = 0
                nextPhase = .longBreak
            } else {
                nextPhase = .shortBreak
            }
        } else {
            nextPhase = .focus
        }

        phase = nextPhase
        totalPhaseSeconds = settings.durationSeconds(for: nextPhase)
        remainingSeconds = totalPhaseSeconds

        if nextPhase.isBreak {
            advanceStretchPrompt()
            isRunning = true
            targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
            if settings.showFullScreenBreakOverlay {
                isBreakOverlayPresented = true
            }
            onBreakStarted?(nextPhase, currentStretchPrompt)
        } else {
            dismissOverlayIfNeeded()
            if settings.autoStartNextPhase {
                isRunning = true
                targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
            } else {
                isRunning = false
                targetEndDate = nil
            }
            onFocusStarted?()
        }
    }
}
