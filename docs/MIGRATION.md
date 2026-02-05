# Migration Guide

This guide helps you migrate existing StoreKit implementations to StoreKit2Framework. Whether you're using StoreKit 1, another StoreKit 2 wrapper, or custom StoreKit 2 code, this guide will help you transition smoothly.

## Table of Contents

1. [Why Migrate?](#why-migrate)
2. [Migration Overview](#migration-overview)
3. [From StoreKit 1](#from-storekit-1)
4. [From Custom StoreKit 2](#from-custom-storekit-2)
5. [From Other Frameworks](#from-other-frameworks)
6. [Step-by-Step Migration](#step-by-step-migration)
7. [Testing Your Migration](#testing-your-migration)
8. [Rollback Plan](#rollback-plan)

## Why Migrate?

### Benefits of StoreKit2Framework

- **Modern Swift Concurrency**: Uses async/await instead of completion handlers
- **Observable Pattern**: Automatic UI updates with `@Observable`
- **Simplified API**: Less boilerplate, clearer intent
- **Better Security**: Automatic transaction verification
- **Offline Support**: Cached premium status for instant access
- **Type Safety**: Swift 6.2 strict concurrency compliance
- **Tested**: Comprehensive test coverage and proven reliability
- **Maintained**: Active development and support

### When to Migrate

✅ **Good times to migrate:**
- Starting a new feature or redesign
- Modernizing legacy code
- Having StoreKit-related bugs
- Wanting better testability
- Upgrading to iOS 18+

⚠️ **Consider delaying if:**
- About to submit a critical release
- Limited testing resources available
- App has complex custom StoreKit logic that works well
- Need to support iOS < 18

## Migration Overview

### High-Level Steps

1. **Install** StoreKit2Framework via Swift Package Manager
2. **Configure** product IDs and features
3. **Replace** old StoreKit manager with PremiumManager
4. **Update** UI components to use framework views
5. **Remove** old code and dependencies
6. **Test** thoroughly with all subscription types
7. **Deploy** gradually with feature flags (recommended)

### Estimated Time

- **Simple apps** (basic subscriptions): 2-4 hours
- **Medium apps** (multiple products, custom UI): 4-8 hours
- **Complex apps** (family sharing, promotional offers): 8-16 hours

## From StoreKit 1

StoreKit 1 uses older patterns like `SKProductsRequest`, `SKPaymentQueue`, and delegates. Here's how to migrate:

### Old StoreKit 1 Pattern

```swift
// Old code
import StoreKit

class IAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = IAPManager()
    private var products: [SKProduct] = []
    var isPremium = false
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: ["com.app.premium"])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
    
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                isPremium = true
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
```

### New StoreKit2Framework Pattern

```swift
// New code
import StoreKit2Framework

// In your App struct
@main
struct YourApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.app.premium.monthly",
                yearly: "com.app.premium.yearly",
                lifetime: "com.app.premium.lifetime"
            ),
            features: [
                .init(title: "Premium Features", systemImageName: "star.fill")
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

// In your views
struct MyView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            Text("Premium User")
        }
    }
}
```

### Key Changes

| StoreKit 1 | StoreKit2Framework |
|------------|-------------------|
| `SKProduct` | `Product` (StoreKit 2 native) |
| `SKPaymentQueue` | Handled automatically |
| `SKProductsRequest` | `loadProducts()` method |
| Delegates | async/await |
| Manual transaction finishing | Automatic |
| `NSObject` inheritance | Not required |
| Manual receipt validation | Automatic verification |

### Migration Checklist

- [ ] Remove `SKPaymentQueue.default().add(self)` observers
- [ ] Delete `SKProductsRequestDelegate` conformance
- [ ] Delete `SKPaymentTransactionObserver` conformance
- [ ] Replace product fetching with `loadProducts()`
- [ ] Replace purchase flow with `purchase(_:)` method
- [ ] Remove manual transaction finishing code
- [ ] Update UI to use `@Observable` pattern
- [ ] Remove receipt validation code (handled automatically)

## From Custom StoreKit 2

If you already have custom StoreKit 2 code, migration is simpler but still important.

### Old Custom StoreKit 2 Pattern

```swift
// Old custom code
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium = false
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePremiumStatus()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: ["com.app.premium"])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePremiumStatus()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }
    
    func updatePremiumStatus() async {
        var hasPremium = false
        
        for await result in Transaction.currentEntitlements {
            let transaction = try? checkVerified(result)
            if transaction != nil {
                hasPremium = true
                break
            }
        }
        
        isPremium = hasPremium
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                let transaction = try? self.checkVerified(result)
                await transaction?.finish()
                await self.updatePremiumStatus()
            }
        }
    }
}
```

### New StoreKit2Framework Pattern

```swift
// New code - much simpler!
import StoreKit2Framework

// Just configure and use
@main
struct YourApp: App {
    init() {
        let config = PremiumManager.Configuration(
            productIdentifiers: .init(
                monthly: "com.app.premium.monthly",
                yearly: "com.app.premium.yearly"
            ),
            features: [
                .init(title: "Premium Access", systemImageName: "star.fill")
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

### Key Benefits

- **Less Code**: ~200 lines reduced to ~20 lines
- **Better Pattern**: `@Observable` instead of `@Published`
- **Automatic Caching**: Premium status persists automatically
- **Better Error Handling**: Comprehensive error cases
- **UI Components**: Pre-built paywall and settings views
- **Feature Gating**: Built-in modifiers for premium content

## From Other Frameworks

### From RevenueCat

```swift
// Old RevenueCat
import RevenueCat

Purchases.configure(withAPIKey: "your_key")

Purchases.shared.getOfferings { offerings, error in
    // Handle offerings
}

Purchases.shared.purchase(package: package) { transaction, customerInfo, error, cancelled in
    if customerInfo?.entitlements["premium"]?.isActive == true {
        // User has premium
    }
}
```

```swift
// New StoreKit2Framework
import StoreKit2Framework

let config = PremiumManager.Configuration(
    productIdentifiers: .init(
        monthly: "com.app.premium.monthly",
        yearly: "com.app.premium.yearly"
    ),
    features: []
)
PremiumManager.shared.configure(config)
PremiumManager.shared.ensureInitialized()

// Check premium
if PremiumManager.shared.isPremium {
    // User has premium
}

// Purchase
Task {
    try await PremiumManager.shared.purchase(product)
}
```

**Benefits over RevenueCat:**
- No external service dependency
- No API keys to manage
- No additional costs
- Direct App Store integration
- Better privacy (no data shared with third parties)
- Native Swift concurrency

### From SwiftyStoreKit

```swift
// Old SwiftyStoreKit
import SwiftyStoreKit

SwiftyStoreKit.retrieveProductsInfo(["com.app.premium"]) { result in
    // Handle products
}

SwiftyStoreKit.purchaseProduct("com.app.premium") { result in
    switch result {
    case .success(let purchase):
        // Handle success
    case .error(let error):
        // Handle error
    }
}
```

```swift
// New StoreKit2Framework
import StoreKit2Framework

// Configure once
PremiumManager.shared.configure(config)
PremiumManager.shared.ensureInitialized()

// Products are automatically loaded
let products = PremiumManager.shared.products

// Purchase with modern async/await
Task {
    try await PremiumManager.shared.purchase(product)
}
```

**Benefits over SwiftyStoreKit:**
- Native StoreKit 2 (not wrapping StoreKit 1)
- Modern async/await instead of callbacks
- Observable pattern for reactive UI
- Built-in UI components
- Active maintenance and iOS 18+ support

## Step-by-Step Migration

### Phase 1: Preparation (1 hour)

1. **Review Current Implementation**
   ```bash
   # Find all StoreKit references
   grep -r "import StoreKit" .
   grep -r "SKProduct" .
   grep -r "SKPayment" .
   ```

2. **Document Product IDs**
   - List all current product identifiers
   - Note which are active and which are legacy
   - Check App Store Connect for exact IDs

3. **Backup Current Implementation**
   ```bash
   git checkout -b backup/old-storekit
   git push origin backup/old-storekit
   ```

4. **Install Framework**
   - Add package via Xcode
   - Verify it builds alongside existing code

### Phase 2: Parallel Implementation (2-4 hours)

1. **Add Configuration**
   ```swift
   // In App.swift or AppDelegate
   let config = PremiumManager.Configuration(
       productIdentifiers: .init(
           monthly: "YOUR_MONTHLY_ID",
           yearly: "YOUR_YEARLY_ID",
           lifetime: "YOUR_LIFETIME_ID"
       ),
       features: [
           // Your premium features
       ]
   )
   PremiumManager.shared.configure(config)
   PremiumManager.shared.ensureInitialized()
   ```

2. **Create Feature Flag**
   ```swift
   struct FeatureFlags {
       static var useNewStoreKit = false // Start with false
   }
   ```

3. **Implement Dual Code Paths**
   ```swift
   var isPremium: Bool {
       if FeatureFlags.useNewStoreKit {
           return PremiumManager.shared.isPremium
       } else {
           return oldIAPManager.isPremium
       }
   }
   ```

### Phase 3: UI Migration (1-2 hours)

1. **Replace Paywall**
   ```swift
   // Old custom paywall
   // Replace with:
   PaywallView(
       privacyPolicyURL: yourPrivacyURL,
       termsOfServiceURL: yourTermsURL,
       analyticsSource: "migration"
   )
   ```

2. **Update Settings**
   ```swift
   // Replace custom settings UI with:
   PremiumSettingsSection()
   ```

3. **Apply Feature Gating**
   ```swift
   // Replace manual checks with modifiers:
   PremiumFeatureView()
       .premiumRequired()
   ```

### Phase 4: Testing (2-3 hours)

1. **Enable New Implementation**
   ```swift
   struct FeatureFlags {
       static var useNewStoreKit = true // Enable
   }
   ```

2. **Test All Flows**
   - [ ] Load products
   - [ ] Purchase monthly
   - [ ] Purchase yearly
   - [ ] Purchase lifetime (if applicable)
   - [ ] Restore purchases
   - [ ] Subscription upgrade
   - [ ] Subscription downgrade
   - [ ] Cancellation behavior
   - [ ] Offline behavior
   - [ ] Fresh install restore

3. **Test Edge Cases**
   - [ ] No internet connection
   - [ ] Failed payment
   - [ ] Canceled subscription
   - [ ] Family sharing (if enabled)
   - [ ] Multiple devices

### Phase 5: Cleanup (1 hour)

1. **Remove Old Code**
   ```bash
   # Delete old IAP manager files
   # Remove old dependencies
   # Clean up unused imports
   ```

2. **Remove Feature Flag**
   ```swift
   // Delete FeatureFlags.useNewStoreKit checks
   // Use PremiumManager directly
   ```

3. **Update Documentation**
   - Update README
   - Update onboarding docs
   - Update team wiki

## Testing Your Migration

### Test Plan Template

#### Scenario 1: New User
1. Fresh app install
2. View paywall
3. Purchase monthly subscription
4. Verify premium access granted
5. Verify settings show correct status
6. Kill and restart app
7. Verify premium persists

#### Scenario 2: Existing Premium User
1. Install new version (with migration)
2. Launch app
3. Verify premium status maintained
4. Check settings UI
5. Test restore purchases
6. Verify all premium features work

#### Scenario 3: Subscription Changes
1. Have active monthly subscription
2. Upgrade to yearly
3. Verify upgrade successful
4. Check settings reflect new subscription
5. Test after subscription period

#### Scenario 4: Edge Cases
1. No network on launch
2. Network loss during purchase
3. Very slow network
4. Invalid product IDs (should fail gracefully)
5. Sandbox environment

### Monitoring Checklist

Monitor these metrics after migration:

- [ ] Conversion rate (before vs after)
- [ ] Purchase success rate
- [ ] Restore success rate
- [ ] Crash rate related to purchases
- [ ] User complaints about subscriptions
- [ ] App Store review sentiment

## Rollback Plan

### If Something Goes Wrong

1. **Immediate Rollback**
   ```bash
   git revert <migration-commits>
   git push origin main
   # Submit hotfix to App Store
   ```

2. **Partial Rollback**
   ```swift
   // Re-enable feature flag
   struct FeatureFlags {
       static var useNewStoreKit = false
   }
   ```

3. **Keep Both Systems**
   - Keep old code temporarily
   - Use feature flag for controlled rollout
   - Monitor metrics before full migration

### Rollback Checklist

- [ ] Old code still compiles
- [ ] Old code is tested and works
- [ ] Can deploy old version quickly
- [ ] Have backup of pre-migration database
- [ ] Can revert App Store submission

## Common Migration Issues

### Issue: Products Don't Load

**Symptom**: Empty products array after migration

**Solutions**:
1. Verify product IDs exactly match App Store Connect
2. Check StoreKit configuration file is selected in scheme
3. Ensure `ensureInitialized()` is called
4. Check for error logs in console

### Issue: Premium Status Lost

**Symptom**: Users lose premium after migration

**Solutions**:
1. Ensure you're not clearing UserDefaults during migration
2. Call `updatePremiumStatus()` on first launch
3. Verify transaction listener is running
4. Check `Transaction.currentEntitlements` is being checked

### Issue: UI Doesn't Update

**Symptom**: Premium status changes but UI stays the same

**Solutions**:
1. Verify using `@Observable` not `@ObservableObject`
2. Ensure accessing `.shared` instance correctly
3. Check `@MainActor` is on PremiumManager
4. Verify views are using `private let premiumManager = PremiumManager.shared`

## Best Practices

### DO ✅

- Test thoroughly in sandbox before production
- Keep old code for 1-2 releases during transition
- Use feature flags for gradual rollout
- Monitor metrics closely after migration
- Document any custom behavior you need to preserve
- Communicate changes to your team

### DON'T ❌

- Don't rush the migration before a major release
- Don't delete old code immediately
- Don't skip testing restore functionality
- Don't forget to test offline behavior
- Don't migrate without understanding your current flow
- Don't assume all users will update immediately

## Need Help?

- **Documentation**: See [INTEGRATION.md](INTEGRATION.md) for detailed usage
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Examples**: Check `Examples/DemoApp` for working code
- **Issues**: Report problems on GitHub Issues

---

**Good luck with your migration!** Take it step by step and test thoroughly. 🚀
