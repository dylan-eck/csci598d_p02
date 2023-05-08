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
                            do {
                                let bookmarkData = try url.bookmarkData(
                                    options: [.withSecurityScope],
                                    includingResourceValuesForKeys: nil,
                                    relativeTo: nil
                                )
                                UserDefaults.standard.set(bookmarkData, forKey: UserDefaults.lastURLBookmarkKey)
                            } catch {
                                print("error creating model url bookmark: \(error)")
                            }
                        }
                    }.keyboardShortcut("o", modifiers: .command)
                }
                SidebarCommands()
            }
    }
}
