import Observation
import SwiftUI

@MainActor
@Observable
final class ShareModel {
    var text = ""
    var isLoading = true

    func finishLoading(_ value: String?) {
        text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isLoading = false
    }
}

struct ShareSheetView: View {
    @Bindable var model: ShareModel
    let onSave: (_ pin: Bool) -> Void
    let onCancel: () -> Void

    private var canSave: Bool {
        !model.isLoading && !model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if model.isLoading {
                        HStack {
                            ProgressView()
                            Text("Reading shared content…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        TextEditor(text: $model.text)
                            .frame(minHeight: 120, maxHeight: 240)
                            .font(.body)
                    }
                } header: {
                    Text("Clip")
                } footer: {
                    if !model.isLoading {
                        Label(ClipKindDetector.detect(model.text).label, systemImage: ClipKindDetector.detect(model.text).symbolName)
                    }
                }

                Section {
                    Button {
                        onSave(false)
                    } label: {
                        Label("Save to Recent", systemImage: "clock")
                    }
                    Button {
                        onSave(true)
                    } label: {
                        Label("Save and Pin", systemImage: "pin")
                    }
                }
                .disabled(!canSave)
            }
            .navigationTitle("Save to Clipper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}
