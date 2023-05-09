import SwiftUI

struct DisplayOptionsView: View {
    @EnvironmentObject var viewModel: ViewModel

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Picker("Vertex Colors", selection: $viewModel.vertexColors) {
                    ForEach(viewModel.vertexColoringOptions) { option in
                        Text(option.name).tag(option.id)
                    }
                }
            },
            label: {
                HStack(spacing: 4) {
                    Image(systemName: "display")
                        .foregroundColor(.secondary)
                    Text("Display Options")
                        .foregroundColor(.primary)
                }
            }
        )
            .bold()
    }
}
