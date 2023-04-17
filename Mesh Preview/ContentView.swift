import SwiftUI
import MetalKit

struct ContentView: View {
    @EnvironmentObject var sceneData: SceneData

    var body: some View {
        NavigationView {
            List {
                DisclosureGroup("Model Info") {
                    VStack(alignment: .leading) {
                        Text("vertex count")
                        Text("triangle count")
                    }
                }
                
                DisclosureGroup("Viewport Settings") {
                    
                }
                
                DisclosureGroup("Camera Settings") {
                    Button(action: {sceneData.toggleProjection()}) {
                        Text("toggle projection")
                    }
                }
            }
                .frame(maxHeight: .infinity)
                .backgroundStyle(.opacity(0))
                .toolbar {
                    ToolbarItem {
                        Button(action: toggleSidebar) {
                            Label("toggle sidebar visibility", systemImage: "sidebar.left")
                        }
                    }
                }
            
            Viewport3DView()
                .ignoresSafeArea()
        }
            .frame(idealWidth: 400)
           
    }
    
    private func toggleSidebar() { // 2
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
