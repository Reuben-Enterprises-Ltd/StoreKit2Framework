# Issue 012: Product Configuration System

## Priority
**High** - Required for framework flexibility

## Description
Create a flexible product configuration system that allows apps to easily customize product IDs, descriptions, and benefits without modifying framework code.

## Requirements

### Configuration API

The framework needs to support different product setups for different apps. Create a configuration system:

```swift
// Default configuration
PremiumManager.Configuration.default

// Custom configuration
let config = PremiumManager.Configuration(
    productIdentifiers: ProductIdentifiers(
        monthly: "com.myapp.premium.monthly",
        yearly: "com.myapp.premium.yearly",
        lifetime: "com.myapp.premium.lifetime"
    ),
    features: [
        "Export unlimited projects",
        "Advanced analytics",
        "Priority support",
        "Remove ads",
        "Cloud sync"
    ],
    enableDebugMode: true
)

PremiumManager.shared.configure(config)
```

### Configurable Components

#### 1. Product Identifiers
- Must be customizable per app
- Validated on configuration
- Type-safe access

#### 2. Feature List
- Customizable benefits list
- Used in PaywallView
- Can be localized

#### 3. Paywall Customization
- Custom headlines
- Custom benefits
- Custom colors (optional)
- Custom button text

#### 4. Debug Settings
- Premium override flag
- Verbose logging
- Mock product mode

### Implementation Pattern

```swift
extension PremiumManager {
    struct Configuration {
        var productIdentifiers: ProductIdentifiers
        var features: [String]
        var enableDebugMode: Bool
        var cacheKey: String
        
        static var `default`: Configuration {
            Configuration(
                productIdentifiers: .default,
                features: [],
                enableDebugMode: false,
                cacheKey: "premium_status"
            )
        }
    }
    
    struct ProductIdentifiers {
        var monthly: String
        var yearly: String
        var lifetime: String?
        
        var all: [String] {
            [monthly, yearly, lifetime].compactMap { $0 }
        }
        
        static var `default`: ProductIdentifiers {
            ProductIdentifiers(
                monthly: "com.default.monthly",
                yearly: "com.default.yearly",
                lifetime: "com.default.lifetime"
            )
        }
    }
    
    func configure(_ config: Configuration) {
        // Apply configuration
    }
}
```

### PaywallView Configuration

```swift
struct PaywallView: View {
    let configuration: PaywallConfiguration
    
    init(
        headline: String? = nil,
        features: [String]? = nil,
        configuration: PaywallConfiguration = .default
    ) {
        // Use provided or fall back to PremiumManager config
    }
}

struct PaywallConfiguration {
    var headline: String
    var features: [String]
    var showRestoreButton: Bool
    var showPrivacyLinks: Bool
    var tintColor: Color?
    
    static var `default`: PaywallConfiguration { ... }
}
```

## Validation

The configuration system should validate:
- Product IDs are not empty
- Product IDs follow Apple's format
- Features list is not empty (warn if empty)
- No duplicate product IDs

```swift
extension PremiumManager.Configuration {
    func validate() throws {
        guard !productIdentifiers.monthly.isEmpty else {
            throw ConfigurationError.emptyProductID
        }
        // ... more validation
    }
}
```

## Environment-Based Configuration

Support different configs for different environments:

```swift
#if DEBUG
let config = Configuration.debug
#else
let config = Configuration.production
#endif

PremiumManager.shared.configure(config)
```

## Acceptance Criteria
- [ ] Configuration struct created
- [ ] ProductIdentifiers customizable
- [ ] Features list customizable
- [ ] Debug settings available
- [ ] Validation logic implemented
- [ ] Default configuration provided
- [ ] Environment-specific configs supported
- [ ] PaywallView uses configuration
- [ ] Documentation with examples
- [ ] Type-safe API
- [ ] Compile-time checks where possible

## Usage Examples

### Example 1: Simple Setup
```swift
@main
struct MyApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.myapp.pro.monthly",
                yearly: "com.myapp.pro.yearly",
                lifetime: nil  // No lifetime option
            ),
            features: [
                "Unlimited exports",
                "Advanced features",
                "Priority support"
            ]
        )
        
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
}
```

### Example 2: Multiple Product Groups
```swift
// For apps with multiple premium tiers
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
                features: ["Feature 1", "Feature 2"]
            )
        case .pro:
            return .init(
                productIdentifiers: .init(
                    monthly: "com.app.pro.monthly",
                    yearly: "com.app.pro.yearly"
                ),
                features: ["All features", "Priority support"]
            )
        }
    }
}
```

## Technical Notes
- Configuration should be set before `ensureInitialized()`
- Thread-safe configuration access
- Immutable after initialization (prevent runtime changes)
- Consider using property wrappers for config access
- Store configuration for unit tests

## Related Issues
- Depends on: #002 (PremiumManager structure)
- Enhances: #003 (PaywallView customization)
- Required for: #007 (Example app needs to configure)

## Estimated Effort
3-4 hours
