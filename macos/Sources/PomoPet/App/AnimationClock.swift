import Combine
import Foundation

@MainActor
final class AnimationClock: ObservableObject {
    @Published var tick: Int = 0
    @Published var showingSettings: Bool = false
    @Published var isInhaling: Bool = true
    @Published var bobbing: Bool = false
}
