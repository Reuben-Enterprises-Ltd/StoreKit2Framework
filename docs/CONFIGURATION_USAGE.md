# Product Configuration System Usage Guide

The StoreKit2Framework provides a flexible configuration system that allows you to customize product identifiers, features, and behavior without modifying the framework code.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Configuration Components](#configuration-components)
- [Usage Examples](#usage-examples)
- [Validation](#validation)
- [Paywall Configuration](#paywall-configuration)
- [Best Practices](#best-practices)
- [API Reference](#api-reference)

## Overview

The configuration system consists of three main components:

1. **ProductIdentifiers** - Define your App Store product IDs
2. **Configuration** - Configure the PremiumManager behavior
3. **PaywallConfiguration** - Customize the paywall appearance

## Quick Start

### Basic Setup

Configure the PremiumManager in your app's initialization, before calling `ensureInitialized()`:

```swift
import SwiftUI
import StoreKit2Framework

@main
struct MyApp: App {
    init() {
        // 1. Create configuration
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.myapp.premium.monthly",
                yearly: "com.myapp.premium.yearly",
                lifetime: "com.myapp.premium.lifetime"
            ),
            features: [
                .init(title: "Unlimited exports", systemImageName: "square.and.arrow.up"),
                .init(title: "Advanced analytics", systemImageName: "chart.xyaxis.line"),
                .init(title: "Cloud sync", systemImageName: "icloud"),
                .init(title: "Priority support", systemImageName: "person.fill.questionmark")
            ]
        )
        
        // 2. Apply configuration
        PremiumManager.shared.configure(config)
        
        // 3. Initialize
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Configuration Components

### ProductIdentifiers

Defines the App Store product IDs your app uses.

```swift
let productIds = PremiumManager.ProductIdentifiers(
    monthly: "com.myapp.pro.monthly",    // Required
    yearly: "com.myapp.pro.yearly",       // Required
    lifetime: "com.myapp.pro.lifetime"    // Optional
)
```

**Properties:**
- `monthly: String` - Monthly subscription product ID
- `yearly: String` - Yearly subscription product ID
- `lifetime: String?` - Optional lifetime (non-renewing) subscription
- `all: [String]` - Computed property returning all non-nil product IDs

**Default Configuration:**
```swift
PremiumManager.ProductIdentifiers.default
// monthly: "com.yourcompany.yourapp.monthly"
// yearly: "com.yourcompany.yourapp.yearly"
// lifetime: "com.yourcompany.yourapp.lifetime"
```

### Feature

Represents a displayable benefit/feature shown in the paywall.

```swift
let feature = PremiumManager.Feature(
    title: "Cloud Sync",
    systemImageName: "icloud"
)
```

**Properties:**
- `title: String` - The user-facing title of the feature
- `systemImageName: String` - The SF Symbol name to represent the feature visually

### Configuration

Main configuration struct for PremiumManager.

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: productIds,
    features: [
        .init(title: "Feature 1", systemImageName: "star.fill"),
        .init(title: "Feature 2", systemImageName: "bolt.fill")
    ],
    enableDebugMode: false,
    cacheKey: "premium_status",
    privacyPolicyURL: URL(string: "https://myapp.com/privacy")!,
    termsOfServiceURL: URL(string: "https://myapp.com/terms")!
)
```

**Properties:**
- `productIdentifiers: ProductIdentifiers` - Product IDs to use
- `features: [PremiumManager.Feature]` - List of features/benefits for paywall with custom SF Symbol icons
- `enableDebugMode: Bool` - Enable verbose logging
- `cacheKey: String` - UserDefaults key for caching premium status
- `privacyPolicyURL: URL` - Privacy policy URL (default: `https://support.reubenenterprises.com/privacy`)
- `termsOfServiceURL: URL` - Terms of service URL (default: Apple's EULA)

**Default Legal URLs:**
- Privacy: `https://support.reubenenterprises.com/privacy`
- Terms: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

**Presets:**
```swift
// Default configuration
PremiumManager.Configuration.default

// Debug configuration (enableDebugMode = true)
PremiumManager.Configuration.debug

// Production configuration (enableDebugMode = false)
PremiumManager.Configuration.production
```

### PaywallConfiguration

Customize the paywall appearance.

```swift
let paywallConfig = PaywallConfiguration(
    headline: "Unlock Premium",
    features: [
        .init(title: "Feature 1", systemImageName: "star.fill"),
        .init(title: "Feature 2", systemImageName: "bolt.fill")
    ],
    showRestoreButton: true,
    showPrivacyLinks: true,
    tintColor: .blue
)
```

## Usage Examples

### Example 1: Simple App with Two Product Tiers

```swift
@main
struct SimpleApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.simpleapp.pro.monthly",
                yearly: "com.simpleapp.pro.yearly",
                lifetime: nil  // No lifetime option
            ),
            features: [
                .init(title: "Unlimited exports", systemImageName: "square.and.arrow.up"),
                .init(title: "Advanced features", systemImageName: "wand.and.stars"),
                .init(title: "Priority support", systemImageName: "person.fill.questionmark")
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

### Example 2: Environment-Based Configuration

```swift
@main
struct MyApp: App {
    init() {
        #if DEBUG
        let config = PremiumManager.Configuration.debug
        #else
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.myapp.premium.monthly",
                yearly: "com.myapp.premium.yearly",
                lifetime: "com.myapp.premium.lifetime"
            ),
            features: [
                .init(title: "Export unlimited projects", systemImageName: "square.and.arrow.up"),
                .init(title: "Advanced analytics", systemImageName: "chart.xyaxis.line"),
                .init(title: "Priority support", systemImageName: "person.fill.questionmark")
            ],
            enableDebugMode: false
        )
        #endif
        
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

### Example 3: Multiple Premium Tiers

For apps with multiple premium tiers, create different configurations:

```swift
enum PremiumTier {
    case basic
    case pro
    
    var configuration: PremiumManager.Configuration {
        switch self {
        case .basic:
            return .init(
                productIdentifiers: .init(
                    monthly: "com.app.basic.monthly",
                    yearly: "com.app.basic.yearly"
                ),
                features: [
                    .init(title: "Remove ads", systemImageName: "nosign"),
                    .init(title: "Basic analytics", systemImageName: "chart.bar")
                ]
            )
        case .pro:
            return .init(
                productIdentifiers: .init(
                    monthly: "com.app.pro.monthly",
                    yearly: "com.app.pro.yearly",
                    lifetime: "com.app.pro.lifetime"
                ),
                features: [
                    .init(title: "All features", systemImageName: "star.fill"),
                    .init(title: "Advanced analytics", systemImageName: "chart.xyaxis.line"),
                    .init(title: "Priority support", systemImageName: "person.fill.questionmark"),
                    .init(title: "Custom themes", systemImageName: "paintbrush.pointed")
                ]
            )
        }
    }
}

// In your app init:
let tier: PremiumTier = .pro
PremiumManager.shared.configure(tier.configuration)
```

### Example 4: Custom Paywall Configuration

```swift
struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Show Premium") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                configuration: PaywallConfiguration(
                    headline: "Go Pro to Continue",
                    features: [
                        .init(title: "Unlimited access", systemImageName: "infinity"),
                        .init(title: "Priority support", systemImageName: "person.fill.questionmark"),
                        .init(title: "Cloud sync", systemImageName: "icloud")
                    ],
                    showRestoreButton: true,
                    showPrivacyLinks: true,
                    tintColor: .purple
                )
                // Legal URLs are automatically loaded from Configuration
                // No need to pass privacyPolicyURL or termsOfServiceURL
            )
        }
    }
}
```

### Example 5: Using PremiumManager Configuration in Paywall

The PaywallView automatically uses features and legal URLs from PremiumManager configuration:

```swift
// In app init - configure legal URLs once
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [
        .init(title: "Feature A", systemImageName: "a.circle.fill"),
        .init(title: "Feature B", systemImageName: "b.circle.fill"),
        .init(title: "Feature C", systemImageName: "c.circle.fill")
    ],
    privacyPolicyURL: URL(string: "https://myapp.com/privacy")!,
    termsOfServiceURL: URL(string: "https://myapp.com/terms")!
)
PremiumManager.shared.configure(config)

// In your views - legal URLs are automatically pulled from config
.sheet(isPresented: $showPaywall) {
    PaywallView()  // Uses configuration defaults
}
```

**Note:** Legal URLs can still be overridden per-paywall if needed:
```swift
PaywallView(
    privacyPolicyURL: URL(string: "https://different.com/privacy"),
    termsOfServiceURL: URL(string: "https://different.com/terms")
)
// However, this is deprecated. Configure URLs in PremiumManager.Configuration instead.
```

## Validation

The configuration system includes built-in validation to catch common errors:

### What Gets Validated

1. **Product IDs are not empty**
2. **Product IDs follow Apple's format** (must contain '.')
3. **No duplicate product IDs**
4. **Cache key is not empty**
5. **Features list warning** (if empty and debug mode enabled)

### Validation Example

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .init(
        monthly: "invalid",  // ❌ Missing '.'
        yearly: "com.app.yearly",
        lifetime: ""  // ❌ Empty string
    )
)

// Validation happens automatically in configure()
PremiumManager.shared.configure(config)
// Prints error and continues with previous config
```

### Manual Validation

You can also validate manually:

```swift
let config = PremiumManager.Configuration(...)

do {
    try config.validate()
    print("✅ Configuration is valid")
} catch let error as ConfigurationError {
    print("❌ Configuration error: \(error.errorDescription ?? "")")
}
```

### Configuration Errors

```swift
public enum ConfigurationError: Error {
    case emptyProductID(field: String)
    case invalidProductIDFormat(id: String)
    case duplicateProductIDs
    case emptyCacheKey
}
```

## Paywall Configuration

### Using Default Behavior

```swift
PaywallView()  // Uses PremiumManager configuration
```

### Custom Configuration

```swift
PaywallView(
    configuration: PaywallConfiguration(
        headline: "Custom Headline",
        features: ["Custom Feature 1", "Custom Feature 2"],
        showRestoreButton: true,
        showPrivacyLinks: false,
        tintColor: .orange
    )
)
```

### Legacy API (Backward Compatible)

```swift
PaywallView(
    headline: "Go Premium",
    benefits: [
        BenefitItem(icon: "star.fill", title: "Feature 1", description: ""),
        BenefitItem(icon: "bolt.fill", title: "Feature 2", description: "")
    ]
)
```

## Best Practices

### 1. Configure Before Initialization

```swift
// ✅ Correct order
PremiumManager.shared.configure(config)
PremiumManager.shared.ensureInitialized()

// ❌ Wrong order (configuration won't take effect)
PremiumManager.shared.ensureInitialized()
PremiumManager.shared.configure(config)
```

### 2. Use Environment-Based Configuration

```swift
#if DEBUG
let config = Configuration.debug
#else
let config = Configuration.production
#endif
```

### 3. Validate Product IDs

Ensure your product IDs match those in App Store Connect:
- Must contain at least one '.'
- Follow reverse-domain format: `com.company.app.product`
- Must match exactly what's in App Store Connect

### 4. Store Configuration for Testing

```swift
struct TestConfiguration {
    static let test = PremiumManager.Configuration(
        productIdentifiers: .init(
            monthly: "com.test.monthly",
            yearly: "com.test.yearly"
        ),
        features: [
            .init(title: "Test Feature", systemImageName: "star.fill")
        ],
        enableDebugMode: true,
        cacheKey: "test_premium_status"
    )
}
```

### 5. Centralize Feature Lists

```swift
enum AppFeatures {
    static let premiumFeatures: [PremiumManager.Feature] = [
        .init(title: "Unlimited exports", systemImageName: "square.and.arrow.up"),
        .init(title: "Advanced analytics", systemImageName: "chart.xyaxis.line"),
        .init(title: "Priority support", systemImageName: "person.fill.questionmark"),
        .init(title: "Custom themes", systemImageName: "paintbrush.pointed")
    ]
}

let config = Configuration(
    productIdentifiers: .default,
    features: AppFeatures.premiumFeatures
)
```

## API Reference

### PremiumManager

```swift
// Configure (must be called before ensureInitialized)
func configure(_ config: Configuration)

// Access current configuration (read-only)
var currentConfiguration: Configuration { get }
```

### Configuration

```swift
struct Configuration {
    var productIdentifiers: ProductIdentifiers
    var features: [PremiumManager.Feature]
    var enableDebugMode: Bool
    var cacheKey: String
    
    static var `default`: Configuration
    static var debug: Configuration
    static var production: Configuration
    
    func validate() throws
}
```

### Feature

```swift
struct Feature {
    let title: String
    let systemImageName: String
    
    init(title: String, systemImageName: String)
}
```

### ProductIdentifiers

```swift
struct ProductIdentifiers {
    var monthly: String
    var yearly: String
    var lifetime: String?
    var all: [String] { get }
    
    static var `default`: ProductIdentifiers
    
    init(monthly: String, yearly: String, lifetime: String? = nil)
}
```

### PaywallConfiguration

```swift
struct PaywallConfiguration {
    var headline: String
    var features: [PremiumManager.Feature]
    var showRestoreButton: Bool
    var showPrivacyLinks: Bool
    var tintColor: Color?
    
    static var `default`: PaywallConfiguration
}
```

## Advanced Features

The framework supports optional advanced features that enhance functionality without impacting the core behavior.

### Analytics Integration

Track premium events with your analytics service:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    analytics: MyAnalytics()  // Your PremiumAnalytics implementation
)
```

### Offline Grace Period

Allow offline access for a specified duration:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 604800  // 7 days in seconds
)
```

### Promotional Offers

Enable promotional offers support:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    enablePromotionalOffers: true
)
```

For detailed information, see [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md).

---

## Troubleshooting

### Configuration Not Taking Effect

**Problem:** Product IDs or features not updating
**Solution:** Ensure `configure()` is called before `ensureInitialized()`

### Debug Logging

Enable debug mode to see configuration details:

```swift
let config = Configuration(
    productIdentifiers: .default,
    features: [
        .init(title: "Feature 1", systemImageName: "star.fill")
    ],
    enableDebugMode: true  // 👈 Enable verbose logging
)
```

Output:
```
✅ PremiumManager configured with:
  - Products: ["com.app.monthly", "com.app.yearly"]
  - Features: 1 features
  - Debug mode: true
✅ Loaded 2 products: ["com.app.monthly", "com.app.yearly"]
```

### Invalid Product IDs

If products fail to load, check:
1. Product IDs match App Store Connect exactly
2. Products are in "Ready to Submit" or "Approved" state
3. StoreKit configuration file is correct (for testing)

## Related Documentation

- [PREMIUM_MANAGER_USAGE.md](PREMIUM_MANAGER_USAGE.md) - PremiumManager basics
- [PAYWALL_VIEW_USAGE.md](PAYWALL_VIEW_USAGE.md) - PaywallView customization
- [QUICK_START.md](../QUICK_START.md) - Getting started guide
- [README.md](../README.md) - Framework overview

## Support

For issues, feature requests, or questions:
- GitHub Issues: [StoreKit2Framework Issues](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/issues)
