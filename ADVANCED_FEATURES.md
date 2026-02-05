# Advanced Features and Customization

This guide covers advanced features and customization options available in the StoreKit2Framework. All advanced features are **opt-in** and maintain backward compatibility with the core framework.

## Table of Contents

1. [Analytics Integration](#analytics-integration)
2. [Offline Grace Period](#offline-grace-period)
3. [Promotional Offers Support](#promotional-offers-support)
4. [Future Features](#future-features)

---

## Analytics Integration

Track premium events and user behavior with your analytics service of choice.

### Overview

The analytics integration provides a simple protocol-based API for tracking key premium events:
- Paywall views
- Purchase completions
- Purchase failures
- Purchase cancellations
- Purchase restorations

### Implementation

#### 1. Create Your Analytics Class

Implement the `PremiumAnalytics` protocol to integrate with your analytics service:

```swift
import StoreKit2Framework
import StoreKit

@MainActor
class MyAnalytics: PremiumAnalytics {
    func trackPaywallShown(source: String) {
        // Send to your analytics service
        Analytics.logEvent("paywall_shown", parameters: ["source": source])
    }
    
    func trackPurchaseCompleted(product: Product) {
        // Track successful purchase
        Analytics.logEvent("purchase_completed", parameters: [
            "product_id": product.id,
            "price_string": product.displayPrice
        ])
        
        // Also track revenue with numeric price
        let priceDouble = NSDecimalNumber(decimal: product.price).doubleValue
        Analytics.logRevenue(
            amount: priceDouble,
            currency: product.priceFormatStyle.currencyCode
        )
    }
    
    func trackPurchaseFailed(product: Product?, error: Error) {
        // Track purchase failure
        Analytics.logEvent("purchase_failed", parameters: [
            "product_id": product?.id ?? "unknown",
            "error": error.localizedDescription
        ])
    }
    
    func trackPurchaseCancelled(product: Product) {
        // Track user cancellation
        Analytics.logEvent("purchase_cancelled", parameters: [
            "product_id": product.id
        ])
    }
    
    func trackRestorePurchases(success: Bool) {
        // Track restore attempts
        Analytics.logEvent("restore_purchases", parameters: [
            "success": success
        ])
    }
}
```

#### 2. Configure Analytics

Pass your analytics instance to the configuration:

```swift
import StoreKit2Framework

@main
struct MyApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: [
                .init(title: "Unlimited Access", systemImageName: "infinity"),
                .init(title: "Cloud Sync", systemImageName: "icloud")
            ],
            analytics: MyAnalytics()
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

#### 3. Track Paywall Views with Context

Pass the source/context when showing paywalls to understand user behavior:

```swift
struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(analyticsSource: "settings")
        }
    }
}
```

**Common source values:**
- `"onboarding"` - First app launch
- `"settings"` - Settings screen
- `"feature_gate"` - Blocked feature
- `"usage_limit"` - Usage limit reached
- `"promotion"` - Marketing campaign

### Privacy Considerations

- All analytics events are **opt-in** through configuration
- Only high-level actions are tracked, not user data
- No personal information is included in events
- Respect user privacy preferences
- Follow platform privacy guidelines (App Tracking Transparency on iOS)

### Protocol Methods

All `PremiumAnalytics` protocol methods have default no-op implementations, so you only need to implement the events you care about:

```swift
@MainActor
class MinimalAnalytics: PremiumAnalytics {
    // Only implement the events you need
    func trackPurchaseCompleted(product: Product) {
        // Your implementation
    }
    
    // Other methods use default no-op implementations
}
```

### Testing

Use a mock analytics class for testing:

```swift
@MainActor
class MockAnalytics: PremiumAnalytics {
    var events: [String] = []
    
    func trackPaywallShown(source: String) {
        events.append("paywall_shown:\(source)")
    }
    
    func trackPurchaseCompleted(product: Product) {
        events.append("purchase_completed:\(product.id)")
    }
}

// In tests
let analytics = MockAnalytics()
let config = PremiumManager.Configuration(analytics: analytics)
// Verify events
XCTAssertEqual(analytics.events.count, 2)
```

### Example Implementation

See [`Examples/DemoApp/DemoApp/ExampleAnalytics.swift`](Examples/DemoApp/DemoApp/ExampleAnalytics.swift) for a complete example implementation with console logging.

---

## Offline Grace Period

Allow users to access premium features offline for a specified duration.

### Overview

The offline grace period ensures premium users can continue using features even when offline or when the App Store verification temporarily fails.

### Configuration

Set the grace period duration (in seconds):

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 86400  // 24 hours (default)
)
```

**Common values:**
- `3600` - 1 hour
- `86400` - 24 hours (default)
- `604800` - 7 days
- `2592000` - 30 days

### How It Works

1. When a user has premium access, the framework caches this status
2. On subsequent app launches, cached status is used immediately
3. The framework verifies with App Store in the background
4. If verification fails (e.g., offline), cached status remains valid for the grace period
5. After the grace period expires, premium access is revoked until verification succeeds

### Best Practices

- **Short grace period** (1-7 days) for high-value features
- **Longer grace period** (7-30 days) for offline-first apps
- Consider your user experience when choosing duration
- Balance between user convenience and subscription protection

### Example

```swift
// For an offline-first notes app
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 604800  // 7 days
)

// For a streaming service
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 86400  // 24 hours
)
```

---

## Promotional Offers Support

Enable support for introductory offers and promotional offers.

### Configuration

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    enablePromotionalOffers: true
)
```

### Status

🚧 **Coming Soon** - This feature is currently in development.

When enabled, the framework will:
- Support introductory pricing (free trials, discounted first period)
- Support promotional offers (win-back campaigns, special pricing)
- Handle offer code redemption
- Display appropriate pricing in the paywall

---

## Future Features

The following features are planned for future releases:

### Subscription Groups Management
- Multiple subscription groups
- Cross-grade functionality
- Different product categories

### Family Sharing
- Family sharing status detection
- UI indicators for shared subscriptions
- Proper entitlement handling

### Server-Side Validation
- Receipt validation helpers
- Server notification handling
- Integration guides

### Advanced UI Components
- Compact paywall variants
- Premium status widgets
- Feature comparison tables

### Localization Support
- Multi-language paywall content
- Regional pricing display
- Currency formatting

### A/B Testing
- Multiple paywall variants
- Pricing experiments
- Built-in variant selection

### Grace Period Handling
- Billing retry period support
- Grace period UI indicators
- Recovery flows

See [issues/010-advanced-features-customization.md](issues/010-advanced-features-customization.md) for detailed feature descriptions and implementation plans.

---

## Backward Compatibility

All advanced features are designed to be:
- **Opt-in** - Not required for basic usage
- **Non-breaking** - Existing code continues to work
- **Well-documented** - Clear migration paths
- **Performance-conscious** - No impact when disabled

### Upgrading from Basic Configuration

Old code continues to work without changes:

```swift
// This still works exactly as before
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: []
)
```

Add advanced features when ready:

```swift
// Add analytics when you're ready
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    analytics: MyAnalytics()
)

// Or customize offline grace period
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 604800  // 7 days
)
```

---

## Configuration Reference

### Complete Configuration Example

```swift
let config = PremiumManager.Configuration(
    // Required: Product identifiers
    productIdentifiers: PremiumManager.ProductIdentifiers(
        monthly: "com.yourapp.monthly",
        yearly: "com.yourapp.yearly",
        lifetime: "com.yourapp.lifetime"
    ),
    
    // Optional: Features for paywall
    features: [
        .init(title: "Unlimited Access", systemImageName: "infinity"),
        .init(title: "Cloud Sync", systemImageName: "icloud")
    ],
    
    // Optional: Debug mode
    enableDebugMode: false,
    
    // Optional: Cache key
    cacheKey: "premium_status",
    
    // Advanced: Analytics (opt-in)
    analytics: MyAnalytics(),
    
    // Advanced: Offline grace period (default: 24 hours)
    offlineGracePeriod: 86400,
    
    // Advanced: Promotional offers (default: false)
    enablePromotionalOffers: false
)
```

---

## Getting Help

- **Documentation**: See [CONFIGURATION_USAGE.md](CONFIGURATION_USAGE.md) for core configuration
- **Examples**: Check [`Examples/DemoApp`](Examples/DemoApp) for working examples
- **Issues**: Report bugs or request features on GitHub
- **API Reference**: Full DocC documentation available

---

## Related Documentation

- [Configuration Usage Guide](CONFIGURATION_USAGE.md)
- [Quick Start Guide](QUICK_START.md)
- [Premium Manager Usage](PREMIUM_MANAGER_USAGE.md)
- [Testing Guide](TESTING_GUIDE.md)
