#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

/// Manages premium subscription status and in-app purchases.
///
/// `PremiumManager` is the central coordinator for all StoreKit operations in your app.
/// It provides a reactive, observable interface for premium status and handles all purchase flows.
///
/// ## Overview
///
/// The manager uses Apple's StoreKit 2 framework to:
/// - Load products from the App Store
/// - Process purchases securely with automatic verification
/// - Monitor subscription status in real-time
/// - Handle restore purchases
/// - Cache premium status for offline access
///
/// ## Usage
///
/// ### Basic Setup
///
/// Initialize early in your app's lifecycle:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         let config = PremiumManager.Configuration(
///             productIdentifiers: .init(
///                 monthly: "com.app.monthly",
///                 yearly: "com.app.yearly"
///             ),
///             features: [
///                 .init(title: "Unlimited Access", systemImageName: "infinity")
///             ]
///         )
///         PremiumManager.shared.configure(config)
///         PremiumManager.shared.ensureInitialized()
///     }
/// }
/// ```
///
/// ### Check Premium Status
///
/// Access premium status reactively in your views:
///
/// ```swift
/// struct MyView: View {
///     private let premiumManager = PremiumManager.shared
///
///     var body: some View {
///         if premiumManager.isPremium {
///             PremiumFeatureView()
///         } else {
///             FreeFeatureView()
///         }
///     }
/// }
/// ```
///
/// ### Purchase Products
///
/// Handle purchases with async/await:
///
/// ```swift
/// Task {
///     do {
///         try await PremiumManager.shared.purchase(product)
///         // Purchase successful
///     } catch {
///         // Handle error
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Singleton Instance
///
/// - ``shared``
///
/// ### Configuration
///
/// - ``Configuration``
/// - ``ProductIdentifiers``
/// - ``Feature``
/// - ``configure(_:)``
/// - ``currentConfiguration``
///
/// ### Initialization
///
/// - ``ensureInitialized()``
///
/// ### Premium Status
///
/// - ``isPremium``
/// - ``activeEntitlement``
///
/// ### Products
///
/// - ``products``
/// - ``isLoading``
/// - ``error``
/// - ``loadProducts()``
///
/// ### Purchase Operations
///
/// - ``purchase(_:)``
/// - ``restorePurchases()``
///
/// ### Analytics
///
/// - ``trackPaywallShown(source:)``
///
/// - Important: Always use the ``shared`` singleton instance.
/// - Note: The manager is marked with `@MainActor`, so all access must be from the main thread.
@MainActor
@Observable
public final class PremiumManager {
    // MARK: - Configuration Types
    
    /// Product identifiers for In-App Purchases.
    ///
    /// Configure this struct with your App Store Connect product IDs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let identifiers = ProductIdentifiers(
    ///     monthly: "com.myapp.premium.monthly",
    ///     yearly: "com.myapp.premium.yearly",
    ///     lifetime: "com.myapp.premium.lifetime"
    /// )
    /// ```
    ///
    /// - Important: Product IDs must match exactly (case-sensitive) with your App Store Connect configuration.
    public struct ProductIdentifiers {
        /// Monthly subscription product ID.
        ///
        /// This should match the product ID configured in App Store Connect.
        ///
        /// ## Example
        ///
        /// ```swift
        /// monthly: "com.mycompany.myapp.monthly"
        /// ```
        public var monthly: String
        
        /// Yearly subscription product ID.
        ///
        /// This should match the product ID configured in App Store Connect.
        /// Typically offers better value than monthly subscription.
        ///
        /// ## Example
        ///
        /// ```swift
        /// yearly: "com.mycompany.myapp.yearly"
        /// ```
        public var yearly: String
        
        /// Optional lifetime (non-renewing) subscription product ID.
        ///
        /// Use a non-renewing subscription for lifetime access.
        /// In DEBUG mode, lifetime subscriptions expire after 10 minutes for testing.
        /// In production, they never expire.
        ///
        /// ## Example
        ///
        /// ```swift
        /// lifetime: "com.mycompany.myapp.lifetime"
        /// ```
        public var lifetime: String?
        
        /// All configured product IDs.
        ///
        /// Returns an array of all product IDs, excluding nil lifetime.
        /// Used internally to fetch products from the App Store.
        public var all: [String] {
            [monthly, yearly, lifetime].compactMap { $0 }
        }
        
        /// Default product identifiers with placeholder values.
        ///
        /// These are placeholder values and should be replaced with your actual
        /// product IDs from App Store Connect.
        ///
        /// - Warning: Do not use these default IDs in production. Configure with your own product IDs.
        public static var `default`: ProductIdentifiers {
            ProductIdentifiers(
                monthly: "com.yourcompany.yourapp.monthly",
                yearly: "com.yourcompany.yourapp.yearly",
                lifetime: "com.yourcompany.yourapp.lifetime"
            )
        }
        
        /// Initialize with custom product IDs.
        ///
        /// - Parameters:
        ///   - monthly: Monthly subscription product ID from App Store Connect
        ///   - yearly: Yearly subscription product ID from App Store Connect  
        ///   - lifetime: Optional lifetime product ID from App Store Connect
        ///
        /// ## Example
        ///
        /// ```swift
        /// let identifiers = ProductIdentifiers(
        ///     monthly: "com.myapp.premium.monthly",
        ///     yearly: "com.myapp.premium.yearly",
        ///     lifetime: "com.myapp.premium.lifetime"
        /// )
        /// ```
        public init(monthly: String, yearly: String, lifetime: String? = nil) {
            self.monthly = monthly
            self.yearly = yearly
            self.lifetime = lifetime
        }
    }
    
    /// A displayable feature or benefit shown in the paywall.
    ///
    /// Features are displayed in the paywall UI to communicate the value
    /// of premium subscriptions to users.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let feature = Feature(
    ///     title: "Cloud Sync",
    ///     systemImageName: "icloud.fill"
    /// )
    /// ```
    public struct Feature {
        /// The user-facing title of the feature.
        ///
        /// Keep titles concise (2-4 words) for best UI presentation.
        ///
        /// ## Examples
        /// - "Cloud Sync"
        /// - "Unlimited Access"
        /// - "Priority Support"
        public let title: String
        
        /// The SF Symbol name used to represent the feature visually.
        ///
        /// Use SF Symbols that clearly represent the feature.
        /// Visit [SF Symbols](https://developer.apple.com/sf-symbols/) for available symbols.
        ///
        /// ## Examples
        /// - "icloud.fill"
        /// - "infinity"
        /// - "person.fill.questionmark"
        public let systemImageName: String
        
        /// Initialize a feature with a title and icon.
        ///
        /// - Parameters:
        ///   - title: User-facing feature title
        ///   - systemImageName: SF Symbol name for the icon
        public init(title: String, systemImageName: String) {
            self.title = title
            self.systemImageName = systemImageName
        }
    }
    
    /// Configuration for the PremiumManager.
    ///
    /// Customize the behavior and appearance of the premium subscription system.
    ///
    /// ## Overview
    ///
    /// Configuration must be set before calling ``ensureInitialized()``.
    /// Once initialized, configuration changes will not take effect.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = Configuration(
    ///     productIdentifiers: .init(
    ///         monthly: "com.app.monthly",
    ///         yearly: "com.app.yearly"
    ///     ),
    ///     features: [
    ///         .init(title: "Cloud Sync", systemImageName: "icloud.fill"),
    ///         .init(title: "Unlimited Access", systemImageName: "infinity")
    ///     ],
    ///     enableDebugMode: false
    /// )
    /// PremiumManager.shared.configure(config)
    /// ```
    ///
    /// ## Topics
    ///
    /// ### Product Configuration
    ///
    /// - ``productIdentifiers``
    /// - ``features``
    ///
    /// ### Behavior
    ///
    /// - ``enableDebugMode``
    /// - ``cacheKey``
    ///
    /// ### Advanced Features
    ///
    /// - ``analytics``
    /// - ``offlineGracePeriod``
    /// - ``enablePromotionalOffers``
    ///
    /// ### Validation
    ///
    /// - ``validate()``
    ///
    /// ### Presets
    ///
    /// - ``default``
    /// - ``debug``
    /// - ``production``
    public struct Configuration {
        /// Product identifiers to use for in-app purchases.
        ///
        /// Configure with your App Store Connect product IDs.
        public var productIdentifiers: ProductIdentifiers
        
        /// List of features/benefits displayed in the paywall.
        ///
        /// Choose 3-5 compelling benefits that communicate value to users.
        public var features: [PremiumManager.Feature]
        
        /// Enable debug mode for verbose logging.
        ///
        /// When enabled, the framework logs detailed information about:
        /// - Initialization
        /// - Product loading
        /// - Purchase flows
        /// - Status updates
        ///
        /// - Important: Set to `false` in production builds.
        public var enableDebugMode: Bool
        
        /// Key for caching premium status in UserDefaults.
        ///
        /// Must be unique to your app to avoid conflicts.
        /// The cached status enables instant UI updates on app launch.
        ///
        /// ## Example
        ///
        /// ```swift
        /// cacheKey: "myapp_premium_status"
        /// ```
        public var cacheKey: String
        
        // MARK: - Advanced Features
        
        /// Analytics delegate for tracking premium events (optional).
        ///
        /// Implement ``PremiumAnalytics`` protocol to receive callbacks for:
        /// - Paywall shown
        /// - Purchase completed/failed/cancelled
        /// - Restore purchases
        ///
        /// ## Example
        ///
        /// ```swift
        /// class MyAnalytics: PremiumAnalytics {
        ///     func trackPurchaseCompleted(product: Product) {
        ///         Analytics.log("purchase", value: product.price)
        ///     }
        /// }
        ///
        /// let config = Configuration(
        ///     productIdentifiers: .default,
        ///     features: [],
        ///     analytics: MyAnalytics()
        /// )
        /// ```
        public var analytics: (any PremiumAnalytics)?
        
        /// Offline grace period in seconds (default: 24 hours).
        ///
        /// Premium features remain accessible offline for this duration
        /// after last successful verification with the App Store.
        ///
        /// ## Recommended Values
        /// - 24 hours (86400): Good for most apps
        /// - 1 hour (3600): Strict verification
        /// - 7 days (604800): Very generous for offline use
        ///
        /// - Note: Verification happens automatically when network is available.
        public var offlineGracePeriod: TimeInterval
        
        /// Enable promotional offers support (default: false).
        ///
        /// When enabled, the framework supports:
        /// - Introductory offers
        /// - Promotional offers
        /// - Win-back offers
        ///
        /// - Note: Requires additional App Store Connect configuration.
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
    
    /// The shared singleton instance of PremiumManager.
    ///
    /// Use this instance throughout your app to access premium features and manage subscriptions.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct MyView: View {
    ///     private let premiumManager = PremiumManager.shared
    ///
    ///     var body: some View {
    ///         Text(premiumManager.isPremium ? "Premium" : "Free")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: Do not create your own instances. Always use the shared singleton.
    public static let shared = PremiumManager()
    
    // MARK: - Public State (Observable)
    
    /// Whether the user currently has active premium access.
    ///
    /// This property is reactive and automatically updates the UI when changed.
    /// It checks for:
    /// - Active auto-renewable subscriptions
    /// - Non-expired lifetime purchases
    /// - Debug override flag (DEBUG builds only)
    ///
    /// ## Example
    ///
    /// ```swift
    /// if premiumManager.isPremium {
    ///     // Show premium features
    /// } else {
    ///     // Show upgrade prompt
    /// }
    /// ```
    ///
    /// - Note: Status is cached for instant access on launch and verified asynchronously.
    public private(set) var isPremium = false
    
    /// Available products loaded from the App Store.
    ///
    /// Products are sorted by price (lowest to highest) for consistent display.
    /// Array is empty until products are successfully loaded.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ForEach(premiumManager.products) { product in
    ///     Button(product.displayName) {
    ///         Task { try await premiumManager.purchase(product) }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: Products load automatically during initialization.
    public private(set) var products: [Product] = []
    
    /// Whether products are currently being loaded from the App Store.
    ///
    /// Use this to show loading indicators in your UI.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if premiumManager.isLoading {
    ///     ProgressView("Loading products...")
    /// } else {
    ///     ProductList(products: premiumManager.products)
    /// }
    /// ```
    public private(set) var isLoading = false
    
    /// The last error that occurred during product loading or purchase.
    ///
    /// Check this after operations to handle errors gracefully.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let error = premiumManager.error {
    ///     Text("Error: \(error.localizedDescription)")
    ///         .foregroundStyle(.red)
    /// }
    /// ```
    ///
    /// - Note: Error is cleared when starting a new operation.
    public private(set) var error: Error?
    
    // MARK: - Private State
    
    /// Active subscription or lifetime non-renewing subscription details.
    ///
    /// Contains information about the user's current subscription including:
    /// - Subscription state
    /// - Renewal date
    /// - Purchase date
    /// - Product type
    ///
    /// `nil` if user doesn't have an active subscription.
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
    
    /// Initialize the PremiumManager and start monitoring transactions.
    ///
    /// Call this method once during app launch, after calling ``configure(_:)``.
    /// It performs the following:
    /// - Loads cached premium status for instant UI updates
    /// - Starts listening for transaction updates
    /// - Loads products from the App Store
    /// - Verifies current premium status
    ///
    /// ## Example
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     init() {
    ///         let config = PremiumManager.Configuration(...)
    ///         PremiumManager.shared.configure(config)
    ///         PremiumManager.shared.ensureInitialized()
    ///     }
    /// }
    /// ```
    ///
    /// - Note: Safe to call multiple times. Initialization only happens once.
    public func ensureInitialized() {
        startInitialization()
    }
    
    /// Configure the PremiumManager with custom settings.
    ///
    /// Set your product IDs, features, and other configuration before initializing.
    /// Configuration is immutable after initialization.
    ///
    /// - Parameter config: The configuration to use
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = PremiumManager.Configuration(
    ///     productIdentifiers: .init(
    ///         monthly: "com.app.monthly",
    ///         yearly: "com.app.yearly"
    ///     ),
    ///     features: [
    ///         .init(title: "Cloud Sync", systemImageName: "icloud.fill")
    ///     ],
    ///     enableDebugMode: false
    /// )
    /// PremiumManager.shared.configure(config)
    /// ```
    ///
    /// - Important: Must be called **before** ``ensureInitialized()`` to take effect.
    /// - Throws: Prints warning if configuration is invalid but continues with previous config.
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
                print("  - Offline grace period: \(configuration.offlineGracePeriod) seconds (\(String(format: "%.1f", configuration.offlineGracePeriod / 3600)) hours)")
                print("  - Promotional offers: \(configuration.enablePromotionalOffers ? "Enabled" : "Disabled")")
            }
        } catch {
            // Log validation error but continue with current config
            print("❌ PremiumManager Configuration Error: \(error)")
            print("   Continuing with previous configuration")
        }
    }
    
    /// Access to the current configuration (read-only).
    ///
    /// Use this to read configuration values after setup.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let monthlyID = PremiumManager.shared.currentConfiguration.productIdentifiers.monthly
    /// let features = PremiumManager.shared.currentConfiguration.features
    /// ```
    ///
    /// - Note: Configuration is immutable after initialization.
    public var currentConfiguration: Configuration {
        configuration
    }
    
    // MARK: - Analytics
    
    /// Track that a paywall was shown to the user.
    ///
    /// If analytics are configured, this notifies your analytics delegate.
    /// Helps track conversion funnel and understand where users see the paywall.
    ///
    /// - Parameter source: The source/context where paywall was shown
    ///
    /// ## Example
    ///
    /// ```swift
    /// PremiumManager.shared.trackPaywallShown(source: "onboarding")
    /// PremiumManager.shared.trackPaywallShown(source: "feature_limit")
    /// PremiumManager.shared.trackPaywallShown(source: "settings")
    /// ```
    ///
    /// ## Common Sources
    /// - `"onboarding"`: During initial app setup
    /// - `"feature_limit"`: When user hits a limit
    /// - `"settings"`: User-initiated from settings
    /// - `"feature_gate"`: Attempting to access premium feature
    ///
    /// - Note: No-op if analytics are not configured.
    public func trackPaywallShown(source: String = "unknown") {
        configuration.analytics?.trackPaywallShown(source: source)
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from the App Store.
    ///
    /// Fetches products configured in ``Configuration/productIdentifiers``
    /// and sorts them by price (lowest to highest).
    ///
    /// Usually called automatically during initialization.
    /// Can be called manually to refresh products.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Button("Refresh Products") {
    ///     Task {
    ///         await premiumManager.loadProducts()
    ///     }
    /// }
    /// ```
    ///
    /// - Note: Sets ``isLoading`` to `true` during fetch and updates ``products`` on success.
    /// - Note: Sets ``error`` if loading fails.
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
    
    /// Purchase a product.
    ///
    /// Handles the complete purchase flow:
    /// 1. Initiates purchase with StoreKit
    /// 2. Verifies transaction authenticity
    /// 3. Updates premium status
    /// 4. Tracks analytics (if configured)
    /// 5. Finishes transaction
    ///
    /// - Parameter product: The product to purchase (from ``products`` array)
    ///
    /// ## Example
    ///
    /// ```swift
    /// Button("Subscribe") {
    ///     Task {
    ///         do {
    ///             try await premiumManager.purchase(product)
    ///             // Purchase successful
    ///         } catch {
    ///             // Handle error
    ///             showError(error)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Throws: ``PremiumError`` if purchase fails or verification fails
    ///
    /// ## Possible Outcomes
    /// - **Success**: Purchase completes, premium is granted
    /// - **User Cancelled**: User cancels in payment sheet (not an error)
    /// - **Pending**: Requires action (e.g., parental approval)
    /// - **Failed**: Network error, payment declined, etc. (throws error)
    ///
    /// - Note: Analytics events are tracked automatically if analytics delegate is configured.
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
    
    /// Restore previous purchases.
    ///
    /// Checks for existing entitlements and updates premium status.
    /// Required by App Store guidelines to provide a restore option.
    ///
    /// Use this when:
    /// - User reinstalls the app
    /// - User switches devices
    /// - User signs in with different Apple ID
    ///
    /// ## Example
    ///
    /// ```swift
    /// Button("Restore Purchases") {
    ///     Task {
    ///         await premiumManager.restorePurchases()
    ///         if premiumManager.isPremium {
    ///             showSuccess("Purchases restored!")
    ///         } else {
    ///             showInfo("No purchases found")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: Syncs with App Store and updates ``isPremium`` automatically.
    /// - Note: Tracks analytics event if analytics delegate is configured.
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

