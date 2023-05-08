import SwiftUI

class ViewModel: ObservableObject {
    @Published var sceneData = SceneData()
    
    var modelURL: URL? {
        get { sceneData.modelURL }
        set { sceneData.modelURL = newValue }
    }
    
    var modelFileSize: Int? {
        get { sceneData.modelFileSize }
        set { sceneData.modelFileSize = newValue }
    }
    
    var backgroundColor: Vec3 {
        get { sceneData.backgroundColor }
        set { sceneData.backgroundColor = newValue }
    }
    
    var vertexColors: UInt32 {
        get { sceneData.vertexColors }
        set { sceneData.vertexColors = newValue }
    }
}
