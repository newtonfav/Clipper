import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var pro
    @Environment(ClipStore.self) private var store
    @State private var showPaywall = false
    @AppStorage(AppGroup.DefaultsKey.autoReturnAfterInsert, store: AppGroup.defaults)
    private var autoReturnAfterInsert = true
    @AppStorage(AppGroup.DefaultsKey.captureOnKeyboardOpen, store: AppGroup.defaults)
    private var captureOnKeyboardOpen = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if pro.isPro {
                        Label("Clipper Pro is unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Clipper Pro", systemImage: "sparkles")
                        }
                        Button("Restore Purchases") {
                            Task { await pro.restore() }
                        }
                    }
                } header: {
                    Text("Clipper Pro")
                } footer: {
                    Text(pro.isPro
                         ? "Unlimited pins, \(Limits.pro.maxHistory) recent copies, insert variants and quick actions."
                         : "Unlimited pins, \(Limits.pro.maxHistory) recent copies, insert variants and quick actions. One-time purchase.")
                }

                Section {
                    Toggle("Switch back after inserting", isOn: $autoReturnAfterInsert)
                    Toggle("Capture clipboard while keyboard is open", isOn: $captureOnKeyboardOpen)
                } header: {
                    Text("Keyboard")
                } footer: {
                    Text("Switching back goes to the next keyboard in your list, so keep Clipper last. Capturing from the keyboard needs Allow Full Access.")
                }

                Section("Setup") {
                    NavigationLink("Setup guide") {
                        OnboardingView(onDone: nil)
                    }
                    NavigationLink("Privacy") {
                        PrivacyNoteView()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Self.version)
                    LabeledContent("Recent limit", value: "\(store.limits.maxHistory) clips")
                    LabeledContent("Pin limit", value: store.limits.maxPins.map { "\($0) clips" } ?? "Unlimited")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
        }
    }

    private static var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
