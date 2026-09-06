import Foundation
import RealityKit
import simd

/// Attached to every tappable cubie entity so the tap handler can identify
/// what it represents without re-parsing entity names.
struct CubieComponent: Component {
    let perspectiveId: String
    let perspectiveName: String
    let statementId: String
    let text: String
    let score: Double
    let isCenter: Bool
    let isConsensus: Bool
}

/// Marks the two twist-control buttons so the tap handler can tell them
/// apart from cubies.
struct TwistButtonComponent: Component {
    /// -1 = twist left (bring the previous face to the front),
    /// +1 = twist right (bring the next face to the front).
    let direction: Int
}

enum CubeGeometry {

    /// Spacing between adjacent cubie centers within a face's 3x3 grid.
    ///
    /// This has to clear the oversized center cubie's half-width (0.12,
    /// from `centerSize`) plus a normal cubie's half-width (0.07, from
    /// `cellSize`) — 0.19 — or the center cubie physically overlaps its
    /// neighbors. 0.24 leaves a visible ~0.05 gap on top of that, i.e. real
    /// padding rather than just "not overlapping."
    static let cellPitch: Float = 0.24
    /// Rendered size of a normal (non-center) cubie square.
    static let cellSize: Float = 0.14
    /// Rendered size of the oversized center cubie.
    static let centerSize: Float = 0.24
    /// How far the center cubie protrudes toward the viewer.
    static let centerProtrusion: Float = 0.025

    /// Distance from the carousel's vertical axis to each face panel —
    /// large enough that adjacent faces (90 degrees apart) don't overlap
    /// at the corners. Widened along with `cellPitch` above, since a wider
    /// face needs more clearance to avoid clipping its neighbor.
    static let carouselRadius: Float = 0.55

    /// Half the visible width of a face panel (center to the outer edge of
    /// its outermost column), used to place things like the twist buttons
    /// snugly against a face's actual edge rather than guessing a distance
    /// from the carousel's rotation radius.
    static let faceHalfWidth: Float = cellPitch + cellSize / 2

    /// Builds one face panel (a 3x3 grid of cubies) for the given face data,
    /// as a standalone entity centered on its own local origin, facing +Z.
    /// The caller is responsible for positioning/rotating it onto the
    /// carousel (see `CubeTwistController`).
    @MainActor
    static func buildFacePanel(_ face: FaceData) -> Entity {
        let panel = Entity()
        panel.name = "facePanel_\(face.perspectiveId)"

        // Grid layout: center gets the oversized/protruding cubie; the 8
        // secondary statements fill the remaining positions in reading
        // order (top-left to bottom-right), matching the order they
        // already appear in cube_data.json.
        let gridPositions: [(row: Int, col: Int)] = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]

        // Center cubie.
        let centerEntity = makeCubieEntity(
            data: face.centerCubie,
            face: face,
            isCenter: true,
            size: centerSize
        )
        centerEntity.position = SIMD3<Float>(0, 0, centerProtrusion)
        panel.addChild(centerEntity)

        // 8 secondary cubies.
        for (cubieData, pos) in zip(face.cubies, gridPositions) {
            let entity = makeCubieEntity(
                data: cubieData,
                face: face,
                isCenter: false,
                size: cellSize
            )
            entity.position = SIMD3<Float>(Float(pos.col) * cellPitch, Float(-pos.row) * cellPitch, 0)
            panel.addChild(entity)
        }

        return panel
    }

    @MainActor
    private static func makeCubieEntity(data: CubieData, face: FaceData, isCenter: Bool, size: Float) -> Entity {
        let mesh = MeshResource.generatePlane(width: size, height: size)

        let kind: TextTexture.CubieKind
        if isCenter {
            kind = .center
        } else if data.isConsensusStatement {
            kind = .consensus
        } else if data.polarity == "reject" {
            kind = .reject
        } else {
            kind = .affirm
        }

        let material = TextTexture.makeCubieMaterial(text: data.text, kind: kind)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "cubie_\(face.perspectiveId)_\(data.statementId)"

        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(size, size, 0.01))]))
        entity.components.set(HoverEffectComponent())
        entity.components.set(CubieComponent(
            perspectiveId: face.perspectiveId,
            perspectiveName: face.name,
            statementId: data.statementId,
            text: data.text,
            score: data.score,
            isCenter: isCenter,
            isConsensus: data.isConsensusStatement
        ))

        return entity
    }

    /// A simple flat arrow button used to twist the carousel.
    @MainActor
    static func makeTwistButton(direction: Int) -> Entity {
        let size: Float = 0.12
        let mesh = MeshResource.generatePlane(width: size, height: size)
        let label = direction < 0 ? "\u{2039}" : "\u{203A}" // ‹ ›
        let material = TextTexture.makeCubieMaterial(text: label, kind: .center)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = direction < 0 ? "twistLeftButton" : "twistRightButton"
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(size, size, 0.01))]))
        entity.components.set(HoverEffectComponent())
        entity.components.set(TwistButtonComponent(direction: direction))

        return entity
    }
}
