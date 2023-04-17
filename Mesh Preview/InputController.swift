//
//  InputController.swift
//  CSCI598D_P02_ECK
//
//  Created by Dylan Eck on 4/16/23.
//

import GameController

class InputController {
    static let controller = InputController()
    
    var keysPressed: Set<GCKeyCode> = []
    var mousePressed: Bool = false
    var mouseDelta: Vec2 = Vec2(0, 0)
    
    init() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: nil
        ) { notification in
                guard
                    let keyboard = notification.object as? GCKeyboard,
                    let input = keyboard.keyboardInput
                else {
                    return
                }
                
                input.keyChangedHandler = { _, _, keyCode, pressed in
                    if pressed {
                        self.keysPressed.insert(keyCode)
                    } else {
                        self.keysPressed.remove(keyCode)
                    }
                }
                
        }
        
        notificationCenter.addObserver(
            forName: .GCMouseDidConnect,
            object: nil,
            queue: nil
        ) { notification in
            guard
                let mouse = notification.object as? GCMouse,
                let input = mouse.mouseInput
            else {
                return
            }
            
            input.leftButton.pressedChangedHandler = { _, _, pressed in
                self.mousePressed = pressed
            }
            
            input.mouseMovedHandler = { _, deltaX, deltaY in
                self.mouseDelta = Vec2(deltaX, deltaY)
            }
            
            
        }
    }
}

