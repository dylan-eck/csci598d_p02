import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("\n### APP WILL TERMINATE ###\n")
        NotificationCenter.default.post(name: .appWillTerminate, object: nil)
    }
}

extension Notification.Name {
    static let appWillTerminate = Notification.Name("appWillTerminate")
}

