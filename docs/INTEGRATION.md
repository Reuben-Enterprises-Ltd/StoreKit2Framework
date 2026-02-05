# Complete Integration Guide

This guide provides detailed, step-by-step instructions for integrating StoreKit2Framework into your iOS app. Follow this guide to implement a complete, production-ready subscription system.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [App Store Connect Setup](#app-store-connect-setup)
4. [Basic Configuration](#basic-configuration)
5. [Core Implementation](#core-implementation)
6. [UI Integration](#ui-integration)
7. [Feature Gating](#feature-gating)
8. [Testing](#testing)
9. [Production Checklist](#production-checklist)
10. [Advanced Features](#advanced-features)

## Prerequisites

Before you begin, ensure you have:

- **Xcode 16.0+** installed
- **iOS 18.0+** deployment target
- **Swift 6.2+** enabled in your project
- An **active Apple Developer Program membership**
- Basic understanding of **SwiftUI** and **async/await**

## Installation

### Adding the Package

#### Option 1: Xcode (Recommended)

1. Open your project in Xcode
2. Select **File** → **Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git
   ```
4. Select version requirements (recommend "Up to Next Major Version")
5. Click **Add Package**
6. Confirm the package is added to your target

#### Option 2: Package.swift

Add to your package dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git",
        from: "1.0.0"
    )
]
```

Then add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["StoreKit2Framework"]
)
```

### Verify Installation

Build your project to verify the package is correctly installed:

```bash
# Command line
swift build

# Or in Xcode
⌘B (Command + B)
```

## App Store Connect Setup

### 1. Create In-App Purchase Products

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app (or create a new one)
3. Navigate to **Features** → **In-App Purchases**
4. Click **+** to create a new subscription group
5. Name your group (e.g., "Premium Subscriptions")
6. Add subscriptions to the group:

#### Monthly Subscription
- **Reference Name**: Monthly Premium
- **Product ID**: `com.yourcompany.yourapp.monthly`
- **Subscription Duration**: 1 month
- **Price**: Your chosen price (e.g., $4.99)

#### Yearly Subscription
- **Reference Name**: Yearly Premium
- **Product ID**: `com.yourcompany.yourapp.yearly`
- **Subscription Duration**: 1 year
- **Price**: Your chosen price (e.g., $39.99)

#### Lifetime (Optional)
- **Reference Name**: Lifetime Premium
- **Product ID**: `com.yourcompany.yourapp.lifetime`
- **Type**: Non-Renewing Subscription
- **Duration**: 1 year (technical requirement, but treated as lifetime in app)
- **Price**: Your chosen price (e.g., $99.99)

### 2. Configure Subscription Group

1. Ensure all subscriptions are in the **same subscription group**
2. Set upgrade/downgrade behavior
3. Configure family sharing (optional)
4. Set promotional offers (optional)

### 3. Add Legal Information

⚠️ **Required for App Store approval:**

1. **Privacy Policy URL**: Create and host a privacy policy
2. **Terms of Service URL**: Create and host terms of service
3. Add these URLs in App Store Connect under your app's information

## Basic Configuration

### Step 1: Create Configuration

Create your configuration as early as possible in your app's lifecycle:

```swift
import SwiftUI
import StoreKit2Framework

@main
struct YourApp: App {
    init() {
        configureFramework()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureFramework() {
        // Create configuration with your product IDs
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.yourcompany.yourapp.monthly",
                yearly: "com.yourcompany.yourapp.yearly",
                lifetime: "com.yourcompany.yourapp.lifetime"
            ),
            features: [
                .init(title: "Unlimited Access", systemImageName: "infinity"),
                .init(title: "Cloud Sync", systemImageName: "icloud.fill"),
                .init(title: "Premium Themes", systemImageName: "paintpalette.fill"),
                .init(title: "Priority Support", systemImageName: "person.fill.questionmark"),
                .init(title: "Ad-Free Experience", systemImageName: "eye.slash.fill"),
            ],
            enableDebugMode: false,
            cacheKey: "your_app_premium_status"
        )
        
        // Apply configuration and initialize
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
}
```

### Step 2: Important Configuration Notes

**Timing**: Configuration must happen before `ensureInitialized()` is called.

**Product IDs**: Must match exactly what you created in App Store Connect (case-sensitive).

**Features**: These appear in your paywall. Choose 3-5 compelling benefits.

**Cache Key**: Must be unique to your app. Used for storing premium status offline.

## Core Implementation

### Understanding Premium Status

The framework provides a reactive `isPremium` property that automatically updates throughout your app:

```swift
import StoreKit2Framework

struct MyView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            Text("You have premium access!")
        } else {
            Text("Upgrade to premium")
        }
    }
}
```

### Key PremiumManager Methods

#### ensureInitialized()
Initializes the framework and starts monitoring transactions. Call once at app launch.

```swift
PremiumManager.shared.ensureInitialized()
```

#### loadProducts()
Manually refresh products from App Store. Usually not needed as this happens automatically.

```swift
Task {
    await premiumManager.loadProducts()
}
```

#### purchase(_:)
Purchase a specific product.

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
Restore previous purchases.

```swift
Task {
    await premiumManager.restorePurchases()
}
```

## UI Integration

### 1. Paywall Implementation

The simplest way to show a paywall:

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
                privacyPolicyURL: URL(string: "https://yourapp.com/privacy")!,
                termsOfServiceURL: URL(string: "https://yourapp.com/terms")!,
                analyticsSource: "main_screen"
            )
        }
    }
}
```

### 2. Customizing the Paywall

Use `PaywallConfiguration` for advanced customization:

```swift
let config = PaywallConfiguration(
    headline: "Unlock Your Full Potential",
    features: [
        .init(title: "Custom Feature 1", systemImageName: "star.fill"),
        .init(title: "Custom Feature 2", systemImageName: "bolt.fill"),
    ],
    showRestoreButton: true,
    showPrivacyLinks: true,
    tintColor: .purple
)

PaywallView(
    configuration: config,
    privacyPolicyURL: privacyURL,
    termsOfServiceURL: termsURL,
    analyticsSource: "onboarding"
)
```

### 3. Settings Integration

Add a premium settings section to your settings screen:

```swift
import SwiftUI
import StoreKit2Framework

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                // Automatic premium settings section
                PremiumSettingsSection()
                
                // Your other settings
                Section("General") {
                    NavigationLink("Notifications") {
                        NotificationSettingsView()
                    }
                    NavigationLink("Privacy") {
                        PrivacySettingsView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

### 4. Compact Premium Status Display

For displaying status in other contexts:

```swift
List {
    PremiumStatusRow()
    
    // Other list items
}
```

Or use the badge:

```swift
Text("Pro Features")
    .badge(PremiumBadge())
```

## Feature Gating

Feature gating lets you lock content behind premium subscriptions.

### Pattern 1: Hide Completely (.premiumOnly)

Removes the view entirely for free users:

```swift
NavigationLink("Advanced Analytics") {
    AdvancedAnalyticsView()
}
.premiumOnly()
```

### Pattern 2: Show with Overlay (.premiumGated)

Blurs the content and shows a paywall button:

```swift
PremiumContentView()
    .premiumGated(headline: "Unlock Premium Features")
```

### Pattern 3: Disable with Lock Icon (.premiumRequired)

Disables interaction and shows a lock icon:

```swift
Button("Export All Data") {
    exportData()
}
.premiumRequired()
```

### Pattern 4: Custom Gating

For complete control:

```swift
struct CustomFeature: View {
    private let premiumManager = PremiumManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        if premiumManager.isPremium {
            // Premium content
            FullFeatureView()
        } else {
            // Free user view
            VStack {
                Text("This feature requires premium")
                Button("Upgrade") {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(analyticsSource: "custom_feature")
            }
        }
    }
}
```

### Best Practices for Feature Gating

1. **Be Clear**: Always explain why a feature is locked
2. **Easy Upgrade**: Provide an obvious upgrade path
3. **Graceful**: Don't frustrate users with too many locks
4. **Value First**: Show free value before asking for payment
5. **Context**: Use analytics source to understand conversion

## Testing

### Local Testing with StoreKit Configuration

1. The framework includes a `Configuration.storekit` file for testing
2. In Xcode, select your scheme: **Product** → **Scheme** → **Edit Scheme**
3. Under **Run** → **Options**, enable **StoreKit Configuration**
4. Select `Configuration.storekit` from the package
5. Run your app in Simulator

You can now test purchases without real money or sandbox accounts.

### Debug Mode

Enable premium instantly during development:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    enableDebugMode: true  // Enables extra logging
)
```

Or use the environment variable:

```bash
# In Xcode: Edit Scheme → Run → Arguments
# Add Environment Variable:
PREMIUM_ENABLED = true
```

### Sandbox Testing

For testing on real devices:

1. Create a sandbox tester account in App Store Connect
2. Sign out of your real Apple ID on the device
3. Run your app from Xcode
4. When prompted for Apple ID, use your sandbox account
5. Test purchase flows with fake payment

### Testing Checklist

- [ ] Products load correctly
- [ ] Monthly subscription purchase works
- [ ] Yearly subscription purchase works
- [ ] Lifetime purchase works (if enabled)
- [ ] Restore purchases works on fresh install
- [ ] Premium status persists after app restart
- [ ] Premium status updates in real-time
- [ ] Paywall dismisses after successful purchase
- [ ] Error messages display correctly
- [ ] Feature gating works as expected
- [ ] Settings UI shows correct status
- [ ] Subscription management link works

## Production Checklist

Before submitting to the App Store:

### Code Checklist
- [ ] All product IDs match App Store Connect exactly
- [ ] Privacy Policy URL is valid and accessible
- [ ] Terms of Service URL is valid and accessible
- [ ] Debug mode is disabled (`enableDebugMode: false`)
- [ ] All features are properly gated
- [ ] Error handling is comprehensive
- [ ] No forced unwraps or force tries in production code

### App Store Connect Checklist
- [ ] All IAP products are "Ready to Submit"
- [ ] Subscription group is properly configured
- [ ] Product descriptions are complete
- [ ] Screenshots are uploaded
- [ ] Pricing is set for all territories
- [ ] Legal URLs are added to App Store listing

### Testing Checklist
- [ ] Tested with sandbox account
- [ ] Tested on real device
- [ ] Tested all purchase flows
- [ ] Tested restore functionality
- [ ] Tested offline behavior
- [ ] Tested subscription upgrades/downgrades
- [ ] Tested family sharing (if enabled)

### Documentation Checklist
- [ ] App Store description mentions subscriptions
- [ ] Privacy policy covers subscription data
- [ ] Terms of service cover subscription terms
- [ ] Support contact info is provided

## Advanced Features

### Analytics Integration

Track premium events with your analytics service:

```swift
import StoreKit2Framework

class MyAnalytics: PremiumAnalytics {
    func trackPaywallShown(source: String) {
        // Your analytics service
        Analytics.log("paywall_shown", parameters: ["source": source])
    }
    
    func trackPurchaseCompleted(product: Product) {
        Analytics.log("purchase_completed", parameters: [
            "product_id": product.id,
            "price": product.displayPrice
        ])
    }
    
    func trackPurchaseFailed(product: Product?, error: Error) {
        Analytics.log("purchase_failed", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    func trackPurchaseCancelled(product: Product) {
        Analytics.log("purchase_cancelled")
    }
    
    func trackRestorePurchases(success: Bool) {
        Analytics.log("restore_purchases", parameters: ["success": success])
    }
}

// Configure with analytics
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    analytics: MyAnalytics()
)
```

### Offline Grace Period

Configure how long premium features remain accessible offline:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    offlineGracePeriod: 86400 // 24 hours in seconds
)
```

### Promotional Offers

Enable support for promotional and introductory offers:

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    enablePromotionalOffers: true
)
```

## Common Patterns

### Onboarding with Paywall

```swift
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage1().tag(0)
            OnboardingPage2().tag(1)
            OnboardingPage3().tag(2)
        }
        .tabViewStyle(.page)
        .overlay(alignment: .bottom) {
            if currentPage == 2 {
                Button("Get Started") {
                    showPaywall = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(analyticsSource: "onboarding")
        }
    }
}
```

### Conditional Feature Access

```swift
struct ContentView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        List {
            Section("Basic Features") {
                BasicFeature1()
                BasicFeature2()
            }
            
            Section("Premium Features") {
                PremiumFeature1()
                    .premiumRequired()
                PremiumFeature2()
                    .premiumRequired()
            }
        }
    }
}
```

### Time-Limited Trial

```swift
struct TrialManager {
    static var trialStartDate: Date? {
        get { UserDefaults.standard.object(forKey: "trial_start") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "trial_start") }
    }
    
    static var isInTrial: Bool {
        guard let startDate = trialStartDate else {
            // First launch - start trial
            trialStartDate = Date()
            return true
        }
        
        let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: Date()
        ).day ?? 0
        
        return daysSinceStart < 7 // 7-day trial
    }
    
    static var hasAccess: Bool {
        PremiumManager.shared.isPremium || isInTrial
    }
}
```

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Next Steps

- Read [BEST_PRACTICES.md](BEST_PRACTICES.md) for optimization tips
- Review [API_REFERENCE.md](API_REFERENCE.md) for complete API documentation
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you encounter issues
- See the example app in `Examples/DemoApp` for a complete implementation

## Support

- **Issues**: [GitHub Issues](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/issues)
- **Documentation**: See other guides in this repository
- **Example App**: `Examples/DemoApp` contains a complete working example

---

**Congratulations!** You've successfully integrated StoreKit2Framework into your app. 🎉
