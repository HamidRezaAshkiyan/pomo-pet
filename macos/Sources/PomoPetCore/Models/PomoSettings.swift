import Foundation

public struct PomoSettings: Codable, Equatable, Sendable {
    public var focusMinutes: Int
    public var shortBreakMinutes: Int
    public var longBreakMinutes: Int
    public var sessionsBeforeLongBreak: Int
    public var selectedPet: PetKind
    public var showFullScreenBreakOverlay: Bool
    public var showTimerInMenuBar: Bool
    public var playSoundChime: Bool
    public var autoStartNextPhase: Bool

    public init(
        focusMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        sessionsBeforeLongBreak: Int = 4,
        selectedPet: PetKind = .cat,
        showFullScreenBreakOverlay: Bool = true,
        showTimerInMenuBar: Bool = true,
        playSoundChime: Bool = true,
        autoStartNextPhase: Bool = false
    ) {
        self.focusMinutes = max(1, focusMinutes)
        self.shortBreakMinutes = max(1, shortBreakMinutes)
        self.longBreakMinutes = max(1, longBreakMinutes)
        self.sessionsBeforeLongBreak = max(1, sessionsBeforeLongBreak)
        self.selectedPet = selectedPet
        self.showFullScreenBreakOverlay = showFullScreenBreakOverlay
        self.showTimerInMenuBar = showTimerInMenuBar
        self.playSoundChime = playSoundChime
        self.autoStartNextPhase = autoStartNextPhase
    }

    public func durationSeconds(for phase: TimerPhase) -> Int {
        switch phase {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }
}

public protocol SettingsStore: Sendable {
    func load() -> PomoSettings
    func save(_ settings: PomoSettings)
}

public final class UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "com.pomopet.settings.v1") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> PomoSettings {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(PomoSettings.self, from: data) else {
            return PomoSettings()
        }
        return decoded
    }

    public func save(_ settings: PomoSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
