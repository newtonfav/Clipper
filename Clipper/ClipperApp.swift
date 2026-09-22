import SwiftUI

@main
struct ClipperApp: App {
    @State private var store = ClipStore()
    @State private var pro = ProStore()
    @State private var observation: DarwinObservation?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(pro)
                .onChange(of: pro.isPro) { _, _ in
                    store.refreshLimits()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    store.reload()
                    // Don't trigger the system paste prompt underneath first-run onboarding.
                    if AppSettings.hasSeenOnboarding {
                        ClipboardCapture.captureIfNeeded(into: store)
                    }
                }
                .task {
                    let store = store
                    observation = DarwinNotifier.observe(AppGroup.storeDidChangeNotification) {
                        store.reload()
                    }
                }
        }
    }
}
