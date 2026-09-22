import SwiftUI

struct PrivacyNoteView: View {
    var body: some View {
        List {
            Section {
                Label("Clips are stored in a private container on this device that only Clipper, its keyboard and its share extension can read.", systemImage: "internaldrive")
                Label("There is no network access, no account, no iCloud sync and no analytics.", systemImage: "network.slash")
                Label("Allow Full Access is required by iOS for any keyboard that reads the clipboard or writes to shared storage. Clipper uses it for nothing else.", systemImage: "lock.shield")
                Label("Deleting a clip removes it immediately. Deleting the app removes everything.", systemImage: "trash")
            }
            .font(.subheadline)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
