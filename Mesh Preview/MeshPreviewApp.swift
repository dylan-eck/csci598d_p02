import SwiftUI

@main
struct MeshPreviewApp: App {
    @StateObject var sceneData = SceneData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sceneData)
                .ignoresSafeArea()
        }
            .windowStyle(HiddenTitleBarWindowStyle())
            .commands {
                CommandGroup(replacing: CommandGroupPlacement.newItem) {
                    Button("Open File...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            sceneData.modelURL = panel.url
                        }
                    }.keyboardShortcut("o", modifiers: .command)
                }
                SidebarCommands()
            }
    }
}
