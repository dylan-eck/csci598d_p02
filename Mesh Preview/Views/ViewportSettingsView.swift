import SwiftUI

struct ViewportSettingsView: View {
    var body: some View {
        DisclosureGroup(
            content: {
               
            },
            label: {
                HStack(spacing: 4) {
                    Image(systemName: "display")
                        .foregroundColor(.secondary)
                    Text("Viewport Settings")
                        .foregroundColor(.primary)
                }
            }
        )
            .bold()
    }
}
