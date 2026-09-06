import Foundation
import RealityKit
import SwiftUI

/// Rasterizes a cubie's label to a small square texture and wraps it as an
/// unlit RealityKit material — same approach as the Month Dodecahedron
/// project, but built entirely on SwiftUI's `ImageRenderer` instead of
/// UIKit's `UIGraphicsImageRenderer`. The content being rendered
/// (`CubieFace` below) is an ordinary SwiftUI `View`, styled with
/// `Font`/`Color` rather than `UIFont`/`UIColor`, and `ImageRenderer.cgImage`
/// is used deliberately instead of `.uiImage` — `CGImage` is a Core
/// Graphics type, not a UIKit one, so reading it out this way doesn't pull
/// UIKit back in.
///
/// One honest caveat: `UnlitMaterial`'s tint APIs are typed as
/// `RealityKit.Material.Color`, which on visionOS is itself a `UIColor`
/// alias — RealityKit depends on UIKit internally on this platform whether
/// or not this file ever writes the word "UIKit". What this file *does*
/// avoid is ever spelling that out: it only ever touches texture-based
/// materials (built from a `CGImage`), never a solid tint, so no line here
/// needs to name `UIColor` or import UIKit to compile.
///
/// Note on orientation: this still uses RealityKit's built-in
/// `MeshResource.generatePlane`, which has its own correct default UV
/// mapping (see `CubeGeometry.swift`), so the upside-down-text issue from
/// the dodecahedron's hand-rolled UV math doesn't apply here regardless of
/// which renderer produced the texture.
enum TextTexture {

    /// Texture size in points; `renderScale` controls the actual pixel
    /// density (2x here gives a 1024x1024 texture from a 512x512 view).
    private static let textureSize: CGFloat = 512
    private static let renderScale: CGFloat = 2

    enum CubieKind {
        case center
        case affirm
        case reject
        case consensus // overrides affirm/reject styling to flag shared ground
    }

    @MainActor
    static func makeCubieMaterial(text: String, kind: CubieKind) -> UnlitMaterial {
        var material = UnlitMaterial()
        if let texture = makeTexture(text: text, kind: kind) {
            material.color = .init(texture: .init(texture))
        }
        // If texture generation fails, `material` simply keeps
        // UnlitMaterial's own default appearance rather than reaching for
        // a UIColor-typed tint fallback — see the type-level note above.
        return material
    }

    @MainActor
    private static func makeTexture(text: String, kind: CubieKind) -> TextureResource? {
        let content = CubieFace(text: text, kind: kind)
            .frame(width: textureSize, height: textureSize)

        let renderer = ImageRenderer(content: content)
        renderer.scale = renderScale
        renderer.isOpaque = true

        guard let cgImage = renderer.cgImage else { return nil }
        return try? TextureResource(image: cgImage, options: .init(semantic: .color))
    }

    fileprivate static func colors(for kind: CubieKind) -> (background: Color, foreground: Color, accent: Color) {
        switch kind {
        case .center:
            return (Color(red: 0.20, green: 0.45, blue: 0.85), .white, Color.white.opacity(0.9))
        case .affirm:
            return (Color(red: 0.10, green: 0.35, blue: 0.22), .white, Color(red: 0.4, green: 0.9, blue: 0.6))
        case .reject:
            return (Color(red: 0.42, green: 0.12, blue: 0.12), .white, Color(red: 0.95, green: 0.4, blue: 0.4))
        case .consensus:
            return (Color(red: 0.45, green: 0.36, blue: 0.05), .white, Color(red: 1.0, green: 0.84, blue: 0.2))
        }
    }

    /// The cubie's visible content, expressed as a plain SwiftUI view and
    /// rasterized by `ImageRenderer` — no UIKit types anywhere in this file.
    private struct CubieFace: View {
        let text: String
        let kind: CubieKind

        var body: some View {
            let (background, foreground, accent) = colors(for: kind)
            let borderWidth: CGFloat = kind == .center ? 14 : 10
            let fontSize: CGFloat = kind == .center ? 46 : 38
            let weight: Font.Weight = kind == .center ? .bold : .semibold

            ZStack {
                background
                Rectangle()
                    .strokeBorder(accent, lineWidth: borderWidth)
                Text(text)
                    .font(.system(size: fontSize, weight: weight))
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.center)
                    .padding(48)
            }
        }
    }
}
