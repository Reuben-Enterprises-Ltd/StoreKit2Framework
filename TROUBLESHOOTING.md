# Troubleshooting Guide

This guide helps you diagnose and fix common issues when using StoreKit2Framework. Each issue includes symptoms, root causes, and step-by-step solutions.

## Table of Contents

1. [Products Don't Load](#products-dont-load)
2. [Purchases Don't Persist](#purchases-dont-persist)
3. [UI Doesn't Update](#ui-doesnt-update)
4. [Restore Doesn't Work](#restore-doesnt-work)
5. [Subscription Conflicts](#subscription-conflicts)
6. [Sandbox Testing Issues](#sandbox-testing-issues)
7. [Build and Configuration Issues](#build-and-configuration-issues)
8. [Performance Issues](#performance-issues)
9. [Error Messages](#error-messages)

## Products Don't Load

### Symptom
- Empty products array
- Paywall shows no purchase options
- Products array is always empty
- "No products available" message

### Possible Causes

#### 1. StoreKit Configuration Not Selected (Simulator)

**Check:**
```swift
print("Products count: \(PremiumManager.shared.products.count)")
print("Loading: \(PremiumManager.shared.isLoading)")
```

**Solution:**
1. In Xcode: **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options**
3. Under **StoreKit Configuration**, select `Configuration.storekit`
4. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
5. Run again

#### 2. Product IDs Don't Match

**Check:**
```swift
// Print your configured product IDs
let config = PremiumManager.shared.currentConfiguration
print("Monthly ID: \(config.productIdentifiers.monthly)")
print("Yearly ID: \(config.productIdentifiers.yearly)")

// Compare with StoreKit configuration file
// Should match exactly (case-sensitive)
```

**Solution:**
1. Open `Configuration.storekit` file
2. Verify product IDs match **exactly**:
   - Case-sensitive
   - No extra spaces
   - Correct format: `com.company.app.productname`
3. Update either your code or .storekit file to match

#### 3. Products Not "Ready to Submit" (Production)

**Check in App Store Connect:**
- Go to your app → Features → In-App Purchases
- Check status of each product

**Solution:**
1. Ensure all required fields are filled:
   - Display name
   - Description
   - Price
   - Review screenshot (if required)
2. Submit for review if needed
3. Wait for "Ready to Submit" or "Approved" status

#### 4. Network Issues

**Check:**
```swift
Task {
    do {
        try await PremiumManager.shared.loadProducts()
        print("Products loaded successfully")
    } catch {
        print("Load error: \(error)")
    }
}
```

**Solution:**
- Check internet connection
- Try on different network
- Restart device
- Check Apple System Status: [apple.com/support/systemstatus](https://www.apple.com/support/systemstatus/)

#### 5. Not Initialized

**Check:**
```swift
// Ensure initialization happened
print("Manager initialized: \(PremiumManager.shared.isInitialized)")
```

**Solution:**
```swift
// In your App struct
@main
struct YourApp: App {
    init() {
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()  // Must call this!
    }
}
```

## Purchases Don't Persist

### Symptom
- User purchases successfully
- Premium status shows active
- After app restart, premium status is lost
- Subscription doesn't persist across launches

### Possible Causes

#### 1. Cache Not Updating

**Check:**
```swift
// Check if cache is being written
print("isPremium: \(PremiumManager.shared.isPremium)")
print("Cache key: \(PremiumManager.shared.currentConfiguration.cacheKey)")

// Check UserDefaults
let cacheKey = PremiumManager.shared.currentConfiguration.cacheKey
let cached = UserDefaults.standard.bool(forKey: cacheKey)
print("Cached value: \(cached)")
```

**Solution:**
Ensure you're using a unique cache key:
```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    cacheKey: "your_unique_app_premium_status"  // Must be unique!
)
```

#### 2. Transaction Not Finished

The framework handles this automatically, but check:
```swift
// Verify transaction is being finished
// Check console for: "Transaction finished: [product_id]"
```

**Solution:**
Update to latest framework version, as this is handled automatically.

#### 3. Background Listener Not Running

**Check:**
```swift
// Ensure ensureInitialized() was called
PremiumManager.shared.ensureInitialized()
```

**Solution:**
Call `ensureInitialized()` in app initialization:
```swift
@main
struct YourApp: App {
    init() {
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()  // Starts listener
    }
}
```

#### 4. Sandbox Account Issues

**Check:**
- Using correct sandbox account
- Account has valid payment method
- Account isn't expired

**Solution:**
1. Settings → App Store → Sign Out
2. Run app from Xcode
3. When prompted, sign in with sandbox account
4. Complete purchase
5. Restart app to verify persistence

## UI Doesn't Update

### Symptom
- Premium status changes but UI stays the same
- Need to restart app to see changes
- Manual refresh required
- Views don't react to status changes

### Possible Causes

#### 1. Not Using Observable Pattern

**Check:**
```swift
// ❌ Wrong - creates new instance
let premiumManager = PremiumManager()

// ✅ Correct - uses shared instance
private let premiumManager = PremiumManager.shared
```

**Solution:**
Always use `.shared` instance:
```swift
struct MyView: View {
    private let premiumManager = PremiumManager.shared  // Always use .shared!
    
    var body: some View {
        if premiumManager.isPremium {
            Text("Premium user")
        }
    }
}
```

#### 2. Accessing from Wrong Actor

**Check:**
```swift
// PremiumManager is @MainActor
// Ensure you're accessing from main actor context
```

**Solution:**
```swift
Task { @MainActor in
    // Access premium manager here
    if PremiumManager.shared.isPremium {
        // ...
    }
}
```

#### 3. Not Declared Correctly in View

**Check:**
```swift
// ❌ Wrong - breaks observation
@State private var premiumManager = PremiumManager.shared

// ✅ Correct
private let premiumManager = PremiumManager.shared
```

**Solution:**
Use `let`, not `@State`:
```swift
struct MyView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        // Will update automatically
        Text(premiumManager.isPremium ? "Premium" : "Free")
    }
}
```

#### 4. Caching Premium Status in View

**Check:**
```swift
// ❌ Wrong - caches value
let isPremium = PremiumManager.shared.isPremium

// ✅ Correct - always checks current value
if premiumManager.isPremium {
    // ...
}
```

**Solution:**
Always read property directly, don't cache it.

## Restore Doesn't Work

### Symptom
- Restore button does nothing
- Restore completes but premium not granted
- "Nothing to restore" message
- Works on original device but not on new device

### Possible Causes

#### 1. Using Different Apple ID

**Check:**
- User is signed in with same Apple ID that made purchase
- Not using Family Sharing (unless enabled)

**Solution:**
1. Settings → App Store → check Apple ID
2. Must match account used for original purchase
3. If wrong account, sign out and sign in with correct one

#### 2. Purchase Was Refunded

**Check in App Store Connect:**
- Sales and Trends → Subscriptions
- Look for refunds

**Solution:**
If refunded, user must purchase again. Restore won't work.

#### 3. Subscription Expired

**Check:**
```swift
// Verify current entitlements
for await result in Transaction.currentEntitlements {
    print("Entitlement: \(result)")
}
```

**Solution:**
If subscription expired, user must renew. Restore only works for active subscriptions.

#### 4. Sandbox Testing Cache

**Check:**
In sandbox, sometimes cache gets confused.

**Solution:**
```bash
# Delete app completely
# Reinstall from Xcode
# Try restore again
```

#### 5. Wrong Environment

**Check:**
- Production app trying to restore sandbox purchases (won't work)
- Sandbox app trying to restore production purchases (won't work)

**Solution:**
Ensure testing in correct environment (sandbox vs production).

## Subscription Conflicts

### Symptom
- Can't purchase yearly after buying monthly
- Error: "Already subscribed"
- User has multiple active subscriptions
- Upgrade/downgrade doesn't work

### Possible Causes

#### 1. Different Subscription Groups

**Check in App Store Connect:**
- Your App → Features → In-App Purchases
- Select each subscription
- Verify they're in the **same** subscription group

**Solution:**
1. All subscriptions must be in same group
2. Move products to same group if needed
3. Test again after 24 hours (group changes take time)

#### 2. Family Sharing Conflict

**Check:**
- User might have subscription through family sharing
- Can't purchase if already accessing via family

**Solution:**
User must either:
- Use family shared subscription, or
- Leave family sharing to purchase individually

#### 3. Promotional Offer Already Used

**Check:**
- User might have already used introductory offer
- Can't use intro offer twice

**Solution:**
Show regular pricing for users who already used offer.

## Sandbox Testing Issues

### Symptom
- Can't sign in with sandbox account
- "Account invalid" error
- Purchases complete but disappear
- Subscriptions expire immediately

### Common Sandbox Problems

#### 1. Sandbox Account Creation

**Issue:** Account doesn't work

**Solution:**
1. Go to App Store Connect → Users and Access → Sandbox Testers
2. Create new tester (use unique email)
3. Don't verify email (sandbox accounts don't need verification)
4. Use immediately in testing

#### 2. Sandbox Account Conflicts

**Issue:** "Account already in use"

**Solution:**
1. Settings → App Store → Sign Out
2. Delete app completely
3. Reinstall from Xcode
4. Sign in with sandbox account when prompted

#### 3. Rapid Subscription Renewals

**Issue:** Subscriptions renew too quickly in sandbox

**Expected Behavior:**
- 1 week subscription → 3 minutes in sandbox
- 1 month subscription → 5 minutes in sandbox
- 1 year subscription → 1 hour in sandbox

**Solution:**
This is normal! Sandbox accelerates time for testing.

#### 4. Subscription Interruptions

**Issue:** Subscription fails to renew in sandbox

**Expected Behavior:**
- Sandbox subscriptions auto-renew 6 times then stop
- This tests subscription interruption handling

**Solution:**
This is intentional for testing. Start fresh purchase to test again.

## Build and Configuration Issues

### Symptom
- App won't compile
- "Module not found" errors
- Framework import fails
- Type errors with PremiumManager

### Common Build Issues

#### 1. Framework Not Added to Target

**Check:**
- Xcode → Target → Frameworks, Libraries, and Embedded Content
- StoreKit2Framework should be listed

**Solution:**
1. File → Add Package Dependencies
2. Add StoreKit2Framework
3. Select your target
4. Build

#### 2. Minimum Deployment Target

**Check:**
```swift
// Deployment target must be iOS 18.0+
```

**Solution:**
1. Select project in Xcode
2. Select target
3. General → Deployment Info → iOS Deployment Target
4. Set to 18.0 or higher

#### 3. Swift Version Mismatch

**Check:**
```swift
// Project requires Swift 6.2+
```

**Solution:**
1. Xcode → Preferences → Locations
2. Ensure using Xcode 16+
3. Build Settings → Swift Language Version
4. Set to Swift 6

#### 4. Configuration Errors

**Check:**
```swift
do {
    let config = PremiumManager.Configuration(...)
    try config.validate()
} catch {
    print("Configuration error: \(error)")
}
```

**Solution:**
Fix validation errors:
- Empty product IDs
- Invalid format (must contain '.')
- Duplicate product IDs
- Empty cache key

## Performance Issues

### Symptom
- Slow app launch
- UI lag when checking premium status
- Delayed product loading
- Memory issues

### Performance Problems

#### 1. Blocking Main Thread

**Check:**
```swift
// ❌ Wrong - blocks UI
let products = await PremiumManager.shared.loadProducts()

// ✅ Correct - non-blocking
Task {
    await PremiumManager.shared.loadProducts()
}
```

**Solution:**
Use async/await properly and don't block main thread.

#### 2. Fetching Products Too Often

**Check:**
```swift
// ❌ Wrong - fetches every time
.onAppear {
    Task { await premiumManager.loadProducts() }
}

// ✅ Correct - fetches once at init
PremiumManager.shared.ensureInitialized()
```

**Solution:**
Products are fetched once at initialization. Don't fetch repeatedly.

#### 3. Creating Multiple PaywallViews

**Check:**
```swift
// ❌ Wrong - creates view immediately
let paywall = PaywallView()

// ✅ Correct - creates only when shown
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

**Solution:**
Use lazy loading with sheets/fullScreenCovers.

## Error Messages

### "Failed to load products"

**Possible Causes:**
1. No internet connection
2. App Store services down
3. Invalid product IDs
4. StoreKit configuration not selected

**Solution:**
See [Products Don't Load](#products-dont-load)

### "Purchase failed"

**Possible Causes:**
1. User cancelled
2. Payment method declined
3. Network error
4. App Store issue

**Solution:**
```swift
do {
    try await premiumManager.purchase(product)
} catch {
    // Log specific error
    print("Purchase error: \(error)")
    print("Error code: \((error as NSError).code)")
    
    // Show user-friendly message
    showError("Unable to complete purchase. Please try again.")
}
```

### "Failed verification"

**Cause:**
Transaction failed Apple's verification (possible fraud attempt)

**Solution:**
This is security working correctly. Don't grant premium access. Log for investigation.

### "Configuration invalid"

**Possible Causes:**
1. Empty product ID
2. Invalid product ID format
3. Duplicate product IDs

**Solution:**
```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .init(
        monthly: "com.company.app.monthly",  // Must contain '.'
        yearly: "com.company.app.yearly"      // Must be unique
    ),
    features: []
)

do {
    try config.validate()
} catch {
    print("Configuration error: \(error)")
    // Fix the configuration
}
```

## Getting More Help

### Enable Debug Mode

```swift
let config = PremiumManager.Configuration(
    productIdentifiers: .default,
    features: [],
    enableDebugMode: true  // Enables verbose logging
)
```

### Check Console Output

Look for framework log messages:
- "PremiumManager initialized"
- "Products loaded: X"
- "Transaction finished: [product_id]"
- "Premium status updated: true/false"

### Verify Configuration

```swift
// Print current configuration
let config = PremiumManager.shared.currentConfiguration
print("Monthly ID: \(config.productIdentifiers.monthly)")
print("Yearly ID: \(config.productIdentifiers.yearly)")
print("Features count: \(config.features.count)")
print("Cache key: \(config.cacheKey)")
```

### Test in Isolation

Create minimal test case:
```swift
import SwiftUI
import StoreKit2Framework

@main
struct TestApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.test.monthly",
                yearly: "com.test.yearly"
            ),
            features: [],
            enableDebugMode: true
        )
        PremiumManager.shared.configure(config)
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}

struct TestView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        VStack {
            Text("Premium: \(premiumManager.isPremium.description)")
            Text("Products: \(premiumManager.products.count)")
            Text("Loading: \(premiumManager.isLoading.description)")
            
            Button("Show Paywall") {
                // Test paywall
            }
        }
    }
}
```

### Still Stuck?

1. **Check Example App**: `Examples/DemoApp` has working implementation
2. **Review Documentation**: 
   - [INTEGRATION.md](INTEGRATION.md)
   - [BEST_PRACTICES.md](BEST_PRACTICES.md)
   - [API_REFERENCE.md](API_REFERENCE.md)
3. **Search Issues**: [GitHub Issues](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/issues)
4. **Open New Issue**: Include:
   - Framework version
   - Xcode version
   - iOS version
   - Minimal reproduction code
   - Console output
   - Steps to reproduce

---

**Most issues are configuration-related.** Double-check your product IDs, StoreKit configuration, and initialization code first. 🔍
