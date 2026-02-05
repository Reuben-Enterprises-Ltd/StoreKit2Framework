#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

@MainActor
@Observable
public final class PremiumManager {
    // MARK: - Configuration Types
    
    /// Product identifiers for In-App Purchases
    public struct ProductIdentifiers {
        /// Monthly subscription product ID
        public var monthly: String
        
        /// Yearly subscription product ID
        public var yearly: String
        
        /// Optional lifetime (non-renewing) subscription product ID
        public var lifetime: String?
        
        /// All product IDs (excludes nil lifetime)
        public var all: [String] {
            [monthly, yearly, lifetime].compactMap { $0 }
        }
        
        /// Default product identifiers
        public static var `default`: ProductIdentifiers {
            ProductIdentifiers(
                monthly: "com.yourcompany.yourapp.monthly",
                yearly: "com.yourcompany.yourapp.yearly",
                lifetime: "com.yourcompany.yourapp.lifetime"
            )
        }
        
        /// Initialize with custom product IDs
        public init(monthly: String, yearly: String, lifetime: String? = nil) {
            self.monthly = monthly
            self.yearly = yearly
            self.lifetime = lifetime
        }
    }
    
    /// A displayable benefit/feature shown in the paywall
    public struct Feature {
        /// The user-facing title of the feature (e.g., "Cloud Sync")
        public let title: String
        /// The SF Symbol name used to represent the feature visually
        public let systemImageName: String
        
        /// Public initializer so apps can provide custom features in configuration
        public init(title: String, systemImageName: String) {
            self.title = title
            self.systemImageName = systemImageName
        }
    }
    
    /// Configuration for the PremiumManager
    public struct Configuration {
        /// Product identifiers to use
        public var productIdentifiers: ProductIdentifiers
        
        /// List of features/benefits for display in paywall
        public var features: [PremiumManager.Feature]
        
        /// Enable debug mode (verbose logging, etc.)
        public var enableDebugMode: Bool
        
        /// Key for caching premium status in UserDefaults
        public var cacheKey: String
        
        // MARK: - Advanced Features (Optional)
        
        /// Analytics delegate for tracking premium events (opt-in)
        public var analytics: (any PremiumAnalytics)?
        
        /// Offline grace period in seconds (default: 24 hours)
        /// Premium features remain accessible offline for this duration after last verification
        public var offlineGracePeriod: TimeInterval
        
        /// Enable promotional offers support (default: false)
        public var enablePromotionalOffers: Bool
        
        /// Default configuration
        public static var `default`: Configuration {
            Configuration(
                productIdentifiers: .default,
                features: [
                    .init(title: "Advanced Analytics", systemImageName: ""),
                    .init(title: "Cloud Sync", systemImageName: ""),
                    .init(title: "Premium Themes", systemImageName: ""),
                    .init(title: "Priority Support", systemImageName: ""),
                ],
                enableDebugMode: false,
                cacheKey: "premium_status",
                analytics: nil,
                offlineGracePeriod: 86400, // 24 hours
                enablePromotionalOffers: false
            )
        }
        
        /// Debug configuration preset
        public static var debug: Configuration {
            var config = Configuration.default
            config.enableDebugMode = true
            return config
        }
        
        /// Production configuration preset
        public static var production: Configuration {
            var config = Configuration.default
            config.enableDebugMode = false
            return config
        }
        
        /// Initialize with custom configuration
        public init(
            productIdentifiers: ProductIdentifiers = .default,
            features: [PremiumManager.Feature] = [],
            enableDebugMode: Bool = false,
            cacheKey: String = "premium_status",
            analytics: (any PremiumAnalytics)? = nil,
            offlineGracePeriod: TimeInterval = 86400,
            enablePromotionalOffers: Bool = false
        ) {
            self.productIdentifiers = productIdentifiers
            self.features = features
            self.enableDebugMode = enableDebugMode
            self.cacheKey = cacheKey
            self.analytics = analytics
            self.offlineGracePeriod = offlineGracePeriod
            self.enablePromotionalOffers = enablePromotionalOffers
        }
        
        /// Validate the configuration
        public func validate() throws {
            // Check monthly product ID
            guard !productIdentifiers.monthly.isEmpty else {
                throw ConfigurationError.emptyProductID(field: "monthly")
            }
            
            guard productIdentifiers.monthly.contains(".") else {
                throw ConfigurationError.invalidProductIDFormat(id: productIdentifiers.monthly)
            }
            
            // Check yearly product ID
            guard !productIdentifiers.yearly.isEmpty else {
                throw ConfigurationError.emptyProductID(field: "yearly")
            }
            
            guard productIdentifiers.yearly.contains(".") else {
                throw ConfigurationError.invalidProductIDFormat(id: productIdentifiers.yearly)
            }
            
            // Check lifetime product ID if provided
            if let lifetime = productIdentifiers.lifetime {
                guard !lifetime.isEmpty else {
                    throw ConfigurationError.emptyProductID(field: "lifetime")
                }
                
                guard lifetime.contains(".") else {
                    throw ConfigurationError.invalidProductIDFormat(id: lifetime)
                }
            }
            
            // Check for duplicate product IDs
            let ids = productIdentifiers.all
            let uniqueIds = Set(ids)
            guard ids.count == uniqueIds.count else {
                throw ConfigurationError.duplicateProductIDs
            }
            
            // Warn if features list is empty (not an error, but worth noting)
            if features.isEmpty && enableDebugMode {
                print("⚠️ Configuration Warning: Features list is empty")
            }
            
            // Validate cache key
            guard !cacheKey.isEmpty else {
                throw ConfigurationError.emptyCacheKey
            }
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
    
    /// Active subscription or lifetime non-renewing subscription
    public private(set) var activeEntitlement: Product.SubscriptionInfo.Status?
    
    /// Transaction update task
    private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?
    
    /// Current configuration (immutable after initialization)
    private var configuration: Configuration = .default
    
    /// Whether configuration has been set
    private var isConfigured = false
    
    /// Key for caching premium status
    private var cachedPremiumStatusKey: String {
        configuration.cacheKey
    }
    
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
    
    /// Configure the PremiumManager with custom settings
    /// - Parameter config: The configuration to use
    /// - Important: Must be called before `ensureInitialized()` to take effect
    public func configure(_ config: Configuration) {
        guard !hasStartedInitialization else {
            if configuration.enableDebugMode {
                print("⚠️ PremiumManager Warning: configure() called after initialization. Configuration changes will not take effect.")
            }
            return
        }
        
        // Validate configuration
        do {
            try config.validate()
            configuration = config
            isConfigured = true
            
            if configuration.enableDebugMode {
                print("✅ PremiumManager configured with:")
                print("  - Products: \(configuration.productIdentifiers.all)")
                print("  - Features: \(configuration.features.count) features")
                print("  - Debug mode: \(configuration.enableDebugMode)")
                print("  - Analytics: \(configuration.analytics != nil ? "Enabled" : "Disabled")")
                print("  - Offline grace period: \(Int(configuration.offlineGracePeriod / 3600)) hours")
                print("  - Promotional offers: \(configuration.enablePromotionalOffers ? "Enabled" : "Disabled")")
            }
        } catch {
            // Log validation error but continue with current config
            print("❌ PremiumManager Configuration Error: \(error)")
            print("   Continuing with previous configuration")
        }
    }
    
    /// Access to current configuration (read-only)
    public var currentConfiguration: Configuration {
        configuration
    }
    
    // MARK: - Analytics
    
    /// Track paywall shown event
    /// - Parameter source: The source/context where paywall was shown (e.g., "onboarding", "settings", "feature_gate")
    public func trackPaywallShown(source: String = "unknown") {
        configuration.analytics?.trackPaywallShown(source: source)
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
            let productIds = configuration.productIdentifiers.all
            let loadedProducts = try await Product.products(for: productIds)
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
            
            if configuration.enableDebugMode {
                print("✅ Loaded \(products.count) products: \(products.map { $0.id })")
            }
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
            
            // Track successful purchase
            configuration.analytics?.trackPurchaseCompleted(product: product)
            
            // Finish the transaction
            await transaction.finish()
            
        case .userCancelled:
            // Track cancellation
            configuration.analytics?.trackPurchaseCancelled(product: product)
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
            // Track successful restoration
            configuration.analytics?.trackRestorePurchases(success: true)
        } catch {
            self.error = error
            // Track failed restoration
            configuration.analytics?.trackRestorePurchases(success: false)
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
                
                // Check for lifetime non-renewing subscription
                if let lifetimeId = configuration.productIdentifiers.lifetime,
                   transaction.productID == lifetimeId {
                    #if DEBUG
                    // In debug mode, lifetime expires after 10 minutes for testing
                    let debugExpirationInterval: TimeInterval = 10 * 60 // 10 minutes
                    let purchaseDate = transaction.purchaseDate
                    let expirationDate = purchaseDate.addingTimeInterval(debugExpirationInterval)
                    
                    if Date() < expirationDate {
                        hasActiveEntitlement = true
                        break
                    }
                    #else
                    // In production, lifetime never expires
                    hasActiveEntitlement = true
                    break
                    #endif
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

// MARK: - Configuration Errors

public enum ConfigurationError: Error, LocalizedError {
    case emptyProductID(field: String)
    case invalidProductIDFormat(id: String)
    case duplicateProductIDs
    case emptyCacheKey
    
    public var errorDescription: String? {
        switch self {
        case .emptyProductID(let field):
            return "Product ID for '\(field)' cannot be empty"
        case .invalidProductIDFormat(let id):
            return "Product ID '\(id)' does not follow Apple's format (should contain '.')"
        case .duplicateProductIDs:
            return "Product IDs must be unique"
        case .emptyCacheKey:
            return "Cache key cannot be empty"
        }
    }
}
#endif

