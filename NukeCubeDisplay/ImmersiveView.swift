import SwiftUI
import RealityKit

struct ImmersiveView: View {

    private let cubeData = CubeDataLoader.load()

    @State private var controller = CubeTwistController()
    @State private var currentFace: FaceData?
    @State private var selectedCubie: CubieComponent?

    /// Same placement convention used by the Month Dodecahedron project:
    /// roughly arm's length in front of, and slightly below, a user
    /// standing at the space's origin looking down -Z.
    private let cubeRootPosition = SIMD3<Float>(0, 1.4, -1.2)

    var body: some View {
        RealityView { content, attachments in
            let root = Entity()
            root.name = "NukeCubeRoot"
            root.position = cubeRootPosition

            controller.onFrontFaceChanged = { face in
                currentFace = face
            }
            controller.buildCarousel(faces: cubeData.faces, parent: root)

            // Sit just outside the front face's actual visible edge, not
            // out past the carousel's whole rotation radius — a small,
            // fixed gap reads as "attached to the cube" rather than
            // "floating off to the side."
            let buttonGap: Float = 0.05
            let buttonX = CubeGeometry.faceHalfWidth + buttonGap

            let leftButton = CubeGeometry.makeTwistButton(direction: -1)
            leftButton.position = SIMD3<Float>(-buttonX, 0, CubeGeometry.carouselRadius)
            root.addChild(leftButton)

            let rightButton = CubeGeometry.makeTwistButton(direction: 1)
            rightButton.position = SIMD3<Float>(buttonX, 0, CubeGeometry.carouselRadius)
            root.addChild(rightButton)

            content.add(root)

            // Billboard panels: positioned beside the cube in world space
            // (not parented to `root`, so they stay put — and stay
            // face-on to the user via BillboardComponent — regardless of
            // carousel twists). Anchored just past the twist buttons
            // rather than a fixed guess, so "closer to the cube" stays
            // correct if the face size changes later.
            let panelGap: Float = 0.35
            let panelX = buttonX + panelGap

            if let leftPanel = attachments.entity(for: "instructions") {
                leftPanel.position = SIMD3<Float>(cubeRootPosition.x - panelX, cubeRootPosition.y, cubeRootPosition.z + 0.2)
                leftPanel.components.set(BillboardComponent())
                content.add(leftPanel)
            }
            if let rightPanel = attachments.entity(for: "statement") {
                rightPanel.position = SIMD3<Float>(cubeRootPosition.x + panelX, cubeRootPosition.y, cubeRootPosition.z + 0.2)
                rightPanel.components.set(BillboardComponent())
                content.add(rightPanel)
            }
        } attachments: {
            Attachment(id: "instructions") {
                InstructionsPanelView(currentFace: currentFace)
            }
            Attachment(id: "statement") {
                StatementPanelView(selection: selectedCubie)
            }
        }
        .gesture(
            TapGesture().targetedToAnyEntity().onEnded { value in
                if let cubie = value.entity.components[CubieComponent.self] {
                    selectedCubie = cubie
                } else if let button = value.entity.components[TwistButtonComponent.self] {
                    controller.twist(direction: button.direction)
                }
            }
        )
    }
}
