import SwiftUI
import MetalKit

func formattedFileSize(fromBytes bytes: Int) -> String {
    let byteCountFormatter = ByteCountFormatter()
    byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
    byteCountFormatter.countStyle = .file
    return byteCountFormatter.string(fromByteCount: Int64(bytes))
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            List {
                MeshInfoView()
                DisplayOptionsView()
                CameraSettingsView()

                Picker("Vertex Colors", selection: $viewModel.vertexColors) {
                    ForEach(viewModel.vertexColoringOptions) { option in
                        Text(option.name).tag(option.id)
                    }
                }
            }
                .frame(maxHeight: .infinity)
                .backgroundStyle(.opacity(0))
                .toolbar {
                    ToolbarItem {
                        Button(action: toggleSidebar) {
                            Label("toggle sidebar visibility", systemImage: "sidebar.left")
                                .imageScale(.large)
                        }
                    }
                }

            GeometryReader { geometry in
                 Viewport3DView()
                    .ignoresSafeArea()
                    .onAppear {
                        if let color = NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB) {
                            viewModel.backgroundColor = Vec3(
                                Float32(color.redComponent),
                                Float32(color.greenComponent),
                                Float32(color.blueComponent)
                            )
                        }
                    }
                    .onChange(of: colorScheme) { _ in
                        if let color = NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB) {
                            viewModel.backgroundColor = Vec3(
                                Float32(color.redComponent),
                                Float32(color.greenComponent),
                                Float32(color.blueComponent)
                            )
                        }
                    }
            }
        }
            .frame(idealWidth: 400)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
