import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 42))
                .foregroundStyle(.tint)

            Text("Materials Intelligence")
                .font(.title)

            Text("Project foundation")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 520, minHeight: 320)
        .padding()
    }
}
