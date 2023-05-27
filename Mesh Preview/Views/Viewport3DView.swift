import SwiftUI
import MetalKit

struct Viewport3DView: NSViewRepresentable {
    @EnvironmentObject var viewModel: ViewModel

    func makeCoordinator() -> Renderer {
        Renderer(self, viewModel)
    }
    
    func makeNSView(context: NSViewRepresentableContext<Viewport3DView>) -> MTKView {
        let mtkView = CustomMTKView()
        mtkView.delegate = context.coordinator
        mtkView.touchesDelegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.depthStencilPixelFormat = .depth32Float
        
        
        if let device = MTLCreateSystemDefaultDevice() {
            mtkView.device = device
        }

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

