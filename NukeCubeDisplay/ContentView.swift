import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var isImmersiveSpaceOpen = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("NukeCube")
                .font(.largeTitle.bold())

            Text("Four stakeholder perspectives on Delaware's SMR decision, mapped onto a cube you can twist and explore.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            Button(isImmersiveSpaceOpen ? "Hide the Cube" : "Show the Cube") {
                Task {
                    if isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    } else {
                        switch await openImmersiveSpace(id: "NukeCubeSpace") {
                        case .opened:
                            isImmersiveSpaceOpen = true
                        default:
                            isImmersiveSpaceOpen = false
                        }
                    }
                }
            }
            .font(.title3)
            .buttonStyle(.borderedProminent)
        }
        .padding(48)
    }
}

#Preview {
    ContentView()
}
