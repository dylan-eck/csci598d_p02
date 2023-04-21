import SwiftUI
import MetalKit

struct ContentView: View {
    @EnvironmentObject var sceneData: SceneData

    var body: some View {
        NavigationView {
            List {
                DisclosureGroup("Mesh Info") {
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
                                .imageScale(.large)
                        }
                    }
                }
            
            Viewport3DView()
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let mouseLocation = Vec2(Float32(value.location.x), Float32(value.location.y))
                            if let lastLocation = sceneData.lastMouseLocation {
                                sceneData.mouseDelta = mouseLocation - lastLocation
                            }
                            sceneData.lastMouseLocation = mouseLocation
                        }
                        .onEnded { value in
                            sceneData.mouseDelta = Vec2(0, 0)
                            sceneData.lastMouseLocation = nil
                        }
                )
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
