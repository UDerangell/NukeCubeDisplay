import SwiftUI

/// Shared look for both billboard panels: a solid dark background (rather
/// than a light/adaptive material) with dark-appearance text colors forced
/// explicitly, so `.secondary`/`.primary`/`.tint` read correctly against it
/// regardless of the system's own light/dark setting.
private extension View {
    func panelBackground() -> some View {
        self
            .padding(24)
            .frame(width: 380, alignment: .leading)
            .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 24))
            .environment(\.colorScheme, .dark)
    }
}

/// Left-hand billboard: static instructions for interacting with the cube,
/// plus a small "currently viewing" indicator that updates as the user
/// twists the carousel.
struct InstructionsPanelView: View {
    let currentFace: FaceData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How to Explore", systemImage: "hand.tap")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 10) {
                instructionRow(
                    icon: "hand.point.up.left",
                    text: "Tap any square to read its full statement on the panel to your right."
                )
                instructionRow(
                    icon: "arrow.left.arrow.right",
                    text: "Tap the ‹ and › arrows beside the cube to rotate the carousel and bring the next stakeholder perspective to the front."
                )
                instructionRow(
                    icon: "square.fill",
                    text: "The large glowing square on each face is that perspective's single strongest conviction."
                )
            }

            Divider()

            legendRow(color: .green, label: "Affirms — a position this group holds strongly")
            legendRow(color: .red, label: "Rejects — an argument this group pushes back on")
            legendRow(color: .yellow, label: "Consensus — all four perspectives agree here")

            if let face = currentFace {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently viewing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(face.name)
                        .font(.headline)
                    Text(face.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .panelBackground()
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.tint)
            Text(text)
                .font(.body)
        }
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Right-hand billboard: shows the full text (and supporting detail) of
/// whichever cubie the user most recently tapped.
struct StatementPanelView: View {
    let selection: CubieComponent?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Statement", systemImage: "text.bubble")
                .font(.title3.bold())

            if let selection {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selection.perspectiveName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(selection.text)
                        .font(.title3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        scoreView(selection.score)
                        if selection.isCenter {
                            tag("Core conviction", color: .blue)
                        }
                        if selection.isConsensus {
                            tag("Consensus", color: .yellow)
                        }
                    }
                }
            } else {
                Text("Tap any square on the cube to see its full statement here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .panelBackground()
        .animation(.easeInOut(duration: 0.2), value: selection?.statementId)
    }

    private func scoreView(_ score: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: score >= 0 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
            Text(String(format: "%+.2f", score))
        }
        .font(.caption.bold())
        .foregroundStyle(score >= 0 ? .green : .red)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.25), in: Capsule())
            .foregroundStyle(color)
    }
}
