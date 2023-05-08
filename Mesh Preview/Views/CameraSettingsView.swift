import SwiftUI

struct CameraSettingsView: View {
    @EnvironmentObject var sceneData: SceneData
    
    var body: some View {
        DisclosureGroup(
            content: {
                Button(action: {sceneData.toggleProjection()}) {
                    Text("toggle projection")
                }
            },
            label: {
                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .foregroundColor(.secondary)
                    Text("Camera Settings")
                        .foregroundColor(.primary)
                }
            }
        )
            .bold()
    }
}
