import Foundation
import Observation
import StoreKit

/// Owns the single non-consumable "Clipper Pro" product. Mirrors the entitlement into
/// the shared defaults so the keyboard and share extension see the same tier.
@MainActor
@Observable
final class ProStore {
    static let productID = "com.newtonfav.clip.pro"

    private(set) var product: Product?
    private(set) var isPro: Bool = Entitlements.isPro
    private(set) var isBusy = false
    private(set) var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in await self?.listenForTransactions() }
        Task { [weak self] in await self?.load() }
    }

    var displayPrice: String { product?.displayPrice ?? "" }

    func load() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            errorMessage = "Could not load the Pro product: \(error.localizedDescription)"
        }
        await refreshEntitlement()
    }

    func purchase() async {
        guard let product, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    setPro(true)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshEntitlement()
    }

    /// Asks StoreKit for the truth and caches it.
    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setPro(owned)
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
            await refreshEntitlement()
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        Entitlements.isPro = value
    }
}
