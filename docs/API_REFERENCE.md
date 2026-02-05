# API Reference

Complete API documentation for StoreKit2Framework. This reference covers all public types, properties, methods, and modifiers.

## Table of Contents

1. [PremiumManager](#premiummanager)
2. [Configuration Types](#configuration-types)
3. [PaywallView](#paywallview)
4. [Premium Settings Components](#premium-settings-components)
5. [Feature Gating](#feature-gating)
6. [Analytics](#analytics)
7. [Error Types](#error-types)

## PremiumManager

The central coordinator for all StoreKit operations. Manages premium subscription status and handles all purchase flows.

### Overview

```swift
@MainActor
@Observable
public final class PremiumManager
```

- **Thread Safety**: Must be accessed from main actor
- **Pattern**: Singleton via `.shared`
- **Observation**: Automatic UI updates via `@Observable`

### Singleton Instance

```swift
public static let shared: PremiumManager
```

**Usage:**
```swift
private let premiumManager = PremiumManager.shared
```

### Properties

#### isPremium

```swift
public private(set) var isPremium: Bool
```

Whether the user currently has active premium access.

**Example:**
```swift
if premiumManager.isPremium {
    // Show premium features
}
```

#### products

```swift
public private(set) var products: [Product]
```

Available products loaded from the App Store, sorted by price (lowest to highest).

**Example:**
```swift
ForEach(premiumManager.products) { product in
    ProductButton(product: product)
}
```

#### isLoading

```swift
public private(set) var isLoading: Bool
```

Whether products are currently being loaded from the App Store.

**Example:**
```swift
if premiumManager.isLoading {
    ProgressView("Loading products...")
}
```

#### error

```swift
public private(set) var error: Error?
```

The last error that occurred during product loading or purchase.

**Example:**
```swift
if let error = premiumManager.error {
    Text("Error: \(error.localizedDescription)")
}
```

#### activeEntitlement

```swift
public private(set) var activeEntitlement: Product.SubscriptionInfo.Status?
```

The user's active subscription status, if any. Contains details about the subscription.

**Example:**
```swift
if let status = premiumManager.activeEntitlement {
    Text("Subscribed since: \(status.renewalInfo.purchaseDate)")
}
```

#### currentConfiguration

```swift
public var currentConfiguration: Configuration
```

Read-only access to the current configuration.

**Example:**
```swift
let monthlyID = premiumManager.currentConfiguration.productIdentifiers.monthly
```

### Methods

#### configure(_:)

```swift
public func configure(_ config: Configuration)
```

Configure the PremiumManager with custom settings.

**Parameters:**
- `config`: The configuration to use

**Important:** Must be called **before** `ensureInitialized()` to take effect.

**Example:**
```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .init(
        monthly: "com.app.monthly",
        yearly: "com.app.yearly"
    ),
    features: [
        .init(title: "Cloud Sync", systemImageName: "icloud.fill")
    ]
)
PremiumManager.shared.configure(config)
```

#### ensureInitialized()

```swift
public func ensureInitialized()
```

Initialize the PremiumManager and start monitoring transactions. Call once during app launch.

**Example:**
```swift
@main
struct MyApp: App {
    init() {
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
}
```

#### loadProducts()

```swift
public func loadProducts() async
```

Load available products from the App Store. Usually called automatically during initialization.

**Example:**
```swift
Task {
    await premiumManager.loadProducts()
}
```

#### purchase(_:)

```swift
public func purchase(_ product: Product) async throws
```

Purchase a specific product.

**Parameters:**
- `product`: The product to purchase

**Throws:** `PremiumError` if purchase fails

**Example:**
```swift
Task {
    do {
        try await premiumManager.purchase(product)
        // Purchase successful
    } catch {
        // Handle error
        print("Purchase failed: \(error)")
    }
}
```

#### restorePurchases()

```swift
public func restorePurchases() async
```

Restore previous purchases. Checks for existing entitlements and updates premium status.

**Example:**
```swift
Button("Restore Purchases") {
    Task {
        await premiumManager.restorePurchases()
    }
}
```

#### trackPaywallShown(source:)

```swift
public func trackPaywallShown(source: String = "unknown")
```

Track that a paywall was shown. Calls analytics delegate if configured.

**Parameters:**
- `source`: Context where paywall was shown (e.g., "onboarding", "settings")

**Example:**
```swift
premiumManager.trackPaywallShown(source: "feature_limit")
```

## Configuration Types

### PremiumManager.Configuration

Configuration for the PremiumManager.

```swift
public struct Configuration {
    public var productIdentifiers: ProductIdentifiers
    public var features: [PremiumManager.Feature]
    public var enableDebugMode: Bool
    public var cacheKey: String
    public var analytics: (any PremiumAnalytics)?
    public var offlineGracePeriod: TimeInterval
    public var enablePromotionalOffers: Bool
    public var privacyPolicyURL: URL
    public var termsOfServiceURL: URL
}
```

#### Initializer

```swift
public init(
    productIdentifiers: ProductIdentifiers = .default,
    features: [PremiumManager.Feature] = [],
    enableDebugMode: Bool = false,
    cacheKey: String = "premium_status",
    analytics: (any PremiumAnalytics)? = nil,
    offlineGracePeriod: TimeInterval = 86400,
    enablePromotionalOffers: Bool = false,
    privacyPolicyURL: URL = URL(string: "https://support.reubenenterprises.com/privacy")!,
    termsOfServiceURL: URL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
)
```

**Parameters:**
- `productIdentifiers`: Product IDs for your in-app purchases
- `features`: Benefits displayed in paywall
- `enableDebugMode`: Enable verbose logging
- `cacheKey`: UserDefaults key for caching premium status
- `analytics`: Optional analytics delegate
- `offlineGracePeriod`: Seconds premium remains accessible offline (default: 24 hours)
- `enablePromotionalOffers`: Enable promotional offers support
- `privacyPolicyURL`: Privacy policy URL (default: `https://support.reubenenterprises.com/privacy`)
- `termsOfServiceURL`: Terms of service URL (default: Apple's standard EULA)

**Default Legal URLs:**
- Privacy: `https://support.reubenenterprises.com/privacy`
- Terms: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

#### Static Presets

```swift
public static var `default`: Configuration
public static var debug: Configuration
public static var production: Configuration
```

All presets include the default legal URLs.

#### validate()

```swift
public func validate() throws
```

Validates the configuration. Checks for:
- Non-empty product IDs
- Valid product ID format (contains '.')
- No duplicate product IDs
- Non-empty cache key

**Throws:** `ConfigurationError` if validation fails

### PremiumManager.ProductIdentifiers

Product identifiers for In-App Purchases.

```swift
public struct ProductIdentifiers {
    public var monthly: String
    public var yearly: String
    public var lifetime: String?
    
    public var all: [String]
}
```

#### Initializer

```swift
public init(
    monthly: String,
    yearly: String,
    lifetime: String? = nil
)
```

#### default

```swift
public static var `default`: ProductIdentifiers
```

Default product identifiers (placeholder values).

### PremiumManager.Feature

A displayable feature shown in the paywall.

```swift
public struct Feature {
    public let title: String
    public let systemImageName: String
}
```

#### Initializer

```swift
public init(title: String, systemImageName: String)
```

**Example:**
```swift
let feature = PremiumManager.Feature(
    title: "Cloud Sync",
    systemImageName: "icloud.fill"
)
```

## PaywallView

Beautiful, customizable view for displaying products and handling purchases.

### Overview

```swift
public struct PaywallView: View
```

### PaywallConfiguration

Configuration for PaywallView appearance and behavior.

```swift
public struct PaywallConfiguration {
    public var headline: String
    public var features: [PremiumManager.Feature]
    public var showRestoreButton: Bool
    public var showPrivacyLinks: Bool
    public var tintColor: Color?
}
```

#### Initializer

```swift
public init(
    headline: String = "Unlock Premium Features",
    features: [PremiumManager.Feature] = [],
    showRestoreButton: Bool = true,
    showPrivacyLinks: Bool = true,
    tintColor: Color? = nil
)
```

### PaywallView Initializers

#### Modern Initializer (Recommended)

```swift
public init(
    configuration: PaywallConfiguration? = nil,
    privacyPolicyURL: URL? = nil,  // Deprecated
    termsOfServiceURL: URL? = nil,  // Deprecated
    analyticsSource: String = PaywallView.defaultAnalyticsSource
)
```

**Parameters:**
- `configuration`: Custom paywall configuration (uses PremiumManager config if nil)
- `privacyPolicyURL`: **Deprecated** - Use `Configuration.privacyPolicyURL` instead
- `termsOfServiceURL`: **Deprecated** - Use `Configuration.termsOfServiceURL` instead
- `analyticsSource`: Source/context for analytics tracking

**Example (Updated Approach):**
```swift
// Configure legal URLs once in app init
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    privacyPolicyURL: URL(string: "https://app.com/privacy")!,
    termsOfServiceURL: URL(string: "https://app.com/terms")!
)
PremiumManager.shared.configure(config)

// Use PaywallView without URLs - they come from config
PaywallView(
    configuration: .init(
        headline: "Unlock Your Potential",
        showRestoreButton: true
    ),
    analyticsSource: "onboarding"
)
```

**Legacy Example (Still Supported):**
```swift
// URLs can still be passed directly (deprecated)
PaywallView(
    configuration: .init(
        headline: "Unlock Your Potential",
        showRestoreButton: true
    ),
    privacyPolicyURL: URL(string: "https://app.com/privacy")!,
    termsOfServiceURL: URL(string: "https://app.com/terms")!,
    analyticsSource: "onboarding"
)
```

#### Legacy Initializer (Deprecated)

```swift
public init(
    headline: String? = nil,
    benefits: [BenefitItem]? = nil,
    privacyPolicyURL: URL? = nil,  // Deprecated
    termsOfServiceURL: URL? = nil,  // Deprecated
    analyticsSource: String = PaywallView.defaultAnalyticsSource
)
```

**Note:** Use modern initializer with `PaywallConfiguration` instead. Legal URLs should be configured in `PremiumManager.Configuration`.

### BenefitItem

Individual benefit displayed in paywall (legacy).

```swift
public struct BenefitItem: Identifiable {
    public let id: UUID
    public let icon: String
    public let title: String
    public let description: String
}
```

#### Initializer

```swift
public init(icon: String, title: String, description: String)
```

**Example:**
```swift
BenefitItem(
    icon: "star.fill",
    title: "Premium Features",
    description: "Access all advanced features"
)
```

### BenefitRow

Individual benefit row view.

```swift
public struct BenefitRow: View
```

Used internally by PaywallView to display benefits.

### ProductOptionButton

Button for displaying and selecting a product.

```swift
public struct ProductOptionButton: View
```

Used internally by PaywallView to display purchase options.

## Premium Settings Components

Pre-built UI components for settings screens.

### PremiumSettingsSection

Complete settings section with status and actions.

```swift
public struct PremiumSettingsSection: View
```

Displays:
- Premium status indicator
- Subscription type (if applicable)
- Upgrade button (for free users)
- Manage subscription button (for premium users)
- Restore purchases button

**Example:**
```swift
Form {
    PremiumSettingsSection()
    
    Section("General") {
        // Other settings
    }
}
```

#### Initializer

```swift
public init()
```

### PremiumStatusRow

Compact row for displaying premium status.

```swift
public struct PremiumStatusRow: View
```

Shows premium status with icon and badge.

**Example:**
```swift
List {
    PremiumStatusRow()
    // Other items
}
```

#### Initializer

```swift
public init()
```

### PremiumBadge

Small "Pro" badge indicator.

```swift
public struct PremiumBadge: View
```

**Example:**
```swift
Text("Advanced Feature")
    .badge(PremiumBadge())
```

#### Initializer

```swift
public init()
```

## Feature Gating

View modifiers and components for locking content behind premium.

### View Modifiers

#### premiumOnly()

```swift
public func premiumOnly() -> some View
```

Hides the view completely if user doesn't have premium.

**Example:**
```swift
NavigationLink("Advanced Settings") {
    AdvancedSettingsView()
}
.premiumOnly()
```

#### premiumGated(headline:)

```swift
public func premiumGated(headline: String = "Unlock Premium Features") -> some View
```

Shows blur overlay with paywall button when tapped if user isn't premium.

**Parameters:**
- `headline`: Custom headline for the paywall

**Example:**
```swift
ContentView()
    .premiumGated(headline: "Unlock Advanced Features")
```

#### premiumRequired()

```swift
public func premiumRequired() -> some View
```

Disables the view and shows lock icon if user isn't premium.

**Example:**
```swift
Button("Export Data") {
    exportData()
}
.premiumRequired()
```

### PremiumOverlay

Standalone overlay component for locked content.

```swift
public struct PremiumOverlay: View
```

#### Initializer

```swift
public init(
    headline: String = "Unlock Premium Features",
    showPaywall: Binding<Bool>
)
```

**Parameters:**
- `headline`: Headline text to display
- `showPaywall`: Binding to control paywall presentation

**Example:**
```swift
ZStack {
    ContentView()
    
    if !premiumManager.isPremium {
        PremiumOverlay(
            headline: "Premium Required",
            showPaywall: $showPaywall
        )
    }
}
```

## Analytics

Protocol for integrating analytics with the framework.

### PremiumAnalytics

```swift
@MainActor
public protocol PremiumAnalytics {
    func trackPaywallShown(source: String)
    func trackPurchaseCompleted(product: Product)
    func trackPurchaseFailed(product: Product?, error: Error)
    func trackPurchaseCancelled(product: Product)
    func trackRestorePurchases(success: Bool)
}
```

All methods have default no-op implementations, so you only need to implement what you need.

### Implementation Example

```swift
import StoreKit2Framework
import FirebaseAnalytics

class MyAnalytics: PremiumAnalytics {
    func trackPaywallShown(source: String) {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source
        ])
    }
    
    func trackPurchaseCompleted(product: Product) {
        Analytics.logEvent("purchase", parameters: [
            "product_id": product.id,
            "value": product.price as NSNumber
        ])
    }
    
    func trackPurchaseFailed(product: Product?, error: Error) {
        Analytics.logEvent("purchase_failed", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    func trackPurchaseCancelled(product: Product) {
        Analytics.logEvent("purchase_cancelled", parameters: [
            "product_id": product.id
        ])
    }
    
    func trackRestorePurchases(success: Bool) {
        Analytics.logEvent("restore_purchases", parameters: [
            "success": success
        ])
    }
}

// Configure
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    analytics: MyAnalytics()
)
```

## Error Types

### PremiumError

```swift
public enum PremiumError: Error {
    case failedVerification
    case productNotFound
    case purchaseCancelled
    case purchasePending
    case unknown
}
```

Errors that can occur during StoreKit operations.

#### Cases

- **failedVerification**: Transaction failed Apple's verification (security)
- **productNotFound**: Requested product not available
- **purchaseCancelled**: User cancelled the purchase
- **purchasePending**: Purchase is pending (requires action)
- **unknown**: Unknown error occurred

### ConfigurationError

```swift
public enum ConfigurationError: Error {
    case emptyProductID(field: String)
    case invalidProductIDFormat(id: String)
    case duplicateProductID(id: String)
    case emptyCacheKey
}
```

Configuration validation errors.

#### Cases

- **emptyProductID**: Product ID is empty
- **invalidProductIDFormat**: Product ID doesn't contain '.'
- **duplicateProductID**: Duplicate product ID found
- **emptyCacheKey**: Cache key is empty

## Usage Patterns

### Basic Setup

```swift
import SwiftUI
import StoreKit2Framework

@main
struct MyApp: App {
    init() {
        // Configure
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.app.monthly",
                yearly: "com.app.yearly"
            ),
            features: [
                .init(title: "Feature 1", systemImageName: "star.fill"),
                .init(title: "Feature 2", systemImageName: "bolt.fill"),
            ]
        )
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Checking Premium Status

```swift
struct MyView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            Text("Premium user")
        } else {
            Text("Free user")
        }
    }
}
```

### Showing Paywall

```swift
struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                privacyPolicyURL: URL(string: "https://app.com/privacy")!,
                termsOfServiceURL: URL(string: "https://app.com/terms")!,
                analyticsSource: "button_click"
            )
        }
    }
}
```

### Feature Gating

```swift
struct FeaturesView: View {
    var body: some View {
        VStack {
            // Hide completely
            AdvancedFeature()
                .premiumOnly()
            
            // Show with overlay
            DetailedView()
                .premiumGated(headline: "Get Premium")
            
            // Disable with lock
            Button("Export") { }
                .premiumRequired()
        }
    }
}
```

### Settings Integration

```swift
struct SettingsView: View {
    var body: some View {
        Form {
            PremiumSettingsSection()
            
            Section("General") {
                // Other settings
            }
        }
    }
}
```

## Platform Requirements

- **iOS**: 18.0+
- **Swift**: 6.2+
- **Xcode**: 16.0+

## Thread Safety

- **PremiumManager**: Must be accessed from `@MainActor`
- **All Views**: Automatically on main thread in SwiftUI
- **Analytics**: Protocol is `@MainActor` compliant

## Best Practices

1. **Configure Early**: Call `configure()` before `ensureInitialized()`
2. **Use Singleton**: Always use `PremiumManager.shared`
3. **Check isPremium**: Use reactive `isPremium` property
4. **Handle Errors**: Always handle purchase errors gracefully
5. **Show Restore**: Always provide restore purchases option
6. **Test Offline**: Verify app works without network
7. **Use Analytics**: Track events for business insights

## See Also

- [INTEGRATION.md](INTEGRATION.md) - Complete integration guide
- [BEST_PRACTICES.md](BEST_PRACTICES.md) - Best practices and recommendations
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [Examples/DemoApp](Examples/DemoApp) - Complete working example

---

**Version**: 1.0.0 | **Last Updated**: February 2026
