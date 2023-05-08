import SwiftUI

struct CameraSettingsView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        DisclosureGroup(
            content: {
                Button(action: {viewModel.sceneData.toggleProjection()}) {
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
