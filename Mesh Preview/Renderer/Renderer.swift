import MetalKit
import ModelIO
import SwiftUI

func loadModel(from url: URL, to device: MTLDevice) -> MTKMesh? {
    let vertexDescriptor = MDLVertexDescriptor()
    
    vertexDescriptor.attributes[0] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: 0
    )
    
    vertexDescriptor.attributes[1] = MDLVertexAttribute(
        name: MDLVertexAttributeColor,
        format: .float3,
        offset: MemoryLayout<Float>.stride * 3,
        bufferIndex: 0
    )
    
    vertexDescriptor.attributes[2] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: MemoryLayout<Float>.stride * 6,
        bufferIndex: 0
    )
    
    let bufferAllocator = MTKMeshBufferAllocator(device: device)
    let asset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
    
    guard let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh else {
        return nil
    }
    
    do {
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        return mtkMesh
    } catch {
        return nil
    }
}

func printVertexData(mesh: MTKMesh) {
    guard let vertexBuffer = mesh.vertexBuffers.first?.buffer else {
        print("Error: No vertex buffer found in the mesh")
        return
    }
    
    let vertexCount = vertexBuffer.length / (MemoryLayout<Float>.stride * 6) // 6 floats for position and normal
    let vertexData = vertexBuffer.contents().assumingMemoryBound(to: Float.self)
    
    print("Vertex data (Position [x, y, z], Normal [x, y, z]):")
    for i in 0..<vertexCount {
        let position = SIMD3<Float>(vertexData[6 * i], vertexData[6 * i + 1], vertexData[6 * i + 2])
        let normal = SIMD3<Float>(vertexData[6 * i + 3], vertexData[6 * i + 4], vertexData[6 * i + 5])
        print("Vertex \(i): Position: \(position), Normal: \(normal)")
    }
}

enum RenderDeviceBufferError: Error {
    case creationFailed
}

class Renderer: NSObject, MTKViewDelegate {
    var parent: Viewport3DView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue?
    
    var library: MTLLibrary
    
    let gridPipelineState: MTLRenderPipelineState
    var modelPipelineState: MTLRenderPipelineState? = nil
    
    let depthStencilState: MTLDepthStencilState
    let vertexShaderUniformsBuffer: MTLBuffer
    
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
    
    var sceneData: SceneData
    
    init(_ parent: Viewport3DView, _ scene: SceneData) {
        self.parent = parent
        self.sceneData = scene
        
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
            length: MemoryLayout<VertexShaderUniforms>.stride,
            options: .storageModeShared
        ) {
            vertexShaderUniformsBuffer = buffer
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
            // fatalError(error)
            print(error)
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
        
//
//        let scaleFactor: Float32 = 1.0
//        let scale = simd_float4x4(rows: [
//            [scaleFactor,           0,           0, 0],
//            [          0, scaleFactor,           0, 0],
//            [          0,           0, scaleFactor, 0],
//            [          0,           0,           0, 1],
//        ])

//        let pivot: Float = 0.0
//        let radius: Float = 4.0
//        let xCoord: Float = radius * cos(y_angle)
//        let zCoord: Float = radius * sin(y_angle)
//        camera.setPosition(Vec3(xCoord + pivot, 2, zCoord + pivot))
//        camera.setView(targeting: Vec3(pivot, 0, pivot))
//        camera.setOrthographicFocusPlane(radius)

        var uniforms = VertexShaderUniforms(
            modelMatrix: simd_float4x4(1.0), // TRS
            viewMatrix: sceneData.camera.getViewMatrix(),
            inverseViewMatrix: sceneData.camera.getViewMatrix().inverse,
            projectionMatrix: sceneData.camera.getProjectionMatrix(),
            inverseProjectionMatrix: sceneData.camera.getProjectionMatrix().inverse,
            nearClip: sceneData.camera.nearClippingPlane,
            farClip: sceneData.camera.farClippingPlane
        )
        
        memcpy(vertexShaderUniformsBuffer.contents(), &uniforms, MemoryLayout<VertexShaderUniforms>.stride)
    }
    
    func makeDefaultRenderPassDescriptor(for view: MTKView) -> MTLRenderPassDescriptor? {
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1.0)
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            return renderPassDescriptor
        }
        return nil
    }
    
    func draw(in view: MTKView) {
        let systemTime = CACurrentMediaTime()
        let deltaTime = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        lastRenderTime = systemTime
        
        if let url = sceneData.modelURL, self.modelURL == nil{
            self.modelURL = url
        }
        
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        sceneData.update(
            viewWidth: Float32(view.drawableSize.width),
            viewHeight: Float32(view.drawableSize.height))
        update(deltaTime: Float(deltaTime), aspect: aspect)
        
        guard
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = makeDefaultRenderPassDescriptor(for: view),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        
        renderEncoder.setVertexBuffer(vertexShaderUniformsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(vertexShaderUniformsBuffer, offset: 0, index: 1)

        if self.mesh != nil {
            renderEncoder.setRenderPipelineState(modelPipelineState!)
            renderEncoder.setVertexBuffer(mesh!.vertexBuffers[0].buffer, offset: 0, index: 0)
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

        renderEncoder.setRenderPipelineState(gridPipelineState)
        renderEncoder.setVertexBuffer(gridVertexBuffer, offset: 0, index: 0)
        renderEncoder.setTriangleFillMode(.fill)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding();
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
