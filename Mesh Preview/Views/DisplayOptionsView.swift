import SwiftUI

struct DisplayOptionsView: View {
    var body: some View {
        DisclosureGroup(
            content: {
               
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
