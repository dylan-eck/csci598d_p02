import SwiftUI
import MetalKit

struct ContentView: View {
    @EnvironmentObject var sceneData: SceneData

    let items = ["item1", "item2", "item3"]

    var body: some View {
        
        HStack {
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
                
                Viewport3DView()
                    .ignoresSafeArea()
            }
                .frame(idealWidth: 400)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
