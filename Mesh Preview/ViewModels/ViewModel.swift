import SwiftUI

class ViewModel: ObservableObject {
    var sceneData: SceneData
    
    @Published var modelURL: URL? {
        didSet {
            sceneData.modelURL = modelURL
        }
    }
    
    @Published var modelFileSize: Int? {
        didSet {
            sceneData.modelFileSize = modelFileSize
        }
    }
    
    @Published var numVertices: Int? {
        didSet {
            sceneData.numVertices = numVertices
        }
    }
    
    @Published var numTriangles: Int? {
        didSet {
            sceneData.numTriangle = numTriangles
        }
    }
    
    @Published var lightPosition: Vec3 {
        didSet {
            sceneData.lightPosition = lightPosition
        }
    }
    
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
    
    @objc func saveSceneData() {
        saveSceneDataToFile(sceneData: sceneData, fileName: "scene_data.json")
    }
    
    init() {
        sceneData = loadSceneDataFromFile(fileName: "scene_data.json") ?? SceneData()
        
        self.modelURL = sceneData.modelURL
        self.modelFileSize = sceneData.modelFileSize
        self.backgroundColor = sceneData.backgroundColor
        self.vertexColors = sceneData.vertexColors
        self.vertexColoringOptions = sceneData.vertexColoringOptions
        self.lightPosition = sceneData.lightPosition
        self.modelFileSize = sceneData.modelFileSize
        self.numVertices = sceneData.numVertices
        self.numTriangles = sceneData.numTriangle
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveSceneData), name: .appWillTerminate, object: nil)
    }
}

func getApplicationSupportDirectory() -> URL? {
    do {
        let url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appSpecificURL = url.appendingPathComponent("com.dylaneck.MeshPreview", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: appSpecificURL.path) {
            try FileManager.default.createDirectory(at: appSpecificURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appSpecificURL
    } catch {
        print("failed to retrieve application support directory: \(error)")
        return nil
    }
}

func saveSceneDataToFile(sceneData: SceneData, fileName: String) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    do {
        let data = try encoder.encode(sceneData)
        if let dir = getApplicationSupportDirectory() {
            let fileURL = dir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
        }
    } catch {
        print("failed to save scene data: \(error)")
    }
}

func loadSceneDataFromFile(fileName: String) -> SceneData? {
    do {
        guard let dir = getApplicationSupportDirectory() else {
            return nil
        }
        let fileURL = dir.appendingPathComponent(fileName)
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let sceneData = try decoder.decode(SceneData.self, from: data)
        return sceneData
    } catch {
        print("failed to load scene data: \(error)")
        return nil
    }
}

