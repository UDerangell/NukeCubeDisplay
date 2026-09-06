import Foundation
import RealityKit
import simd

/// Implements the "4-panel carousel" simplification of a true twisting
/// Rubik's cube (see the project brief, section 5): the four perspective
/// panels sit at 90-degree intervals around a vertical axis, all facing
/// outward, and a "twist" rotates the whole assembly so the next or
/// previous panel swings into view where the front panel used to be.
/// There is no per-layer cubie decomposition — this deliberately trades
/// mechanical realism for a much simpler and more robust implementation.
@MainActor
final class CubeTwistController {

    private(set) var carouselEntity: Entity?
    private(set) var frontIndex: Int = 0
    private(set) var faces: [FaceData] = []

    /// Called whenever the front-facing perspective changes, so the UI
    /// (e.g. the instructions panel's "currently viewing" label) can update.
    var onFrontFaceChanged: ((FaceData) -> Void)?

    private var rotationSteps: Int = 0
    private var isAnimating = false

    /// Builds the carousel root, containing all 4 face panels positioned
    /// and oriented around the vertical axis, and adds it to `parent`.
    func buildCarousel(faces: [FaceData], parent: Entity) {
        self.faces = faces
        let carousel = Entity()
        carousel.name = "carousel"

        for (index, face) in faces.enumerated() {
            let panel = CubeGeometry.buildFacePanel(face)
            let angle = Float(index) * (.pi / 2)
            // Position the panel on the circle, oriented so its default
            // +Z-facing normal points radially outward.
            panel.position = SIMD3<Float>(sin(angle), 0, cos(angle)) * CubeGeometry.carouselRadius
            panel.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            carousel.addChild(panel)
        }

        parent.addChild(carousel)
        self.carouselEntity = carousel

        if let first = faces.first {
            onFrontFaceChanged?(first)
        }
    }

    /// Rotates the carousel by one quarter turn.
    /// `direction`: -1 twists left (previous face becomes front),
    /// +1 twists right (next face becomes front).
    func twist(direction: Int) {
        guard let carousel = carouselEntity, !isAnimating else { return }
        guard direction == 1 || direction == -1 else { return }

        isAnimating = true
        rotationSteps -= direction
        frontIndex = ((frontIndex + direction) % faces.count + faces.count) % faces.count

        let angle = Float(rotationSteps) * (.pi / 2)
        let newRotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
        var target = carousel.transform
        target.rotation = newRotation

        carousel.move(to: target, relativeTo: carousel.parent, duration: 0.5, timingFunction: .easeInOut)

        let landedIndex = frontIndex
        Task {
            try? await Task.sleep(for: .milliseconds(520))
            isAnimating = false
            if landedIndex < faces.count {
                onFrontFaceChanged?(faces[landedIndex])
            }
        }
    }
}
