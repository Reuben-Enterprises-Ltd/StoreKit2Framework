# Best Practices Guide

This guide provides recommendations and best practices for implementing subscriptions with StoreKit2Framework based on industry standards, App Store guidelines, and user experience research.

## Table of Contents

1. [When to Show the Paywall](#when-to-show-the-paywall)
2. [Subscription Pricing Strategy](#subscription-pricing-strategy)
3. [Feature Gating Patterns](#feature-gating-patterns)
4. [User Experience Guidelines](#user-experience-guidelines)
5. [Analytics and Tracking](#analytics-and-tracking)
6. [App Store Guidelines Compliance](#app-store-guidelines-compliance)
7. [Legal Requirements](#legal-requirements)
8. [Security Best Practices](#security-best-practices)
9. [Performance Optimization](#performance-optimization)
10. [Common Mistakes to Avoid](#common-mistakes-to-avoid)

## When to Show the Paywall

### Strategic Timing

**✅ Good Times to Show Paywall:**

1. **After Value Demonstration**
   - User has experienced core features
   - They understand what they're paying for
   - They've achieved initial success with the app

2. **At Natural Limits**
   - User hits their free tier limit (e.g., 5 projects)
   - Tries to access a premium feature
   - Wants to unlock more capacity

3. **During Onboarding (Carefully)**
   - Only after showing value
   - Make it skippable
   - Don't block first-time experience

4. **User-Initiated**
   - User taps "Upgrade" or "Premium"
   - Opens settings
   - Explicitly wants more features

**❌ Bad Times to Show Paywall:**

1. On first app launch (before any value shown)
2. Immediately after previous dismissal
3. During critical user workflows
4. When user is trying to accomplish a specific task
5. Too frequently (avoid paywall fatigue)

### Implementation Example

```swift
struct ContentView: View {
    @State private var showPaywall = false
    @State private var projectCount = 0
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        VStack {
            // Show content
            ProjectListView()
        }
        .onChange(of: projectCount) { oldValue, newValue in
            // Show paywall after hitting free limit
            if newValue >= 5 && !premiumManager.isPremium {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(analyticsSource: "project_limit")
        }
    }
}
```

### Paywall Frequency Best Practices

- **Cooldown Period**: Don't show paywall more than once every 24 hours
- **Dismissal Tracking**: Track how many times user dismissed paywall
- **Progressive Disclosure**: Increase value proposition with each showing
- **Respect User Choice**: If dismissed 3+ times, stop showing proactively

```swift
class PaywallManager {
    private static let lastShownKey = "paywall_last_shown"
    private static let dismissCountKey = "paywall_dismiss_count"
    
    static var canShowPaywall: Bool {
        // Check cooldown period
        if let lastShown = UserDefaults.standard.object(forKey: lastShownKey) as? Date {
            let hoursSinceLastShown = Date().timeIntervalSince(lastShown) / 3600
            if hoursSinceLastShown < 24 {
                return false
            }
        }
        
        // Check dismiss count
        let dismissCount = UserDefaults.standard.integer(forKey: dismissCountKey)
        if dismissCount >= 3 {
            return false
        }
        
        return true
    }
    
    static func recordPaywallShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownKey)
    }
    
    static func recordPaywallDismissed() {
        let currentCount = UserDefaults.standard.integer(forKey: dismissCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: dismissCountKey)
    }
}
```

## Subscription Pricing Strategy

### Recommended Pricing Structure

**Monthly Subscription**
- Base price point
- Allows users to "try" premium
- Higher total cost over time
- Lower commitment barrier
- Example: $4.99/month

**Yearly Subscription** (Recommended)
- Best value for users
- 15-20% discount vs monthly
- Higher LTV per customer
- Example: $39.99/year (save $20 vs monthly)

**Lifetime Purchase** (Optional)
- For highly committed users
- 2-3x yearly price
- One-time payment
- Good for apps with finite feature set
- Example: $99.99 one-time

### Pricing Psychology

```swift
// Display savings prominently
struct PricingDisplay: View {
    let monthlyPrice: Decimal = 4.99
    let yearlyPrice: Decimal = 39.99
    
    var monthlyCostIfYearly: Decimal {
        yearlyPrice / 12
    }
    
    var savings: Decimal {
        (monthlyPrice * 12) - yearlyPrice
    }
    
    var body: some View {
        VStack {
            Text("Yearly Subscription")
                .font(.headline)
            
            Text("$\(monthlyCostIfYearly, format: .number.precision(.fractionLength(2)))/month")
                .font(.title)
            
            Text("Save $\(savings, format: .number) per year!")
                .foregroundStyle(.green)
                .bold()
        }
    }
}
```

### Product Configuration Best Practices

**One Subscription Group**
- All auto-renewable subscriptions in one group
- Enables automatic upgrade/downgrade
- Simpler for users to understand
- Cleaner management in App Store Connect

**Lifetime as Non-Renewing Subscription**
- Part of the subscription group
- Syncs across devices automatically
- Simpler than non-consumable product
- Better for family sharing

## Feature Gating Patterns

### The Three Gating Strategies

#### 1. Hide Completely (.premiumOnly)

**When to Use:**
- Advanced features not relevant to free users
- Power user tools
- Professional features
- Would confuse free users if visible

```swift
NavigationLink("Advanced Analytics") {
    AdvancedAnalyticsView()
}
.premiumOnly()
```

**Pros:**
- Clean UI for free users
- No frustration from seeing locked features
- Clear separation

**Cons:**
- Users don't know what they're missing
- Lower conversion (invisible = ignored)

#### 2. Show with Overlay (.premiumGated)

**When to Use:**
- Features users should know about
- Visual content worth previewing
- Builds desire through preview
- High-value features

```swift
DetailedReportView()
    .premiumGated(headline: "Unlock Detailed Reports")
```

**Pros:**
- Shows value before purchase
- Builds desire
- Higher conversion
- Users understand what they're paying for

**Cons:**
- Can feel restrictive
- Requires careful messaging

#### 3. Disable with Lock Icon (.premiumRequired)

**When to Use:**
- Actions and buttons
- Settings and options
- Features in lists
- Clear premium indicators

```swift
Button("Export to PDF") {
    exportPDF()
}
.premiumRequired()
```

**Pros:**
- Very clear what requires premium
- Doesn't hide features
- Good for discoverability

**Cons:**
- Can frustrate if overused
- UI may look cluttered with many locks

### Balancing Free vs Premium

**The 80/20 Rule:**
- 80% of core functionality: Free
- 20% advanced features: Premium

**Example: Fitness App**

**Free:**
- Log workouts ✅
- Track basic stats ✅
- View last 30 days ✅
- Basic exercises library ✅

**Premium:**
- Advanced analytics 💎
- Unlimited history 💎
- Custom workout plans 💎
- Export data 💎
- Priority support 💎

```swift
struct WorkoutHistoryView: View {
    private let premiumManager = PremiumManager.shared
    let workouts: [Workout]
    
    var displayedWorkouts: [Workout] {
        if premiumManager.isPremium {
            return workouts // Unlimited
        } else {
            return Array(workouts.prefix(30)) // Last 30 days
        }
    }
    
    var body: some View {
        List(displayedWorkouts) { workout in
            WorkoutRow(workout: workout)
        }
        .safeAreaInset(edge: .bottom) {
            if !premiumManager.isPremium && workouts.count > 30 {
                UpgradePromptBanner()
            }
        }
    }
}
```

## User Experience Guidelines

### 1. Free Tier Must Be Functional

**Rule:** Never block core functionality behind paywall.

**✅ Good:**
```swift
// Free users get 5 projects, premium unlimited
let availableProjects = premiumManager.isPremium ? 
    allProjects : Array(allProjects.prefix(5))
```

**❌ Bad:**
```swift
// Core feature completely blocked
guard premiumManager.isPremium else {
    return PaywallView()
}
```

### 2. Use Inviting Language

**Good Examples:**
- "Unlock advanced features"
- "Get unlimited access"
- "Upgrade your experience"
- "Join Premium"

**Bad Examples:**
- "You're missing out!" (guilt-inducing)
- "Limited version" (negative framing)
- "Upgrade to unlock" (implies broken without payment)

### 3. Always Show Restore Button

**Required by App Store:** Users must be able to restore previous purchases.

```swift
PaywallView(
    configuration: .init(
        showRestoreButton: true  // Always true!
    ),
    privacyPolicyURL: privacyURL,
    termsOfServiceURL: termsURL
)
```

### 4. Loading States

Always show loading indicators during async operations:

```swift
struct ProductListView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        Group {
            if premiumManager.isLoading {
                ProgressView("Loading products...")
            } else if premiumManager.products.isEmpty {
                VStack {
                    Text("Unable to load products")
                    Button("Try Again") {
                        Task { await premiumManager.loadProducts() }
                    }
                }
            } else {
                ProductList(products: premiumManager.products)
            }
        }
    }
}
```

### 5. Error Handling

Fail gracefully with user-friendly messages:

```swift
Task {
    do {
        try await premiumManager.purchase(product)
    } catch {
        // User-friendly message
        errorMessage = "Unable to complete purchase. Please check your connection and try again."
        showError = true
        
        // Developer logging
        print("Purchase error: \(error.localizedDescription)")
        
        // Analytics
        analytics.trackPurchaseFailed(error: error)
    }
}
```

## Analytics and Tracking

### Key Events to Track

**Paywall Events:**
```swift
// Track when paywall is shown
analytics.track("paywall_shown", properties: [
    "source": "feature_limit",  // Where it was shown
    "products_shown": 3,
    "user_type": premiumManager.isPremium ? "premium" : "free"
])

// Track when paywall is dismissed
analytics.track("paywall_dismissed", properties: [
    "source": "feature_limit",
    "time_on_screen": 15.3  // seconds
])
```

**Purchase Events:**
```swift
// Track purchase initiation
analytics.track("purchase_initiated", properties: [
    "product_id": product.id,
    "price": product.price,
    "display_name": product.displayName
])

// Track purchase completion
analytics.track("purchase_completed", properties: [
    "product_id": product.id,
    "revenue": product.price,
    "transaction_id": transaction.id
])

// Track purchase failure
analytics.track("purchase_failed", properties: [
    "product_id": product?.id ?? "unknown",
    "error": error.localizedDescription,
    "error_code": (error as NSError).code
])

// Track cancellation
analytics.track("purchase_cancelled", properties: [
    "product_id": product.id
])
```

**Conversion Funnel:**
```swift
// 1. User sees premium feature
analytics.track("premium_feature_viewed", properties: [
    "feature": "advanced_analytics"
])

// 2. User attempts to access (hits paywall)
analytics.track("paywall_triggered", properties: [
    "feature": "advanced_analytics"
])

// 3. User selects product
analytics.track("product_selected", properties: [
    "product_id": product.id
])

// 4. Purchase completes (or fails)
analytics.track("purchase_completed", ...)
```

### Analytics Integration

Use the built-in analytics protocol:

```swift
import StoreKit2Framework
import FirebaseAnalytics  // or your analytics service

class MyAnalytics: PremiumAnalytics {
    func trackPaywallShown(source: String) {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source
        ])
    }
    
    func trackPurchaseCompleted(product: Product) {
        Analytics.logEvent("purchase", parameters: [
            "product_id": product.id,
            "value": product.price as NSNumber,
            "currency": product.priceFormatStyle.currencyCode ?? "USD"
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

## App Store Guidelines Compliance

### Required Elements

#### 1. Privacy Policy

Must include:
- What data you collect
- How you use subscription data
- Whether you share data with third parties
- User rights (access, deletion, etc.)
- Contact information

#### 2. Terms of Service

Must include:
- Subscription terms
- Cancellation policy
- Refund policy
- Auto-renewal terms
- Pricing information

#### 3. In-App Display

Required to show:
- Privacy Policy link
- Terms of Service link
- Restore Purchases button
- Clear pricing
- Subscription duration

```swift
PaywallView(
    privacyPolicyURL: URL(string: "https://yourapp.com/privacy")!,
    termsOfServiceURL: URL(string: "https://yourapp.com/terms")!,
    analyticsSource: "settings"
)
```

### App Review Guidelines

**Do:**
- Use Apple's in-app purchase system (required)
- Display accurate pricing
- Allow users to restore purchases
- Respect user's subscription status
- Handle all edge cases gracefully

**Don't:**
- Redirect to external payment systems
- Mislead users about pricing
- Hide subscription terms
- Auto-renew without clear disclosure
- Make false claims about features

## Legal Requirements

### GDPR Compliance (EU)

If you have EU users:
- Get consent before collecting data
- Allow data export
- Allow data deletion
- Disclose data usage
- Honor user rights

### CCPA Compliance (California)

If you have California users:
- Disclose data collection
- Allow opt-out of data sale
- Allow data deletion
- Respond to user requests within 45 days

### App Store Requirements

- Privacy policy must be publicly accessible
- Terms must be clear and unambiguous
- Pricing must be transparent
- Auto-renewal must be disclosed
- Cancellation must be easy

### Recommendations

1. **Consult Legal Counsel**: These are complex requirements
2. **Use Templates**: Many available online as starting points
3. **Update Regularly**: Laws change, review annually
4. **Track Changes**: Version your policies
5. **User Notifications**: Notify users of material changes

## Security Best Practices

### 1. Always Verify Transactions

The framework does this automatically, but understanding why:

```swift
// Automatic verification in framework
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw PremiumError.failedVerification
    case .verified(let safe):
        return safe
    }
}
```

**Why:** Prevents jailbreak and fraud attempts.

### 2. Never Trust Client-Side State Alone

```swift
// ❌ Bad: Only checking cached state
if UserDefaults.standard.bool(forKey: "isPremium") {
    showPremiumFeature()
}

// ✅ Good: Always verify with App Store
if PremiumManager.shared.isPremium {  // Checks actual entitlements
    showPremiumFeature()
}
```

### 3. Secure Premium Status Cache

```swift
// Framework handles this, but be aware:
// - Cache is just for instant UI
// - Real verification happens asynchronously
// - Never rely solely on cache for critical decisions
```

### 4. Don't Log Sensitive Data

```swift
// ❌ Bad: Logging transaction details
print("Transaction: \(transaction)")

// ✅ Good: Log only what's needed
print("Purchase successful: \(transaction.productID)")
```

### 5. Handle Refunds

The framework monitors refunds automatically:

```swift
// Automatic in framework:
// - Transaction.updates monitors for refunds
// - Premium status updates immediately
// - Features are locked automatically
```

## Performance Optimization

### 1. Initialize Early

```swift
@main
struct YourApp: App {
    init() {
        // Configure immediately
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
}
```

### 2. Cache Premium Status

Framework does this automatically:
- Instant UI updates on launch
- Verified asynchronously in background
- Works offline

### 3. Lazy Load Paywall

```swift
// Don't create paywall until needed
@State private var showPaywall = false

var body: some View {
    content
        .sheet(isPresented: $showPaywall) {
            PaywallView()  // Created only when shown
        }
}
```

### 4. Minimize Product Fetches

```swift
// ✅ Good: Fetch once at initialization
PremiumManager.shared.ensureInitialized()  // Fetches products

// ❌ Bad: Fetching on every view appearance
.onAppear {
    Task { await premiumManager.loadProducts() }
}
```

## Common Mistakes to Avoid

### 1. Blocking Core Features

**❌ Don't:**
```swift
guard premiumManager.isPremium else {
    return PaywallView()
}
return CoreFeatureView()
```

**✅ Do:**
```swift
if premiumManager.isPremium {
    return UnlimitedFeatureView()
} else {
    return LimitedButFunctionalView()
}
```

### 2. Showing Paywall Too Early

**❌ Don't:**
```swift
struct ContentView: View {
    @State private var showPaywall = true  // Immediately on launch
}
```

**✅ Do:**
```swift
struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        content
            .onAppear {
                // Show after user has seen value
                if shouldShowPaywall() {
                    showPaywall = true
                }
            }
    }
}
```

### 3. Not Handling Errors

**❌ Don't:**
```swift
try! await premiumManager.purchase(product)  // Crashes on error
```

**✅ Do:**
```swift
do {
    try await premiumManager.purchase(product)
} catch {
    showError(error)
}
```

### 4. Forgetting Restore Button

**❌ Don't:**
```swift
PaywallView(
    configuration: .init(showRestoreButton: false)  // Violates guidelines!
)
```

**✅ Do:**
```swift
PaywallView(
    configuration: .init(showRestoreButton: true)  // Required!
)
```

### 5. Not Testing Offline

Always test:
- App launch offline
- Purchase attempt offline
- Feature access offline
- Subscription expiry offline

### 6. Hardcoding Product IDs

**❌ Don't:**
```swift
if product.id == "com.myapp.monthly" {  // Brittle
    // ...
}
```

**✅ Do:**
```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .init(
        monthly: "com.myapp.monthly",
        yearly: "com.myapp.yearly"
    )
)

if product.id == config.productIdentifiers.monthly {  // Configurable
    // ...
}
```

## Additional Resources

- **Apple Documentation**: [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- **WWDC Videos**: Search for "StoreKit" on [developer.apple.com/videos](https://developer.apple.com/videos)
- **App Store Review Guidelines**: [Section 3.1 - In-App Purchase](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- **This Framework**: See [INTEGRATION.md](INTEGRATION.md) for implementation details

---

**Remember:** Great subscription experiences are built on value, transparency, and respect for users. Follow these best practices to create a sustainable, user-friendly premium offering. 🚀
