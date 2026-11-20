import PomoPetCore
import SwiftUI

struct AnimatedPetView: View {
    let catalog: PixelSpriteCatalog
    let pet: PetKind
    let state: PetAnimationState
    let size: CGFloat
    let frameTick: Int
    let bobbing: Bool

    var body: some View {
        Group {
            if let frame = catalog.frame(for: pet, state: state, tick: frameTick),
               let img = PixelImageRenderer.swiftUIImage(from: frame, scale: 6) {
                img
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .offset(y: bobbing ? -2.5 : 1.5)
                    .animation(.easeInOut(duration: 0.45), value: bobbing)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            }
        }
    }
}
