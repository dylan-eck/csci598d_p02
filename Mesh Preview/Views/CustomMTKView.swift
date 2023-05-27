import MetalKit

protocol CustomMTKViewDelegate: AnyObject {
    func handleTouches(_ view: CustomMTKView, touches: Set<NSTouch>)
}

class CustomMTKView: MTKView {
    weak var touchesDelegate: CustomMTKViewDelegate?

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func handleTouches(_ event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        touchesDelegate?.handleTouches(self, touches: touches)
    }
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        handleTouches(event)
    }
    
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        handleTouches(event)
    }
    
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        handleTouches(event)
    }
    
    override func touchesCancelled(with event: NSEvent) {
        super.touchesCancelled(with: event)
        handleTouches(event)
    }
}
