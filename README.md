# StoreKit2Framework

A modern, reusable Swift Package for implementing StoreKit 2 subscriptions in iOS apps.

## 🚀 Installation

### Swift Package Manager

You can add StoreKit2Framework to your iOS project using Swift Package Manager:

#### Xcode

1. In Xcode, select **File** → **Add Package Dependencies...**
2. Enter the package URL: `https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git`
3. Select the version you want to use
4. Click **Add Package**

#### Package.swift

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git", from: "0.1.0")
]
```

Then add it to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["StoreKit2Framework"]
)
```

### Requirements

- iOS 18.0+
- Swift 6.2+
- Xcode 16+

## 🎯 Quick Start

### Try the Example App

The fastest way to see the framework in action:

```bash
cd Examples/DemoApp
open DemoApp.xcodeproj
```

Select a simulator and press ⌘R. The example app demonstrates all integration patterns with comprehensive inline documentation.

[→ Full Example App Documentation](Examples/DemoApp/README.md)

### Basic Integration

```swift
// 1. Configure and initialize in your app
import StoreKit2Framework

@main
struct YourApp: App {
    init() {
        // Configure with your product IDs
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.yourapp.premium.monthly",
                yearly: "com.yourapp.premium.yearly",
                lifetime: "com.yourapp.premium.lifetime"
            ),
            features: [
                "Unlimited access",
                "Priority support",
                "Cloud sync"
            ]
        )
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
}

// 2. Show paywall
.sheet(isPresented: $showPaywall) {
    PaywallView()
}

// 3. Gate features
PremiumFeature()
    .premiumRequired()
```

[→ Complete Integration Guide](QUICK_START.md)

## 🚧 Status: Core Features Implemented

This repository contains a production-ready StoreKit 2 framework with core functionality implemented.

### ✅ Completed
- Package structure and foundation
- Core PremiumManager (@Observable, @MainActor)
- Product loading and management
- Purchase flow with transaction verification
- Restore purchases functionality
- Real-time transaction monitoring
- Premium status caching
- Product configuration system (flexible product IDs and features)
- PaywallView UI component
- Premium settings components (PremiumSettingsSection, PremiumStatusRow, PremiumBadge)
- Feature gating utilities (.premiumOnly(), .premiumGated(), .premiumRequired())
- Comprehensive testing infrastructure (69 tests, >80% coverage)
- StoreKit configuration file for local testing
- Mock objects and test helpers
- Debug tools and documentation
- **Example app/demo** - Complete DemoApp showing all integration patterns

## 📋 What's Here

### Examples
- **`Examples/DemoApp/`** - Complete iOS app demonstrating all framework features:
  - Framework initialization
  - Onboarding with paywall integration
  - Settings with premium management
  - Feature gating patterns (hide, disable, overlay)
  - Purchase flows and subscription management
  - [Full Documentation](Examples/DemoApp/README.md)

### Documentation
- **`STOREKIT_COPILOT_AGENT_GUIDE.md`** - Comprehensive guide on StoreKit 2 implementation patterns
- **`PREMIUM_MANAGER_USAGE.md`** - PremiumManager usage guide and examples
- **`PAYWALL_VIEW_USAGE.md`** - PaywallView usage guide and examples
- **`CONFIGURATION_USAGE.md`** - Product configuration system guide
- **`PREMIUM_SETTINGS_USAGE.md`** - Premium settings components usage guide
- **`FEATURE_GATING_USAGE.md`** - Feature gating utilities usage guide
- **`TESTING_GUIDE.md`** - Comprehensive testing documentation
- **`SCHEME_CONFIGURATION.md`** - Quick Xcode scheme setup for testing
- **`AGENTS.md`** - Development guidelines for Swift and SwiftUI
- **`ROADMAP.md`** - Complete implementation roadmap with phases and timelines

### Issues
The `/issues` directory contains detailed implementation issues:

1. **#001: Swift Package Foundation** - Basic package structure
2. **#002: Core PremiumManager** - Central subscription manager
3. **#003: PaywallView UI Component** - Beautiful purchase UI
4. **#004: Settings Integration** - Premium status display
5. **#005: Feature Gating Utilities** - Lock features behind premium
6. **#006: Testing Infrastructure** - Comprehensive tests
7. **#007: Example App/Demo** - Working example implementation
8. **#008: Documentation & API Reference** - Complete documentation
9. **#009: CI/CD Pipeline** - Automated testing and releases
10. **#010: Advanced Features** - Future enhancements
11. **#011: App Store Connect Guide** - Production setup guide
12. **#012: Product Configuration System** - Flexible configuration

## 🎯 Project Goals

Create a framework that:
- ✅ Works with **iOS 18+** and **Swift 6.2+**
- ✅ Uses modern **@Observable** pattern (not ObservableObject)
- ✅ Follows **strict Swift concurrency** rules
- ✅ Provides **beautiful SwiftUI** components
- ✅ Requires **minimal setup** in consuming apps
- ✅ Handles **security** (transaction verification)
- ✅ Supports **offline mode** (cached status)
- ✅ Is **thoroughly tested** and documented

## 🏗️ Planned Architecture

```
┌─────────────────────────────────────┐
│         App Store                   │
└────────────┬────────────────────────┘
             │
             │ StoreKit 2 API
             │
┌────────────▼────────────────────────┐
│      PremiumManager                 │
│   (@Observable, @MainActor)         │
│                                     │
│  • isPremium status                 │
│  • Load products                    │
│  • Process purchases                │
│  • Restore purchases                │
│  • Real-time updates                │
└────────────┬────────────────────────┘
             │
             │ Observable
             │
      ┌──────┴──────┐
      │             │
┌─────▼─────┐ ┌────▼──────┐
│ PaywallView│ │ Settings  │
│            │ │ Integration│
└────────────┘ └───────────┘
```

## 🚀 Quick Start

### 1. Add Package Dependency

Add StoreKit2Framework to your project using Swift Package Manager.

### 2. Initialize PremiumManager

```swift
import StoreKit2Framework

@main
struct MyApp: App {
    init() {
        // Initialize on app launch
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Show Paywall

```swift
import SwiftUI
import StoreKit2Framework

struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade to Premium") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                headline: "Unlock Premium Features",
                benefits: [
                    BenefitItem(
                        icon: "star.fill",
                        title: "Unlimited Access",
                        description: "No restrictions or limits"
                    ),
                    BenefitItem(
                        icon: "icloud.fill",
                        title: "Cloud Sync",
                        description: "Access on all devices"
                    )
                ],
                privacyPolicyURL: URL(string: "https://yourapp.com/privacy"),
                termsOfServiceURL: URL(string: "https://yourapp.com/terms")
            )
        }
    }
}
```

### 4. Gate Features

Use convenient view modifiers for feature gating:

```swift
import SwiftUI
import StoreKit2Framework

struct FeaturesView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Hide feature completely if not premium
            NavigationLink("Advanced Settings") {
                AdvancedSettingsView()
            }
            .premiumOnly()
            
            // Show with blur overlay if not premium
            PremiumContentView()
                .premiumGated(headline: "Unlock Advanced Features")
            
            // Disable with lock icon if not premium
            Button("Export Data") {
                exportData()
            }
            .premiumRequired()
        }
    }
}
```

### 5. Add Settings Integration

```swift
import SwiftUI
import StoreKit2Framework

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                PremiumSettingsSection()
                
                Section("General") {
                    Text("Notifications")
                    Text("Privacy")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

See [PAYWALL_VIEW_USAGE.md](PAYWALL_VIEW_USAGE.md), [PREMIUM_SETTINGS_USAGE.md](PREMIUM_SETTINGS_USAGE.md), [FEATURE_GATING_USAGE.md](FEATURE_GATING_USAGE.md), and [PREMIUM_MANAGER_USAGE.md](PREMIUM_MANAGER_USAGE.md) for complete guides.

## 📦 Features

### Core Functionality
- **PremiumManager**: Centralized subscription management
- **Product Loading**: Fetch products from App Store
- **Purchase Flow**: Secure purchase processing with verification
- **Restore Purchases**: Easy restoration on new devices
- **Real-time Updates**: Background transaction monitoring
- **Offline Support**: Cached premium status

### UI Components
- **PaywallView**: ✅ Beautiful purchase screen with customization
- **PremiumSettingsSection**: ✅ Complete settings section with status and actions
- **PremiumStatusRow**: ✅ Compact row for List views
- **PremiumBadge**: ✅ "Pro" badge indicator
- **Feature Gating**: ✅ Lock/unlock premium features (.premiumOnly(), .premiumGated(), .premiumRequired())
- **PremiumOverlay**: ✅ Standalone overlay component for locked content

### Developer Experience
- **Simple Setup**: One-line initialization
- **Type Safety**: Swift 6.2 strict concurrency
- **Testability**: Comprehensive test coverage
- **Documentation**: Extensive guides and examples
- **Debug Mode**: Test premium features without purchasing

## 📈 Implementation Timeline

### Phase 1: Foundation (10-12 hours)
- Package structure
- Core PremiumManager
- Configuration system

### Phase 2: UI Components (8-11 hours)
- PaywallView
- Settings integration
- Feature gating utilities

### Phase 3: Testing (4-6 hours)
- Unit tests
- Mock objects
- StoreKit configuration

### Phase 4: Documentation (15-20 hours)
- Example app
- API documentation
- Integration guides

### Phase 5: Production Ready (4-6 hours)
- CI/CD pipeline
- Release automation

**Total MVP: 41-55 hours (6-8 working days)**

See [ROADMAP.md](ROADMAP.md) for detailed timeline.

## 📚 Key Design Decisions

### Why @Observable instead of ObservableObject?
- Modern Swift pattern (iOS 17+)
- Cleaner syntax
- Better performance
- Less boilerplate

### Why Singleton Pattern?
- Single source of truth
- Consistent state across app
- Easy access from anywhere
- Prevents duplicate listeners

### Why Cache Premium Status?
- Instant UI updates on launch
- Works offline
- Verified asynchronously
- Better user experience

### Why Background Transaction Listener?
- Catches external changes (purchases from other devices)
- Handles refunds automatically
- Subscription renewals
- Family sharing updates

## 🔐 Security First

- ✅ All transactions verified before processing
- ✅ Never trust unverified purchases
- ✅ Secure transaction handling
- ✅ Follows Apple's best practices
- ✅ App Review compliant

## 🧪 Testing

The framework includes comprehensive testing infrastructure with **43 tests** covering all core functionality.

### Test Coverage

- ✅ PremiumManager (singleton, state management, concurrency)
- ✅ Product loading and error handling
- ✅ Premium status calculation and caching
- ✅ Purchase and restore flows
- ✅ Transaction verification
- ✅ UI components (PaywallView, Settings, Feature Gating)
- ✅ Debug utilities and mock objects

### Testing Tools Included

1. **StoreKit Configuration File** (`Configuration.storekit`)
   - Pre-configured test products (monthly, yearly, lifetime)
   - Ready for Xcode Simulator testing
   - See [SCHEME_CONFIGURATION.md](./SCHEME_CONFIGURATION.md) for setup

2. **Mock Objects and Test Helpers** (`TestHelpers.swift`)
   - Mock product data
   - Mock transaction information
   - Premium/free state helpers
   - Cache management utilities

3. **Debug Tools**
   - `PREMIUM_ENABLED` environment variable for instant premium access
   - Mock PremiumManager instances for testing
   - Works in DEBUG builds only

### Running Tests

```bash
# Run all tests
swift test

# View test list
swift test --list-tests

# Run specific test suite
swift test --filter "PremiumManager Tests"
```

### Documentation

- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Complete testing documentation
- **[SCHEME_CONFIGURATION.md](./SCHEME_CONFIGURATION.md)** - Quick Xcode scheme setup guide

### Testing Strategy

1. **Local Testing**: StoreKit configuration file in Simulator
2. **Unit Tests**: Comprehensive test coverage (>80% goal)
3. **Debug Mode**: Premium override for development
4. **Sandbox Testing**: Real devices with test accounts
5. **TestFlight**: Final validation before release

## 📖 Documentation Plan

- Quick start guide (5-minute integration)
- Complete integration guide
- API reference (DocC)
- Best practices guide
- Troubleshooting guide
- App Store Connect setup guide
- Example app with full implementation

## 🤝 Contributing

This project follows strict Swift and SwiftUI guidelines:
- iOS 18.0+
- Swift 6.2+
- Modern concurrency (async/await)
- @Observable pattern
- No UIKit (unless necessary)
- No third-party dependencies

See [AGENTS.md](AGENTS.md) for complete guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🗺️ Next Steps

1. ✅ Investigation complete
2. ✅ Issues created
3. ✅ Issue #001 Complete (Package foundation)
4. ✅ Issue #002 Complete (Core PremiumManager)
5. ✅ Issue #003 Complete (PaywallView UI)
6. ✅ Issue #004 Complete (Settings Integration)
7. ✅ Issue #005 Complete (Feature Gating Utilities)
8. ⏳ Issue #006: Testing Infrastructure
9. ⏳ Issue #007: Example App/Demo
10. ⏳ Release v1.0.0

## 📞 Questions?

Check the issues in `/issues` directory for detailed implementation plans.

---

**Status**: Core functionality implemented and ready for integration. PaywallView provides a beautiful UI for purchases. See documentation for complete usage examples.
