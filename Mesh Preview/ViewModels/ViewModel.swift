import SwiftUI

class ViewModel: ObservableObject {
    var sceneData = SceneData()
    
    @Published var modelURL: URL? {
        didSet {
            if let url = modelURL {
                sceneData.modelURL = url
                modelFileSize = fileSize(atURL: url)
            }
        }
    }
    
    @Published private(set) var modelFileSize: Int?
    
    @Published var backgroundColor: Vec3 {
        didSet {
            sceneData.backgroundColor = backgroundColor
        }
    }
    
    @Published var vertexColors: UInt32 {
        didSet {
            sceneData.vertexColors = vertexColors
        }
    }
    
    @Published private(set) var vertexColoringOptions: [vertexColoringOption]
    
    init(scene: SceneData = SceneData()) {
        self.modelURL = sceneData.modelURL
        self.modelFileSize = sceneData.modelFileSize
        self.backgroundColor = sceneData.backgroundColor
        self.vertexColors = sceneData.vertexColors
        self.vertexColoringOptions = sceneData.vertexColoringOptions
    }
}
