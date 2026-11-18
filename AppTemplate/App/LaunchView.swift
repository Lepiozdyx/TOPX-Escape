import SwiftUI

struct LaunchView: View {
    let launch: LaunchCoordinator

    var body: some View {
        switch launch.route {
        case .loading:
            LoadingView()
        case .native:
            NativeRootView()
                .environment(\.scenePhase, launch.scenePhase)
        case .web(let url):
            WebView(url: url)
        }
    }
}

private struct LoadingView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            if let icon = UIImage(named: "icon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250, maxHeight: 250)
                    .scaleEffect(isPulsing ? 0.7 : 1)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
            } else {
                ProgressView()
            }
        }
    }
}
