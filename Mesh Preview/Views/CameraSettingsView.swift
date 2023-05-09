import SwiftUI

struct CameraSettingsView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
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
