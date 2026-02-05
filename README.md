# StoreKit2Framework

A modern, reusable Swift Package for implementing StoreKit 2 subscriptions in iOS apps.

## 🚧 Status: Investigation Complete - Implementation Pending

This repository contains the investigation and planning documents for creating a reusable StoreKit2 framework that can be dropped into any iOS project.

## 📋 What's Here

### Documentation
- **`STOREKIT_COPILOT_AGENT_GUIDE.md`** - Comprehensive guide on StoreKit 2 implementation patterns
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
- ✅ Works with **iOS 26+** and **Swift 6.2+**
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

## 📦 Planned Features

### Core Functionality
- **PremiumManager**: Centralized subscription management
- **Product Loading**: Fetch products from App Store
- **Purchase Flow**: Secure purchase processing with verification
- **Restore Purchases**: Easy restoration on new devices
- **Real-time Updates**: Background transaction monitoring
- **Offline Support**: Cached premium status

### UI Components
- **PaywallView**: Beautiful purchase screen
- **Settings Integration**: Premium status display
- **Feature Gating**: Lock/unlock premium features
- **Premium Badges**: Visual indicators

### Developer Experience
- **Simple Setup**: One-line initialization
- **Type Safety**: Swift 6.2 strict concurrency
- **Testability**: Comprehensive test coverage
- **Documentation**: Extensive guides and examples
- **Debug Mode**: Test premium features without purchasing

## 🚀 Planned Usage

```swift
// 1. Initialize in app
@main
struct MyApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.myapp.premium.monthly",
                yearly: "com.myapp.premium.yearly"
            ),
            features: ["Unlimited exports", "Advanced features"]
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

// 2. Show paywall anywhere
Button("Upgrade to Premium") {
    showPaywall = true
}
.sheet(isPresented: $showPaywall) {
    PaywallView(headline: "Unlock Premium Features")
}

// 3. Gate features
if PremiumManager.shared.isPremium {
    AdvancedFeatureView()
}

// Or use view modifier
AdvancedFeatureView()
    .premiumGated(headline: "Unlock Advanced Features")
```

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
- iOS 26.0+
- Swift 6.2+
- Modern concurrency (async/await)
- @Observable pattern
- No UIKit (unless necessary)
- No third-party dependencies

See [AGENTS.md](AGENTS.md) for complete guidelines.

## 📋 Requirements

- iOS 26.0+
- Swift 6.2+
- Xcode 15+
- StoreKit 2

## 📄 License

*To be determined*

## 🗺️ Next Steps

1. ✅ Investigation complete
2. ✅ Issues created
3. ⏳ Start with Issue #001 (Package foundation)
4. ⏳ Implement core functionality
5. ⏳ Create UI components
6. ⏳ Add tests and documentation
7. ⏳ Release v1.0.0

## 📞 Questions?

Check the issues in `/issues` directory for detailed implementation plans.

---

**Note**: This framework is currently in the planning phase. Implementation will begin shortly. Star and watch this repo to follow progress!
