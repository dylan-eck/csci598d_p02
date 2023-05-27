import MetalKit
import ModelIO
import simd

extension MTLVertexDescriptor {
    static var defaultDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<simd_float3>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset = 2 * MemoryLayout<simd_float3>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.attributes[3].format = .float2
        vertexDescriptor.attributes[3].offset = 3 * MemoryLayout<simd_float3>.stride
        vertexDescriptor.attributes[3].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = 3 * MemoryLayout<simd_float3>.stride + MemoryLayout<simd_float2>.stride
        
        return vertexDescriptor
    }
}

extension MDLVertexDescriptor {
    static var defaultDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MTKModelIOVertexDescriptorFromMetal(MTLVertexDescriptor.defaultDescriptor)
        
        let position = vertexDescriptor.attributes[0] as! MDLVertexAttribute
        position.name = MDLVertexAttributePosition
        
        let color = vertexDescriptor.attributes[1] as! MDLVertexAttribute
        color.name = MDLVertexAttributeColor
        
        let normal = vertexDescriptor.attributes[2] as! MDLVertexAttribute
        normal.name = MDLVertexAttributeNormal
        
        let uv = vertexDescriptor.attributes[3] as! MDLVertexAttribute
        uv.name = MDLVertexAttributeTextureCoordinate
        
        return vertexDescriptor
    }
}

enum RenderDeviceBufferError: Error {
    case creationFailed
}

class Renderer: NSObject, MTKViewDelegate, CustomMTKViewDelegate {

    var parent: Viewport3DView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue?
    
    var library: MTLLibrary

    let gridPipelineState: MTLRenderPipelineState
    var modelPipelineState: MTLRenderPipelineState? = nil
    
    let depthStencilState: MTLDepthStencilState
    let uniformsBuffer: MTLBuffer
    
    var lastRenderTime: TimeInterval! = nil
    var currentTime: TimeInterval = 0.0
    var y_angle: Float = 0.0
    var x_angle: Float = 0.0
    
    var projectionMatrix = Mat4(1.0)
    
    let yAxisFOV: Float = 45.0
    let nearClip: Float = 0.01
    let farClip: Float  = 100

    var modelURL: URL? = nil {
        didSet {
            prepareModelResources()
        }
    }
    var mesh: MTKMesh? = nil
    
    let gridVertexBuffer: MTLBuffer
    
    var viewModel: ViewModel
    var sceneData: SceneData
    
    init(_ parent: Viewport3DView, _ viewModel: ViewModel) {
        self.parent = parent
        self.viewModel = viewModel
        self.sceneData = viewModel.sceneData
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("failed to get default metal device")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("failed to create default metal library")
        }
        self.library = library
        
        let gridVertices: [Vertex] = [
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0)),
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0)),
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0)),
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0)),
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0)),
            Vertex(position: Vec3(0), color: Vec3(1), normal: Vec3(0))
        ]
        
        if let buffer = device.makeBuffer(
            bytes: gridVertices,
            length: gridVertices.count * MemoryLayout<Vertex>.stride,
            options: []
        ) {
            gridVertexBuffer = buffer
        } else {
            fatalError("failed to create vertex buffer")
        }
        
        let metalVertexDescriptor = MTLVertexDescriptor()

        metalVertexDescriptor.attributes[0] = MTLVertexAttributeDescriptor()
        metalVertexDescriptor.attributes[0].format = .float3
        metalVertexDescriptor.attributes[0].offset = 0
        metalVertexDescriptor.attributes[0].bufferIndex = 0

        metalVertexDescriptor.attributes[1] = MTLVertexAttributeDescriptor()
        metalVertexDescriptor.attributes[1].format = .float3
        metalVertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 3
        metalVertexDescriptor.attributes[1].bufferIndex = 0

        metalVertexDescriptor.attributes[2] = MTLVertexAttributeDescriptor()
        metalVertexDescriptor.attributes[2].format = .float3
        metalVertexDescriptor.attributes[2].offset = MemoryLayout<Float>.stride * 6
        metalVertexDescriptor.attributes[2].bufferIndex = 0

        metalVertexDescriptor.layouts[0] = MTLVertexBufferLayoutDescriptor()
        metalVertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 9
        
        if let state = Renderer.createPipelineState(
            device: device,
            library: library,
            vertexShaderName: "gridVertexShader",
            fragmentShaderName: "gridFragmentShader",
            alphaBlendingEnabled: true,
            vertexDescriptor: metalVertexDescriptor
        ) {
            gridPipelineState = state
        } else {
            fatalError("failed to create pipeline state")
        }
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = .less

        if let state = device.makeDepthStencilState(descriptor: depthDescriptor) {
            depthStencilState = state
        } else {
            fatalError("failed to create depth stencil state")
        }
        
        if let buffer = device.makeBuffer(
            length: MemoryLayout<ShaderUniforms>.stride,
            options: .storageModeShared
        ) {
            uniformsBuffer = buffer
        } else {
            fatalError("failed to create uniforms buffer")
        }

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    static func createPipelineState(
        device: MTLDevice,
        library: MTLLibrary,
        vertexShaderName: String,
        fragmentShaderName: String,
        alphaBlendingEnabled: Bool,
        vertexDescriptor: MTLVertexDescriptor
    ) -> MTLRenderPipelineState? {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()

        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexShaderName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentShaderName)
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        if (alphaBlendingEnabled) {
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
      
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        }
        
        do {
            let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            return pipelineState
        } catch {
            print(error)
            return nil
        }
    }
    
    func getStatistic(from asset: MDLAsset) {
        var totalVertices = 0
        var totalTriangles = 0

        for object in asset.childObjects(of: MDLMesh.self) {
            if let mesh = object as? MDLMesh {
                let vertexCount = mesh.vertexCount
                totalVertices += vertexCount

                var triangleCount = 0
                for submeshIndex in 0..<mesh.submeshes!.count {
                    let submesh = mesh.submeshes![submeshIndex] as! MDLSubmesh
                    if submesh.geometryType == .triangles {
                        triangleCount += submesh.indexCount / 3
                    }
                }
                totalTriangles += triangleCount
            }
        }
        
        viewModel.numVertices = totalVertices
        viewModel.numTriangles = totalTriangles
    }
    
    func loadModel(from url: URL, to device: MTLDevice) -> MTKMesh? {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: MDLVertexDescriptor.defaultDescriptor,
            bufferAllocator: bufferAllocator
        )
        
        let size = fileSize(atURL: url)
        viewModel.modelFileSize = size
        getStatistic(from: asset)
        
        guard let mdlMesh = (
            asset.childObjects(of: MDLMesh.self).first as? MDLMesh
        ) else {
            return nil
        }

        do {
            let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
            
            return mtkMesh
        } catch {
            return nil
        }
    }
    
    func prepareModelResources() {
        guard
            let url = modelURL,
            let model = loadModel(from: url, to: self.device)
        else {
            fatalError("failed to load model")
        }
        
        self.mesh = model

        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh!.vertexDescriptor)!

        if let state = Renderer.createPipelineState(
            device: device,
            library: library,
            vertexShaderName: "vertexShader",
            fragmentShaderName: "fragmentShader",
            alphaBlendingEnabled: false,
            vertexDescriptor: vertexDescriptor
        ) {
            modelPipelineState = state
        } else {
            fatalError("failed to create pipeline state")
        }
    }
    
    func update(deltaTime: Float, aspect: Float) {
        var uniforms = ShaderUniforms(
            modelMatrix: simd_float4x4(1.0), // TRS
            viewMatrix: sceneData.camera.getViewMatrix(),
            inverseViewMatrix: sceneData.camera.getViewMatrix().inverse,
            projectionMatrix: sceneData.camera.getProjectionMatrix(),
            inverseProjectionMatrix: sceneData.camera.getProjectionMatrix().inverse,
            nearClip: sceneData.camera.nearClippingPlane,
            farClip: sceneData.camera.farClippingPlane,
            lightPosition: sceneData.lightPosition,
            attributeSelector: sceneData.vertexColors
        )
        
        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<ShaderUniforms>.stride)
    }
    
    func makeRenderPassDescriptor(for view: MTKView, clearColor: Vec3 = Vec3(1.0, 0.0, 1.0)) -> MTLRenderPassDescriptor? {
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColorMake(
                Double(clearColor.x),
                Double(clearColor.y),
                Double(clearColor.z),
                1.0
            )
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            return renderPassDescriptor
        }
        return nil
    }
    
    
    private var gesturePosLastDraw: CGPoint? = nil
    private var gestureDistLastDraw: CGFloat? = nil
    
    func draw(in view: MTKView) {
        sceneData.mouseDelta = Vec2(0, 0)
        if
            gestureType == .drag,
            let prevPos = gesturePosLastDraw,
            let currPos = currGesturePosition
        {
            let dp = CGPoint(x: currPos.x - prevPos.x, y: -1 * (currPos.y - prevPos.y))
            sceneData.mouseDelta = Vec2(Float32(dp.x), Float32(dp.y))
        }
        gesturePosLastDraw = currGesturePosition
        
        if
            gestureType == .pinch,
            let prevDist = gestureDistLastDraw,
            let currDist = currGestureDistance
        {
            let dd = currDist - prevDist
            sceneData.cameraDistance -= 10.0 * Float32(dd)
        }
        gestureDistLastDraw = currGestureDistance
    
        let systemTime = CACurrentMediaTime()
        let deltaTime = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        lastRenderTime = systemTime
        
        if let url = sceneData.modelURL, url != self.modelURL {
            self.modelURL = url
        }
        
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        sceneData.update(
            viewWidth: Float32(view.drawableSize.width),
            viewHeight: Float32(view.drawableSize.height))
        update(deltaTime: Float(deltaTime), aspect: aspect)
        
        let clearColor = Vec3(
            sceneData.backgroundColor.x,
            sceneData.backgroundColor.y,
            sceneData.backgroundColor.z
        )
        
        guard
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = makeRenderPassDescriptor(for: view, clearColor: clearColor),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)

        if self.mesh != nil {
            renderEncoder.setRenderPipelineState(modelPipelineState!)
            renderEncoder.setVertexBuffer(mesh!.vertexBuffers[0].buffer, offset: 0, index: 0)
            
            renderEncoder.setTriangleFillMode(.fill)
            for submesh in mesh!.submeshes {
                renderEncoder.drawIndexedPrimitives(
                    type: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.buffer,
                    indexBufferOffset: submesh.indexBuffer.offset
                )
            }
        }
        
//        renderEncoder.setRenderPipelineState(gridPipelineState)
//        renderEncoder.setVertexBuffer(gridVertexBuffer, offset: 0, index: 0)
//        renderEncoder.setTriangleFillMode(.fill)
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding();
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
    enum GestureType {
        case drag
        case pinch
        case none
        case any
    }
    
    private var gestureStarted = false
    private var identificationMinUpdates = 10
    
    private var prevGesturePosition: CGPoint? = nil
    private var currGesturePosition: CGPoint? = nil
    private var translationAccumulator: Float32 = 0.0
    
    private var prevGestureDistance: CGFloat? = nil
    private var currGestureDistance: CGFloat? = nil
    private var distanceChangeAccumulator: Float32 = 0.0
    
    private var gestureType: GestureType = .none
    private var gestureUpdateCounter = 0
    
    private var lastUpdateTime: Date?
    
    func handleTouches(_ view: CustomMTKView, touches: Set<NSTouch>) {
        if touches.count == 2 {
            let touchArray = Array(touches)
            let touch1 = touchArray[0]
            let touch2 = touchArray[1]
            
            let midpointX = touches.reduce(0.0) { $0 + $1.normalizedPosition.x } / CGFloat(touches.count)
            let midpointY = touches.reduce(0.0) { $0 + $1.normalizedPosition.y } / CGFloat(touches.count)
            
            currGesturePosition = CGPoint(x: midpointX, y: midpointY)
            
            let dx = touch1.normalizedPosition.x - touch2.normalizedPosition.x
            let dy = touch1.normalizedPosition.y - touch2.normalizedPosition.y
            let distance = sqrt(dx*dx + dy*dy)
            currGestureDistance = distance
            
            if !gestureStarted {
                gestureStarted = true
            }
            
            if gestureUpdateCounter < identificationMinUpdates {
                
                if
                    let prevPos = prevGesturePosition,
                    let currPos = currGesturePosition,
                    let prevDist = prevGestureDistance,
                    let currDist = currGestureDistance
                {
                    let dpmag = abs(length(Vec2(currPos) - Vec2(prevPos)))
                    let ddmag = Float32(abs(currDist - prevDist))
                    
                    translationAccumulator += dpmag
                    distanceChangeAccumulator += ddmag
                }
            } else {
                if translationAccumulator > distanceChangeAccumulator {
                    gestureType = .drag
                } else {
                    gestureType = .pinch
                }
            }
            
            if let currPos = currGesturePosition, let currDist = currGestureDistance {
                prevGesturePosition = currPos
                prevGestureDistance = currDist
            }
            
            gestureUpdateCounter += 1
            
        } else if gestureStarted{
            gestureStarted = false
            prevGesturePosition = nil
            currGesturePosition = nil
            translationAccumulator = 0.0
            prevGestureDistance = nil
            currGestureDistance = nil
            distanceChangeAccumulator = 0.0
            gestureType = .none
            gestureUpdateCounter = 0
        }
    }
}

