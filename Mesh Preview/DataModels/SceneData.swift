import Foundation

struct vertexColoringOption: Identifiable, Codable {
    var name: String
    var id: UInt32
}

func fileSize(atURL url: URL) -> Int? {
    do {
        let resourceValues = try url.resourceValues(forKeys: Set([URLResourceKey.fileSizeKey]))
        if let size = resourceValues.fileSize {
            return size
        }
    } catch {
        
    }
    return nil
}

class SceneData: Codable {
    var modelURL: URL?
    var modelFileSize: Int? = nil
    
    var camera = Camera()
    var lastMouseLocation: Vec2? = nil
    var mouseDelta = Vec2(0, 0)
    
    var cameraDistance: Float32 = 1.0
    var minCameraDistance: Float32 = 0.1
    var maxCameraDistance: Float32 = 100.0
    
    var backgroundColor: Vec3 = Vec3(1.0, 0.0, 1.0)
    var vertexColors: UInt32 = VertexAttributeColor.rawValue
    
    
    var vertexColoringOptions = [
        vertexColoringOption(name: "None", id: VertexAttributeNone.rawValue),
        vertexColoringOption(name: "Position", id: VertexAttributePosition.rawValue),
        vertexColoringOption(name: "Color", id: VertexAttributeColor.rawValue),
        vertexColoringOption(name: "Normal", id: VertexAttributeNormal.rawValue),
        vertexColoringOption(name: "Texture Coordinate", id: VertexAttributeTexCoord.rawValue)
    ]
    
    init() {
        camera.position = Vec3(0, 2, 4)
        camera.orthographicFocusPlane = 4
        camera.target = Vec3(0, 0, 0)
        camera.projection = .perspective
        
        cameraDistance = sqrt(dot(camera.position, camera.position))
        
//        if let modelURLBookmark = UserDefaults.standard.data(forKey: UserDefaults.lastURLBookmarkKey) {
//            do {
//                var isStale = false
//                let bookmarkURL = try URL(
//                    resolvingBookmarkData: modelURLBookmark,
//                    options: [.withSecurityScope, .withoutUI],
//                    relativeTo: nil,
//                    bookmarkDataIsStale: &isStale
//                )
//
//                if !isStale && bookmarkURL.startAccessingSecurityScopedResource() {
//                    modelURL = bookmarkURL
//                    bookmarkURL.stopAccessingSecurityScopedResource()
//                }
//            } catch {
//                print("failed to resolve model url bookmark: \(error)")
//            }
//        }
        
    }
    
    func toggleProjection() {
        if camera.projection == .perspective {
            camera.projection = .orthographic
        } else {
            camera.projection = .perspective
        }
    }
    
    func update(viewWidth: Float32, viewHeight: Float32) {
        camera.horizontalResolution = viewWidth
        camera.verticalResolution = viewHeight

        let currentCameraDistance = sqrt(dot(camera.position, camera.position))
        if (abs(cameraDistance - currentCameraDistance) > 0.0001) {
            let cameraDirection = camera.position / currentCameraDistance
            camera.position = cameraDirection * cameraDistance
        }

        
        if mouseDelta != Vec2(0, 0) {            
            let scale: Float32 = 4.0

            let homogeneousPosition = Vec4(camera.position, 1)
            let homogeneousTarget = Vec4(camera.target!, 1)

            var newPosition: Vec4

            let angleRangeX: Float32 = 2 * Float32.pi / camera.horizontalResolution
            let angleRangeY: Float32 = Float32.pi / camera.verticalResolution

            let deltaAngleX = scale * mouseDelta.x * angleRangeX
            let deltaAngleY = scale * mouseDelta.y * angleRangeY

            let xRotation: Mat4 = Mat4.rotate(Mat4(1), deltaAngleX, camera.upDirection)

            newPosition = (xRotation * (homogeneousPosition - homogeneousTarget)) + homogeneousTarget

            let yRotation = Mat4.rotate(Mat4(1), deltaAngleY,
                Vec3(
                    camera.getViewMatrix().transpose[0].x,
                    camera.getViewMatrix().transpose[0].y,
                    camera.getViewMatrix().transpose[0].z
                ))

            newPosition = (yRotation * (newPosition - homogeneousTarget)) + homogeneousTarget
            camera.position = Vec3(newPosition.x, newPosition.y, newPosition.z)
        }
        
        let xzDistanceFromOrigin = sqrt(
            camera.position.x * camera.position.x +
            camera.position.z * camera.position.z
        )

        camera.orthographicFocusPlane = xzDistanceFromOrigin
    }
}
