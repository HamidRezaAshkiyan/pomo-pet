import XCTest
@testable import PomoPetCore

final class PixelSpriteCatalogTests: XCTestCase {
    func testLoadsBundledSprites() throws {
        let catalog = try PixelSpriteCatalog.loadBundled()

        for pet in PetKind.allCases {
            let sheet = try XCTUnwrap(catalog.sheet(for: pet))
            XCTAssertFalse(sheet.displayName.isEmpty)

            for state in PetAnimationState.allCases {
                let anim = try XCTUnwrap(catalog.animation(for: pet, state: state))
                XCTAssertGreaterThanOrEqual(anim.frames.count, 2)
                for frame in anim.frames {
                    XCTAssertEqual(frame.width, 16)
                    XCTAssertEqual(frame.height, 16)
                    XCTAssertEqual(frame.pixels.count, 256)
                }
            }
        }
    }
}
