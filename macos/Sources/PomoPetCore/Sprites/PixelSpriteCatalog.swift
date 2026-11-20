import Foundation

public struct RGBA: Equatable, Sendable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
    public let a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static let clear = RGBA(r: 0, g: 0, b: 0, a: 0)

    public static func fromHex(_ hex: String) -> RGBA {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == "transparent" || trimmed.isEmpty {
            return .clear
        }
        let clean = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else {
            return .clear
        }
        return RGBA(
            r: UInt8((value >> 16) & 0xFF),
            g: UInt8((value >> 8) & 0xFF),
            b: UInt8(value & 0xFF),
            a: 255
        )
    }
}

public struct PixelFrame: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [RGBA]

    public init(width: Int, height: Int, pixels: [RGBA]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

public struct PetAnimation: Equatable, Sendable {
    public let fps: Double
    public let frames: [PixelFrame]
}

public struct PetSpriteSheet: Equatable, Sendable {
    public let id: PetKind
    public let displayName: String
    public let species: String
    public let accentHex: String
    public let states: [PetAnimationState: PetAnimation]
}

public enum SpriteLoaderError: Error, LocalizedError {
    case resourceNotFound
    case invalidDimensions(pet: String, state: String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "Could not locate sprites.json resource."
        case .invalidDimensions(let pet, let state):
            return "Invalid pixel grid dimensions for \(pet) / \(state)."
        }
    }
}

public final class PixelSpriteCatalog: Sendable {
    private let sheets: [PetKind: PetSpriteSheet]

    public init(sheets: [PetKind: PetSpriteSheet]) {
        self.sheets = sheets
    }

    public func sheet(for pet: PetKind) -> PetSpriteSheet? {
        sheets[pet]
    }

    public func animation(for pet: PetKind, state: PetAnimationState) -> PetAnimation? {
        sheets[pet]?.states[state] ?? sheets[pet]?.states[.idle]
    }

    public func frame(for pet: PetKind, state: PetAnimationState, tick: Int) -> PixelFrame? {
        guard let anim = animation(for: pet, state: state), !anim.frames.isEmpty else {
            return nil
        }
        let index = abs(tick) % anim.frames.count
        return anim.frames[index]
    }

    public static func loadBundled() throws -> PixelSpriteCatalog {
        if let url = Bundle.module.url(forResource: "sprites", withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try decode(from: data)
        }
        if let url = Bundle.main.url(forResource: "sprites", withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try decode(from: data)
        }
        throw SpriteLoaderError.resourceNotFound
    }

    public static func decode(from data: Data) throws -> PixelSpriteCatalog {
        let raw = try JSONDecoder().decode(RawCatalog.self, from: data)
        var sheets: [PetKind: PetSpriteSheet] = [:]

        for rawPet in raw.pets {
            guard let petKind = PetKind(rawValue: rawPet.id) else { continue }
            let palette = rawPet.palette.mapValues { RGBA.fromHex($0) }
            var states: [PetAnimationState: PetAnimation] = [:]

            for (stateKey, rawState) in rawPet.states {
                guard let state = PetAnimationState(rawValue: stateKey) else { continue }
                var frames: [PixelFrame] = []
                for rowList in rawState.frames {
                    guard rowList.count == raw.gridSize else {
                        throw SpriteLoaderError.invalidDimensions(pet: rawPet.id, state: stateKey)
                    }
                    var pixels: [RGBA] = []
                    pixels.reserveCapacity(raw.gridSize * raw.gridSize)
                    for row in rowList {
                        guard row.count == raw.gridSize else {
                            throw SpriteLoaderError.invalidDimensions(pet: rawPet.id, state: stateKey)
                        }
                        for ch in row {
                            pixels.append(palette[String(ch)] ?? .clear)
                        }
                    }
                    frames.append(PixelFrame(width: raw.gridSize, height: raw.gridSize, pixels: pixels))
                }
                states[state] = PetAnimation(fps: rawState.fps, frames: frames)
            }

            sheets[petKind] = PetSpriteSheet(
                id: petKind,
                displayName: rawPet.displayName,
                species: rawPet.species,
                accentHex: rawPet.accentHex,
                states: states
            )
        }

        return PixelSpriteCatalog(sheets: sheets)
    }
}

private struct RawCatalog: Decodable {
    let version: Int
    let gridSize: Int
    let pets: [RawPet]
}

private struct RawPet: Decodable {
    let id: String
    let displayName: String
    let species: String
    let accentHex: String
    let palette: [String: String]
    let states: [String: RawState]
}

private struct RawState: Decodable {
    let fps: Double
    let frames: [[String]]
}
