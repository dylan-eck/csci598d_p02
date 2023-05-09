import SwiftUI

struct MeshInfoView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var isExpanded = true
    
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
                    
                    HStack {
                        Text("Vertex Count:")

                        Spacer()

                        if let verts = viewModel.numVertices {
                            Text(String(verts))
                        }
                    }
                    
                    HStack {
                        Text("Triangle Count:")

                        Spacer()

                        if let tris = viewModel.numTriangles {
                            Text(String(tris))
                        }
                    }
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

