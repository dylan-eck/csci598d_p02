import SwiftUI

@main
struct MeshPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .ignoresSafeArea()
        }
            .windowStyle(HiddenTitleBarWindowStyle())
            .commands {
                CommandGroup(replacing: CommandGroupPlacement.newItem) {
                    Button("Open File...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            viewModel.modelURL = url
                        }
                    }.keyboardShortcut("o", modifiers: .command)
                }
                SidebarCommands()
            }
    }
}
