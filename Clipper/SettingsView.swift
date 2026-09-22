import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppGroup.DefaultsKey.autoReturnAfterInsert, store: AppGroup.defaults)
    private var autoReturnAfterInsert = true
    @AppStorage(AppGroup.DefaultsKey.captureOnKeyboardOpen, store: AppGroup.defaults)
    private var captureOnKeyboardOpen = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Switch back after inserting", isOn: $autoReturnAfterInsert)
                    Toggle("Capture clipboard when keyboard opens", isOn: $captureOnKeyboardOpen)
                } header: {
                    Text("Keyboard")
                } footer: {
                    Text("Switching back goes to the next keyboard in your list, so keep Clipper last. Capture on open needs Allow Full Access.")
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
                    LabeledContent("History limit", value: "\(ClipStore.maxHistory) clips")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private static var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
