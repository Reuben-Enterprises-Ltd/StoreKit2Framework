# StoreKit2Framework - Demo App

This demo app demonstrates how to integrate and use the StoreKit2Framework in your iOS app. It showcases all major integration patterns, UI components, and best practices.

## 🎯 What's Demonstrated

### 1. Framework Initialization
**File:** `DemoApp.swift`

The app entry point shows the recommended initialization pattern:

```swift
@main
struct DemoApp: App {
    init() {
        // Initialize early to load products and check premium status
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Key Points:**
- Call `PremiumManager.shared.ensureInitialized()` in your app's `init()`
- This starts loading products and checking premium status immediately
- Premium state will be available by the time your views appear

### 2. Onboarding Integration
**File:** `Views/OnboardingView.swift`

Demonstrates how to integrate the paywall in your onboarding flow:

```swift
struct OnboardingView: View {
    @State private var showPaywall = false
    
    var body: some View {
        // Your onboarding content...
        
        Button("Upgrade to Premium") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(headline: "Start Your Premium Journey")
        }
    }
}
```

**Patterns Shown:**
- Multi-page onboarding flow with page indicators
- Strategic paywall placement (on last page)
- "Skip" vs "Upgrade" options
- Smooth dismissal after purchase

### 3. Settings Integration
**File:** `Views/SettingsView.swift`

Shows how to add premium management to your settings screen:

```swift
Form {
    // Drop in the pre-built settings section
    PremiumSettingsSection()
    
    // Your other settings...
}
```

**Features:**
- Premium status display with subscription type
- Upgrade button for free users
- Manage subscription for premium users
- Restore purchases functionality
- Automatic state updates

**Alternative:** Use `PremiumStatusRow()` for a simpler list-based approach.

### 4. Feature Gating Patterns
**File:** `Views/FeatureListView.swift`

Demonstrates all the different ways to gate premium features:

#### Pattern 1: Premium Only (Hidden)
Features are completely hidden from free users:
```swift
AdvancedFeatureView()
    .premiumOnly()
```

#### Pattern 2: Premium Required (Disabled)
Features are visible but disabled with a lock icon:
```swift
Button("Export All Data") {
    exportData()
}
.premiumRequired()
```

#### Pattern 3: Premium Gated (Overlay)
Content is shown but with a blur overlay and unlock prompt:
```swift
PremiumContentView()
    .premiumGated(headline: "Unlock Advanced Features")
```

#### Pattern 4: Manual/Programmatic Gating
For custom logic like usage limits:
```swift
private func handleExport() {
    if premiumManager.isPremium {
        // Unlimited for premium
        performExport()
    } else if exportCount < maxFreeExports {
        // Limited for free users
        performExport()
        exportCount += 1
        
        if exportCount >= maxFreeExports {
            showPaywall = true // Hit limit
        }
    } else {
        showPaywall = true // Already at limit
    }
}
```

### 5. Premium Badge
Show premium status in your navigation:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        PremiumBadge() // Shows "Pro" if premium
    }
}
```

## 📦 Project Structure

```
DemoApp/
├── DemoApp.xcodeproj/          # Xcode project
├── DemoApp/                    # Source code
│   ├── DemoApp.swift          # App entry point
│   ├── Views/
│   │   ├── ContentView.swift       # Main navigation
│   │   ├── OnboardingView.swift    # Onboarding flow
│   │   ├── SettingsView.swift      # Settings with premium management
│   │   └── FeatureListView.swift   # Feature gating examples
│   └── DemoApp.storekit       # StoreKit test configuration
└── README.md                   # This file
```

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0 or later
- iOS 18.0+ deployment target
- Swift 6.0 or later

### Opening the Project

1. **Open the Demo App:**
   ```bash
   cd Examples/DemoApp
   open DemoApp.xcodeproj
   ```

2. **Select a Simulator:**
   - Choose any iOS 18+ simulator
   - Physical devices work too but require code signing

3. **Configure StoreKit Testing:**
   - In Xcode, go to `Product > Scheme > Edit Scheme...`
   - Select the `Run` action
   - Go to the `Options` tab
   - Under `StoreKit Configuration`, select `DemoApp.storekit`

4. **Build and Run:**
   - Press `Cmd+R` or click the Run button
   - The app will launch in the simulator

### Testing Purchases

The demo includes a StoreKit configuration file with test products:

- **Monthly Premium**: $4.99/month
- **Yearly Premium**: $39.99/year (Best Value)
- **Lifetime Premium**: $24.99 (Non-renewing subscription - expires after 10 minutes in DEBUG mode for testing)

> **Note for Testing**: In DEBUG builds, the lifetime subscription automatically expires 10 minutes after purchase. This allows you to test subscription expiration, UI updates, and re-purchase flows without waiting. In production/release builds, the lifetime subscription never expires.

To test purchases in the simulator:

1. Tap any "Upgrade" button to see the paywall
2. Select a subscription tier
3. Tap "Start Premium"
4. In the StoreKit sandbox dialog, tap "Subscribe" or "Buy"
5. The app will immediately reflect your premium status

**Restore Purchases:**
- Tap "Restore Purchases" on the paywall or in settings
- Your previous test purchases will be restored

**Managing Subscriptions:**
- In settings, tap "Manage Subscription" (when premium)
- This opens the App Store subscription management page

## 🎨 UI Components Used

### From StoreKit2Framework

| Component | Purpose | Usage |
|-----------|---------|-------|
| `PaywallView` | Full-screen purchase screen | `.sheet(isPresented:)` |
| `PremiumSettingsSection` | Complete settings section | Inside `Form {}` |
| `PremiumStatusRow` | Simple status row | Inside `List {}` |
| `PremiumBadge` | "Pro" badge indicator | In toolbar or title |
| `.premiumOnly()` | Hide for free users | View modifier |
| `.premiumRequired()` | Disable with lock | View modifier |
| `.premiumGated()` | Blur with overlay | View modifier |

### Custom Components in Demo

| Component | File | Purpose |
|-----------|------|---------|
| `FeatureCard` | FeatureListView.swift | Displays feature with icon and description |
| `OnboardingPageView` | OnboardingView.swift | Individual onboarding page layout |

## 🔍 Code Highlights

### Accessing Premium Status
```swift
private let premiumManager = PremiumManager.shared

var body: some View {
    if premiumManager.isPremium {
        // Premium content
    } else {
        // Free content
    }
}
```

### Showing the Paywall
```swift
@State private var showPaywall = false

Button("Upgrade") {
    showPaywall = true
}
.sheet(isPresented: $showPaywall) {
    PaywallView(
        headline: "Unlock Premium Features", // Optional custom headline
        benefits: [...],                      // Optional custom benefits
        privacyPolicyURL: ...,               // Required for App Store
        termsOfServiceURL: ...               // Required for App Store
    )
}
```

### Strategic Paywall Triggers

1. **Feature Tap**: When user taps locked feature (via `.premiumRequired()`)
2. **Limit Reached**: When free tier limit is exhausted
3. **Settings**: Explicit "Upgrade" button in settings
4. **Onboarding**: During first-run experience
5. **Value Moment**: After user sees value (e.g., after successful free export)

## 📱 Screenshots

### Main Screen
Shows navigation, feature list, and premium badge

### Onboarding Flow
Multi-page onboarding with paywall integration

### Paywall
Beautiful product selection and purchase flow

### Settings
Premium status management and subscription control

### Feature Gating
Examples of different gating patterns in action

## 🎓 Integration Guide

### Step 1: Add Framework to Your Project

**Option A: Local Development (like this demo)**
```swift
// In Xcode:
// 1. File > Add Package Dependencies...
// 2. Click "Add Local..."
// 3. Select the StoreKit2Framework directory
```

**Option B: From GitHub**
```swift
dependencies: [
    .package(url: "https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git", from: "1.0.0")
]
```

### Step 2: Initialize in Your App

```swift
import StoreKit2Framework

@main
struct YourApp: App {
    init() {
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 3: Update Product IDs

In `PremiumManager.swift`, update the product identifiers to match your App Store Connect products:

```swift
public enum ProductIdentifiers {
    public static let monthly = "com.yourcompany.yourapp.monthly"
    public static let yearly = "com.yourcompany.yourapp.yearly"
    public static let lifetime = "com.yourcompany.yourapp.lifetime"
}
```

### Step 4: Add StoreKit Configuration

1. In Xcode, `File > New > File...`
2. Choose `StoreKit Configuration File`
3. Add your products matching the IDs above
4. Select the configuration in your scheme (Edit Scheme > Run > Options)

### Step 5: Implement Gating

Choose the appropriate pattern for each feature:

```swift
// Hide feature completely
PremiumFeature()
    .premiumOnly()

// Show but disable
Button("Premium Action") { }
    .premiumRequired()

// Show with overlay
ContentView()
    .premiumGated()
```

### Step 6: Add Settings Integration

```swift
Form {
    PremiumSettingsSection()
    // Your other settings...
}
```

### Step 7: Test Thoroughly

- Test all purchase flows
- Test restore purchases
- Test subscription management
- Test feature gating
- Test with/without network

## ⚠️ Common Pitfalls & Solutions

### Pitfall 1: Products Not Loading
**Symptom:** Paywall shows "Unable to Load Products"

**Solution:**
- Ensure StoreKit configuration is selected in scheme
- Verify product IDs match exactly
- Check that products are added to the StoreKit config file
- In simulator, products load from config file (no network needed)

### Pitfall 2: Premium Status Not Updating
**Symptom:** Status doesn't change after purchase

**Solution:**
- Make sure you called `ensureInitialized()` in app init
- Premium status is `@Observable` - SwiftUI will update automatically
- For manual checks, use `premiumManager.isPremium`

### Pitfall 3: Paywall Dismisses Before Purchase
**Symptom:** Sheet dismisses but user didn't complete purchase

**Solution:**
- The paywall auto-dismisses on successful purchase
- If user cancels, sheet stays open
- "Maybe Later" button allows manual dismissal

### Pitfall 4: Subscription Management Not Working
**Symptom:** "Manage Subscription" button doesn't work

**Solution:**
- In simulator, opens browser to App Store subscription page
- On device, opens App Store app directly
- Requires actual App Store listing for production

### Pitfall 5: Feature Gating Not Working
**Symptom:** Premium features visible to free users

**Solution:**
- Ensure modifier is applied: `.premiumRequired()` not `.premiumRequired`
- Check that `PremiumManager.shared.ensureInitialized()` is called
- Verify premium status with print: `print(premiumManager.isPremium)`

## 🧪 Testing Checklist

Before shipping, test all these scenarios:

- [ ] App launch and initialization
- [ ] Premium status loads correctly
- [ ] Products load and display
- [ ] Monthly subscription purchase flow
- [ ] Yearly subscription purchase flow
- [ ] Lifetime purchase flow
- [ ] Purchase cancellation
- [ ] Purchase error handling
- [ ] Restore purchases (with previous purchase)
- [ ] Restore purchases (without previous purchase)
- [ ] Subscription management link
- [ ] Premium features unlock after purchase
- [ ] Feature gating works for free users
- [ ] Feature gating works for premium users
- [ ] Paywall dismisses after purchase
- [ ] Settings shows correct status
- [ ] Premium badge appears when premium
- [ ] App works offline (with cached status)
- [ ] Subscription expiration handling
- [ ] Subscription renewal
- [ ] Family sharing (if enabled)

## 📚 Additional Resources

- [StoreKit2Framework Documentation](../../README.md)
- [Quick Start Guide](../../QUICK_START.md)
- [Premium Manager Usage](../../PREMIUM_MANAGER_USAGE.md)
- [Paywall View Usage](../../PAYWALL_VIEW_USAGE.md)
- [Feature Gating Usage](../../FEATURE_GATING_USAGE.md)
- [Testing Guide](../../TESTING_GUIDE.md)

## 💡 Tips & Best Practices

### 1. Initialize Early
Always call `ensureInitialized()` in your app's `init()`, not in a view's `onAppear`.

### 2. Show Value First
Don't immediately show a paywall. Let users experience your app first.

### 3. Strategic Timing
Show paywalls at natural moments:
- After completing onboarding
- When attempting to use premium feature
- After hitting free tier limit
- On settings screen (explicit user action)

### 4. Clear Benefits
Always communicate value. Use custom benefits for different contexts:
```swift
PaywallView(
    headline: "Export All Your Data",
    benefits: [
        BenefitItem(icon: "arrow.up.doc", title: "Unlimited Exports", description: "...")
    ]
)
```

### 5. Handle Errors Gracefully
The framework handles most errors automatically, but always test:
- Network failures
- App Store connectivity issues
- Receipt verification problems
- Subscription status edge cases

### 6. Test with Real Accounts
Before shipping:
- Test on physical device
- Use TestFlight with test subscriptions
- Test subscription management
- Test family sharing (if enabled)

### 7. Respect User Choice
- Always provide a "Maybe Later" or "Skip" option
- Don't be aggressive with paywall frequency
- Make free tier genuinely useful

### 8. Monitor Metrics
Track:
- Paywall presentation count
- Conversion rate
- Feature usage by tier
- Retention by tier

## 🐛 Troubleshooting

### Build Errors

**"No such module 'StoreKit2Framework'"**
- Ensure the package is added to your project
- Check that the framework target is selected in your scheme
- Clean build folder (Cmd+Shift+K) and rebuild

**"Cannot find 'PremiumManager' in scope"**
- Add `import StoreKit2Framework` at the top of your file
- Verify the framework is properly linked

### Runtime Issues

**Products showing $0.00**
- Normal in simulator with StoreKit configuration
- Real prices appear in TestFlight and production

**Premium status always false**
- Check that `ensureInitialized()` is called
- Verify StoreKit configuration is selected
- Check product IDs match

**Paywall not dismissing after purchase**
- This is automatic - if not working, check for errors in console
- Ensure you're not preventing dismissal with custom code

## 📄 License

This demo app and the StoreKit2Framework are available under the MIT License. See the main repository LICENSE file for details.

## 🤝 Contributing

Found an issue or want to improve the demo? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/discussions)

---

**Happy Coding! 🚀**

This demo demonstrates everything you need to successfully integrate in-app purchases into your iOS app using the StoreKit2Framework.
