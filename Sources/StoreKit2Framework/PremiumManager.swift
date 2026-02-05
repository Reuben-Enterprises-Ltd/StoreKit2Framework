#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

@MainActor
@Observable
public final class PremiumManager {
    // MARK: - Product Identifiers
    
    /// Define your product IDs here
    public enum ProductIdentifiers {
        public static let monthly = "com.yourcompany.yourapp.monthly"
        public static let yearly = "com.yourcompany.yourapp.yearly"
        public static let lifetime = "com.yourcompany.yourapp.lifetime"
        
        public static var all: [String] {
            [monthly, yearly, lifetime]
        }
    }
    
    // MARK: - Singleton
    
    public static let shared = PremiumManager()
    
    // MARK: - Public State (Observable)
    
    /// Whether the user has premium access (reactive)
    public private(set) var isPremium = false
    
    /// Available products from the App Store
    public private(set) var products: [Product] = []
    
    /// Loading state
    public private(set) var isLoading = false
    
    /// Error state
    public private(set) var error: Error?
    
    // MARK: - Private State
    
    /// Active subscription or lifetime purchase
    public private(set) var activeEntitlement: Product.SubscriptionInfo.Status?
    
    /// Transaction update task
    private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?
    
    /// Key for caching premium status
    private let cachedPremiumStatusKey = "cachedPremiumStatus"
    
    /// Whether initialization has started
    private var hasStartedInitialization = false
    
    /// Whether premium status has been updated this launch
    private var hasUpdatedStatusThisLaunch = false
    
    // MARK: - Debug Override (Optional)
    
    /// Scheme flag for testing premium without IAP (DEBUG only)
    #if DEBUG
    private let premiumOverride: Bool = {
        ProcessInfo.processInfo.environment["PREMIUM_ENABLED"] == "1"
    }()
    #else
    private let premiumOverride = false
    #endif
    
    // MARK: - Cached Premium Status
    
    private var cachedPremiumStatus: Bool {
        get { UserDefaults.standard.bool(forKey: cachedPremiumStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: cachedPremiumStatusKey) }
    }
    
    // MARK: - Initialization
    
    private nonisolated init() {
        // Deferred to startInitialization() which must run on MainActor
    }
    
    /// Start initialization - call this early in app lifecycle
    private func startInitialization() {
        guard !hasStartedInitialization else { return }
        hasStartedInitialization = true
        
        // Load cached status immediately for instant UI
        isPremium = cachedPremiumStatus || premiumOverride
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and verify status asynchronously
        Task {
            await loadProducts()
            await updatePremiumStatusIfNeeded()
        }
    }
    
    /// Public method to ensure initialization
    public func ensureInitialized() {
        startInitialization()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from the App Store
    public func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let loadedProducts = try await Product.products(for: ProductIdentifiers.all)
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    /// Purchase a product
    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Update premium status
            await updatePremiumStatus()
            
            // Finish the transaction
            await transaction.finish()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
        } catch {
            self.error = error
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Premium Status Management
    
    /// Update premium status if not done this launch
    private func updatePremiumStatusIfNeeded() async {
        guard !hasUpdatedStatusThisLaunch else { return }
        hasUpdatedStatusThisLaunch = true
        await updatePremiumStatus()
    }
    
    /// Update premium status based on entitlements
    public func updatePremiumStatus() async {
        var hasActiveEntitlement = false
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check for lifetime purchase
                if transaction.productID == ProductIdentifiers.lifetime {
                    hasActiveEntitlement = true
                    break
                }
                
                // Check for active subscription
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {
                    let status = try await subscription.status.first
                    
                    // Check if subscription is active (including non-renewing but still valid)
                    if case .verified = status?.renewalInfo,
                       case .verified = status?.transaction,
                       case .subscribed = status?.state {
                        hasActiveEntitlement = true
                        activeEntitlement = status
                        break
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        // Update status and cache
        let newStatus = hasActiveEntitlement || premiumOverride
        cachedPremiumStatus = newStatus
        isPremium = newStatus
    }
    
    // MARK: - Real-time Transaction Monitoring
    
    /// Listen for transaction updates in the background
    private func listenForTransactions() -> Task<Void, Never> {
        Task { @MainActor [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePremiumStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    /// Verify a transaction is legitimate
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

// MARK: - Errors

public enum StoreError: Error, LocalizedError {
    case failedVerification
    
    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
#endif
