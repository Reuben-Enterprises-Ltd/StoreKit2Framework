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
- PaywallView UI component
- Premium settings components (PremiumSettingsSection, PremiumStatusRow, PremiumBadge)
- Comprehensive tests

### 🚧 In Progress
- Feature gating utilities
- Example app/demo

## 📋 What's Here

### Documentation
- **`STOREKIT_COPILOT_AGENT_GUIDE.md`** - Comprehensive guide on StoreKit 2 implementation patterns
- **`PREMIUM_MANAGER_USAGE.md`** - PremiumManager usage guide and examples
- **`PAYWALL_VIEW_USAGE.md`** - PaywallView usage guide and examples
- **`PREMIUM_SETTINGS_USAGE.md`** - Premium settings components usage guide
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

```swift
struct PremiumFeatureView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            // Show premium content
            AdvancedFeatureContent()
        } else {
            // Show upgrade prompt
            PremiumLockedView()
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

See [PAYWALL_VIEW_USAGE.md](PAYWALL_VIEW_USAGE.md), [PREMIUM_SETTINGS_USAGE.md](PREMIUM_SETTINGS_USAGE.md), and [PREMIUM_MANAGER_USAGE.md](PREMIUM_MANAGER_USAGE.md) for complete guides.

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
- **Feature Gating**: 🚧 Lock/unlock premium features (planned)

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

## 🧪 Testing Strategy

1. **Local Testing**: StoreKit configuration file
2. **Sandbox Testing**: Real devices with test accounts
3. **Unit Tests**: Core business logic
4. **Debug Mode**: Premium override for development
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
7. 🚧 Issue #005: Feature Gating Utilities
8. ⏳ Issue #006: Testing Infrastructure
9. ⏳ Issue #007: Example App/Demo
10. ⏳ Release v1.0.0

## 📞 Questions?

Check the issues in `/issues` directory for detailed implementation plans.

---

**Status**: Core functionality implemented and ready for integration. PaywallView provides a beautiful UI for purchases. See documentation for complete usage examples.
