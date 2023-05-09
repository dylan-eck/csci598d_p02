import SwiftUI

class ViewModel: ObservableObject {
    var sceneData: SceneData
    
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
    
    @objc func saveSceneData() {
        print("\n### SAVE ###\n")
        saveSceneDataToFile(sceneData: sceneData, fileName: "scene_data.json")
    }
    
    init() {
        if let sceneData = loadSceneDataFromFile(fileName: "scene_data.json") {
            print("\n loading saved scene data\n")
            self.sceneData = sceneData
        } else {
            self.sceneData = SceneData()
        }
    
        self.modelURL = sceneData.modelURL
        self.modelFileSize = sceneData.modelFileSize
        self.backgroundColor = sceneData.backgroundColor
        self.vertexColors = sceneData.vertexColors
        self.vertexColoringOptions = sceneData.vertexColoringOptions
        
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
            print("\nsaving scene data to \(fileURL)")
            try data.write(to: fileURL)
            print("scene data saved to: \(fileURL)\n")
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

