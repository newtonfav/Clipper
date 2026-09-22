import SwiftUI

struct ProPaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let features: [(symbol: String, title: String, detail: String)] = [
        ("pin.fill", "Unlimited pins", "Keep every address, link and snippet you reuse. Free keeps \(Limits.free.maxPins ?? 0)."),
        ("clock.arrow.circlepath", "\(Limits.pro.maxHistory) recent copies", "Five times the history, so nothing slips away."),
        ("textformat", "Insert variants", "Long-press a clip to insert it in UPPERCASE or lowercase."),
        ("arrow.up.right.square", "Quick actions", "Open links, start emails and place calls straight from a clip."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor)
                        Text("Clipper Pro")
                            .font(.largeTitle.bold())
                        Text("One purchase. Yours for good.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(features, id: \.title) { feature in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: feature.symbol)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title).font(.headline)
                                    Text(feature.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    VStack(spacing: 12) {
                        if pro.isPro {
                            Label("You have Clipper Pro", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                        } else {
                            Button {
                                Task { await pro.purchase() }
                            } label: {
                                Group {
                                    if pro.isBusy {
                                        ProgressView()
                                    } else if pro.product == nil {
                                        Text("Loading price…")
                                    } else {
                                        Text("Unlock for \(pro.displayPrice)")
                                    }
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(pro.isBusy || pro.product == nil)

                            Button("Restore Purchases") {
                                Task { await pro.restore() }
                            }
                            .font(.subheadline)
                            .disabled(pro.isBusy)
                        }

                        if let message = pro.errorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Text("Family Sharing supported. No subscription, no account.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro {
                Task {
                    try? await Task.sleep(for: .seconds(0.8))
                    dismiss()
                }
            }
        }
    }
}
