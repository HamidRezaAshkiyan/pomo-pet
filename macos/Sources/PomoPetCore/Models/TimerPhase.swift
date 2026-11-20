import Foundation

public enum TimerPhase: String, Codable, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak

    public var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    public var isBreak: Bool {
        self != .focus
    }
}

public enum PetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case cat
    case dog
    case capybara

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cat: return "Mochi"
        case .dog: return "Biscuit"
        case .capybara: return "Yuzu"
        }
    }

    public var species: String {
        switch self {
        case .cat: return "Cat"
        case .dog: return "Shiba"
        case .capybara: return "Capybara"
        }
    }
}

public enum PetAnimationState: String, Codable, CaseIterable, Sendable {
    case idle
    case focusing
    case stretching
    case napping
}

public struct StretchPrompt: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let iconName: String

    public init(id: Int, title: String, subtitle: String, iconName: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }

    public static let defaults: [StretchPrompt] = [
        StretchPrompt(
            id: 0,
            title: "20-20-20 Eye Rest",
            subtitle: "Look at something 20 feet away for 20 seconds to relax your eye muscles.",
            iconName: "eye"
        ),
        StretchPrompt(
            id: 1,
            title: "Drop & Roll Your Shoulders",
            subtitle: "Inhale deeply, lift shoulders up, then slowly roll them back and down.",
            iconName: "figure.cooldown"
        ),
        StretchPrompt(
            id: 2,
            title: "Stand Up & Reach High",
            subtitle: "Step away from your chair, interlace your fingers, and stretch toward the ceiling.",
            iconName: "figure.stand"
        ),
        StretchPrompt(
            id: 3,
            title: "Hydrate & Unclench",
            subtitle: "Take a sip of water, relax your jaw, and gently tilt your neck side to side.",
            iconName: "drop"
        ),
        StretchPrompt(
            id: 4,
            title: "Wrist & Finger Shake",
            subtitle: "Extend each arm forward, gently pull your fingers back, then shake your hands loose.",
            iconName: "hand.raised"
        )
    ]
}
