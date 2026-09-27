import SwiftUI

@main
struct MaterialsIntelligenceApp: App {
    @State private var selection: AppSection? = .overview

    var body: some Scene {
        WindowGroup {
            RootView(selection: $selection)
        }
        .defaultSize(width: 1360, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Materials Intelligence") {
                    selection = .about
                }
            }
        }
    }
}
