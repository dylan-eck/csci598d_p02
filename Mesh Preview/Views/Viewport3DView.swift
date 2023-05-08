import Foundation

import SwiftUI
import MetalKit

struct Viewport3DView: NSViewRepresentable {
    @EnvironmentObject var sceneData: SceneData

    func makeCoordinator() -> Renderer {
        Renderer(self, sceneData)
    }
    
    func makeNSView(context: NSViewRepresentableContext<Viewport3DView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.depthStencilPixelFormat = .depth32Float
        
        if let device = MTLCreateSystemDefaultDevice() {
            mtkView.device = device
        }
        
        let panGestureRecognizer = NSPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePanGesture(_:))
        )
        mtkView.addGestureRecognizer(panGestureRecognizer)

        let magnificationGestureRecognizer = NSMagnificationGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleMagnificationGesture(_:))
        )
        mtkView.addGestureRecognizer(magnificationGestureRecognizer)

        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<Viewport3DView>) {
        
    }
}

struct Viewport3DView_Previews: PreviewProvider {
    static var previews: some View {
        Viewport3DView()
    }
}

