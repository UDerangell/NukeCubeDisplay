import SwiftUI

@main
struct NukeCubeApp: App {

    @State private var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: "NukeCubeSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
