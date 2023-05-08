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

func loadModel(from url: URL, to device: MTLDevice) -> MTKMesh? {
    
    let bufferAllocator = MTKMeshBufferAllocator(device: device)
    let asset = MDLAsset(
        url: url,
        vertexDescriptor: MDLVertexDescriptor.defaultDescriptor,
        bufferAllocator: bufferAllocator
    )
    
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

enum RenderDeviceBufferError: Error {
    case creationFailed
}

class Renderer: NSObject, MTKViewDelegate {
    var parent: Viewport3DView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue?
    
    var library: MTLLibrary

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
    
    func draw(in view: MTKView) {
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
        
        renderEncoder.endEncoding();
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private var panSensitivity: Float32 = 1.0
    
    
    @objc func handlePanGesture(_ gestureRecognizer: NSPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)

        if gestureRecognizer.state == .ended {
            sceneData.lastMouseLocation = nil
            sceneData.mouseDelta = Vec2(0, 0)
        } else {
            let currentMouseLocation = Vec2(Float32(translation.x), Float32(-translation.y))
            if let lastMouseLocation = sceneData.lastMouseLocation {
                let mouseDelta = (currentMouseLocation - lastMouseLocation) * panSensitivity
                if abs(mouseDelta.x) > 0.0001 && abs(mouseDelta.y) > 0.0001 {
                    sceneData.mouseDelta = mouseDelta
                } else {
                    sceneData.mouseDelta = Vec2(0, 0)
                }
            }
            sceneData.lastMouseLocation = currentMouseLocation
        }
    }
    
    private let minValue: Float32 = 0.5
    private let maxValue: Float32 = 2.0
    private var currentScale: Float32 = 1.0
    private var sensitivity: Float32 = 0.01
    
    @objc func handleMagnificationGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        let magnification = Float32(gestureRecognizer.magnification) * sensitivity
        let scaleFactor = 1.0 + magnification
        let newScale = currentScale * scaleFactor
        
        let newScaleClamped = min(max(newScale, minValue), maxValue)
         
        currentScale = newScaleClamped
        
        sceneData.cameraDistance = ((currentScale - minValue) / (maxValue - minValue)) * (sceneData.minCameraDistance - sceneData.maxCameraDistance) + sceneData.maxCameraDistance
    }
}
