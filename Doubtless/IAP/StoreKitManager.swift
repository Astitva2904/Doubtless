import Foundation
import StoreKit

/// Manages all StoreKit 2 interactions for Doubtless IAP.
/// Handles product fetching, purchasing, and transaction observation.
@MainActor
final class StoreKitManager {

    static let shared = StoreKitManager()

    // MARK: - Product IDs
    static let creds100 = "com.srmist.doubtless.creds.100"
    static let creds300 = "com.srmist.doubtless.creds.300"
    static let creds600 = "com.srmist.doubtless.creds.600"
    
    private let productIds: Set<String> = [
        StoreKitManager.creds100, 
        StoreKitManager.creds300, 
        StoreKitManager.creds600
    ]

    // MARK: - State
    private(set) var products: [Product] = []
    private(set) var purchaseInProgress = false

    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Error>?

    // MARK: - Init
    private init() {
        transactionListener = listenForTransactions()
        Task { await fetchProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Fetch Products
    /// Fetches the available IAP products from the App Store.
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("❌ StoreKit: Failed to fetch products: \(error)")
        }
    }

    // MARK: - Purchase
    /// Initiates a purchase for the given product.
    /// Returns `true` if purchase succeeded and credits were granted.
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Grant credits
            try await handleVerifiedTransaction(transaction)
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            // e.g. Ask to Buy — transaction will complete later
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Transaction Listener
    /// Listens for transactions that complete outside the purchase flow
    /// (e.g., Ask to Buy approvals, subscription renewals from other devices).
    @MainActor
    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    try await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("❌ StoreKit: Unverified transaction: \(error)")
                }
            }
        }
    }

    // MARK: - Verification
    /// Checks that a transaction is verified by StoreKit (signed by Apple).
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Fulfillment
    /// After a verified purchase, grant credits to the user's balance.
    private func handleVerifiedTransaction(_ transaction: Transaction) async throws {
        // Only process if not revoked
        guard transaction.revocationDate == nil else { return }
        
        let credsToGrant: Int
        switch transaction.productID {
        case StoreKitManager.creds100: credsToGrant = 100
        case StoreKitManager.creds300: credsToGrant = 300
        case StoreKitManager.creds600: credsToGrant = 600
        default: return
        }

        try await CreditsManager.shared.addPurchasedCredits(
            amount: credsToGrant,
            transactionId: String(transaction.id)
        )
        // Post notification so any visible UI updates
        NotificationCenter.default.post(name: .creditsDidUpdate, object: nil)
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let creditsDidUpdate = Notification.Name("creditsDidUpdate")
}
