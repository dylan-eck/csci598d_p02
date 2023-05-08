import SwiftUI

struct MeshInfoView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading) {
                    HStack {
                        Text("File Size:")

                        Spacer()

                        if let size = viewModel.modelFileSize {
                            Text(formattedFileSize(fromBytes: size))
                        }
                    }

                    Text("vertex count")
                    Text("triangle count")
                }
            },
            label: {
                HStack(spacing: 4) {
                    Image(systemName: "cube.transparent")
                        .foregroundColor(.secondary)
                    Text("Model Info")
                        .foregroundColor(.primary)
                }
            }
        )
            .bold()
    }
}

