# StoreKit 2 Implementation Guide for Copilot Agents

This document explains how to implement a complete StoreKit 2 subscription and paywall system in a SwiftUI iOS app. It's designed to be app-agnostic and replicable in any iOS project.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Implementation Steps](#implementation-steps)
4. [Product Configuration](#product-configuration)
5. [UI Implementation](#ui-implementation)
6. [Testing Strategy](#testing-strategy)
7. [Design Decisions & Rationale](#design-decisions--rationale)
8. [Best Practices](#best-practices)

---

## Architecture Overview

### High-Level Design Philosophy

**Key Principle**: Separation of concerns with a centralized manager pattern.

- **Single Source of Truth**: One `@Observable` manager class handles all StoreKit operations
- **Reactive UI**: SwiftUI views observe the manager's state
- **Security First**: All transactions verified before processing
- **Offline Support**: Cached premium status for instant UI updates
- **Real-time Updates**: Background listener for transaction changes

### Component Architecture

```
┌─────────────────────────────────────────────────────┐
│                    App Store                         │
│              (Products & Transactions)               │
└──────────────────────┬──────────────────────────────┘
                       │
                       │ StoreKit 2 API
                       │
┌──────────────────────▼──────────────────────────────┐
│              PremiumManager                          │
│         (@Observable, @MainActor, Singleton)         │
│                                                      │
│  State:                                              │
│  • isPremium: Bool (cached & reactive)               │
│  • products: [Product]                               │
│  • isLoading/error states                            │
│                                                      │
│  Operations:                                         │
│  • Load products from App Store                      │
│  • Process purchases                                 │
│  • Verify transactions                               │
│  • Restore purchases                                 │
│  • Listen for real-time updates                      │
└──────────────────────┬──────────────────────────────┘
                       │
                       │ Observable
                       │
            ┌──────────┴──────────┐
            │                     │
┌───────────▼────────┐  ┌────────▼──────────┐
│   Settings View    │  │   Paywall Views   │
│  (Status Display)  │  │  (Purchase Flow)  │
└────────────────────┘  └───────────────────┘
```

---

## Core Components

### 1. Premium Manager (The Brain)

This is the most critical component. It's a singleton `@Observable` class that manages all StoreKit interactions.

**File**: `PremiumManager.swift`

```swift
import SwiftUI
import StoreKit

@MainActor
@Observable
final class PremiumManager {
    // MARK: - Product Identifiers
    
    /// Define your product IDs here
    enum ProductIdentifiers {
        static let monthly = "com.yourcompany.yourapp.monthly"
        static let yearly = "com.yourcompany.yourapp.yearly"
        static let lifetime = "com.yourcompany.yourapp.lifetime"
        
        static var all: [String] {
            [monthly, yearly, lifetime]
        }
    }
    
    // MARK: - Singleton
    
    static let shared = PremiumManager()
    
    // MARK: - Public State (Observable)
    
    /// Whether the user has premium access (reactive)
    private(set) var isPremium = false
    
    /// Available products from the App Store
    private(set) var products: [Product] = []
    
    /// Loading state
    private(set) var isLoading = false
    
    /// Error state
    private(set) var error: Error?
    
    // MARK: - Private State
    
    /// Active subscription or lifetime non-renewing subscription
    private(set) var activeEntitlement: Product.SubscriptionInfo.Status?
    
    /// Transaction update task
    private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?
    
    /// Key for caching premium status
    private let cachedPremiumStatusKey = "cachedPremiumStatus"
    
    /// Whether initialization has started
    private var hasStartedInitialization = false
    
    /// Whether premium status has been updated this launch
    private var hasUpdatedStatusThisLaunch = false
    
    // MARK: - Debug Override (Optional)
    
    /// Scheme flag for testing premium without IAP (DEBUG only)
    #if DEBUG
    private let premiumOverride: Bool = {
        ProcessInfo.processInfo.environment["PREMIUM_ENABLED"] == "1"
    }()
    #else
    private let premiumOverride = false
    #endif
    
    // MARK: - Cached Premium Status
    
    private var cachedPremiumStatus: Bool {
        get { UserDefaults.standard.bool(forKey: cachedPremiumStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: cachedPremiumStatusKey) }
    }
    
    // MARK: - Initialization
    
    private nonisolated init() {
        // Deferred to startInitialization() which must run on MainActor
    }
    
    /// Start initialization - call this early in app lifecycle
    private func startInitialization() {
        guard !hasStartedInitialization else { return }
        hasStartedInitialization = true
        
        // Load cached status immediately for instant UI
        isPremium = cachedPremiumStatus || premiumOverride
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and verify status asynchronously
        Task {
            await loadProducts()
            await updatePremiumStatusIfNeeded()
        }
    }
    
    /// Public method to ensure initialization
    func ensureInitialized() {
        startInitialization()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let loadedProducts = try await Product.products(for: ProductIdentifiers.all)
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    /// Purchase a product
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Update premium status
            await updatePremiumStatus()
            
            // Finish the transaction
            await transaction.finish()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
        } catch {
            self.error = error
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Premium Status Management
    
    /// Update premium status if not done this launch
    private func updatePremiumStatusIfNeeded() async {
        guard !hasUpdatedStatusThisLaunch else { return }
        hasUpdatedStatusThisLaunch = true
        await updatePremiumStatus()
    }
    
    /// Update premium status based on entitlements
    func updatePremiumStatus() async {
        var hasActiveEntitlement = false
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check for lifetime non-renewing subscription
                if transaction.productID == ProductIdentifiers.lifetime {
                    #if DEBUG
                    // In debug mode, lifetime expires after 10 minutes for testing
                    let debugExpirationInterval: TimeInterval = 10 * 60 // 10 minutes
                    let purchaseDate = transaction.purchaseDate
                    let expirationDate = purchaseDate.addingTimeInterval(debugExpirationInterval)
                    
                    if Date() < expirationDate {
                        hasActiveEntitlement = true
                        break
                    }
                    #else
                    // In production, lifetime never expires
                    hasActiveEntitlement = true
                    break
                    #endif
                }
                
                // Check for active subscription
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {
                    let status = try await subscription.status.first
                    
                    if case .verified(let renewalInfo) = status?.renewalInfo,
                       case .verified = status?.transaction {
                        // Check if subscription is active
                        if renewalInfo.willAutoRenew {
                            hasActiveEntitlement = true
                            activeEntitlement = status
                            break
                        }
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        // Update status and cache
        let newStatus = hasActiveEntitlement || premiumOverride
        cachedPremiumStatus = newStatus
        isPremium = newStatus
    }
    
    // MARK: - Real-time Transaction Monitoring
    
    /// Listen for transaction updates in the background
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePremiumStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    /// Verify a transaction is legitimate
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

// MARK: - Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
```

**Why This Design?**

1. **`@Observable` instead of `ObservableObject`**: Modern Swift pattern, cleaner syntax
2. **`@MainActor`**: All StoreKit UI operations happen on main thread
3. **Singleton**: Single source of truth accessible throughout the app
4. **Cached Status**: Instant UI updates on app launch, verified asynchronously
5. **Real-time Listener**: Catches purchases from other devices, refunds, expirations
6. **Verification First**: Security - never trust unverified transactions
7. **Debug Override**: Test premium features without purchasing in development

### 2. StoreKit Configuration File

**File**: `YourApp.storekit` (JSON file in Xcode project)

```json
{
  "identifier": "UNIQUE_ID",
  "nonRenewingSubscriptions": [],
  "products": [
    {
      "displayPrice": "24.99",
      "familyShareable": false,
      "internalID": "lifetime_internal_id",
      "localizations": [
        {
          "description": "Unlock all premium features forever",
          "displayName": "Lifetime Premium",
          "locale": "en_US"
        }
      ],
      "productID": "com.yourcompany.yourapp.lifetime",
      "referenceName": "Lifetime Premium",
      "type": "NonConsumable"
    }
  ],
  "subscriptionGroups": [
    {
      "id": "your_app_subscriptions",
      "localizations": [],
      "name": "Your App Premium",
      "subscriptions": [
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "4.99",
          "familyShareable": false,
          "groupNumber": 1,
          "internalID": "monthly_internal_id",
          "introductoryOffer": null,
          "localizations": [
            {
              "description": "Full access to all premium features",
              "displayName": "Monthly Premium",
              "locale": "en_US"
            }
          ],
          "productID": "com.yourcompany.yourapp.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Monthly Premium",
          "subscriptionGroupID": "your_app_subscriptions",
          "type": "RecurringSubscription"
        },
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "39.99",
          "familyShareable": false,
          "groupNumber": 2,
          "internalID": "yearly_internal_id",
          "introductoryOffer": null,
          "localizations": [
            {
              "description": "Full access to all premium features for a year",
              "displayName": "Yearly Premium",
              "locale": "en_US"
            }
          ],
          "productID": "com.yourcompany.yourapp.yearly",
          "recurringSubscriptionPeriod": "P1Y",
          "referenceName": "Yearly Premium",
          "subscriptionGroupID": "your_app_subscriptions",
          "type": "RecurringSubscription"
        }
      ]
    }
  ],
  "version": {
    "major": 4,
    "minor": 0
  }
}
```

**How to Set Up**:
1. Create this file in Xcode: File → New → StoreKit Configuration File
2. Edit the scheme: Product → Scheme → Edit Scheme
3. Run → Options → StoreKit Configuration → Select your file
4. This enables local testing without App Store Connect

---

## Implementation Steps

### Step 1: Create the Manager

1. Create `PremiumManager.swift` with the code above
2. Update `ProductIdentifiers` with your product IDs
3. Add to your main app target

### Step 2: Initialize Early

In your main app entry point:

```swift
@main
struct YourApp: App {
    init() {
        // Initialize premium manager early
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Why?**: Start loading products and checking status as soon as possible.

### Step 3: Create UI Views

You need 2-3 UI components:

1. **Paywall View** - For prompting upgrades at strategic moments
2. **Subscription Management View** - Full-featured subscription center
3. **Settings Integration** - Show premium status

---

## UI Implementation

### 1. Paywall View (Strategic Upgrade Prompts)

**File**: `PaywallView.swift`

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let premiumManager = PremiumManager.shared
    
    let headline: String?
    
    @State private var selectedProduct: Product?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false
    
    init(headline: String? = nil) {
        self.headline = headline
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero section
                    heroSection
                    
                    // Benefits
                    benefitsSection
                    
                    // Product selection
                    productSelection
                    
                    // Purchase button
                    purchaseButton
                    
                    // Restore button
                    restoreButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                premiumManager.ensureInitialized()
                selectDefaultProduct()
            }
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            Text(headline ?? "Unlock Premium Features")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("Get the most out of your experience")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add your app's specific benefits here
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                description: "Deep insights into your data"
            )
            BenefitRow(
                icon: "icloud",
                title: "Cloud Sync",
                description: "Access everywhere, anytime"
            )
            // Add more benefits...
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
    }
    
    private var productSelection: some View {
        VStack(spacing: 12) {
            ForEach(premiumManager.products, id: \.id) { product in
                ProductOptionButton(
                    product: product,
                    isSelected: selectedProduct?.id == product.id
                ) {
                    selectedProduct = product
                }
            }
        }
    }
    
    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                isPurchasing = true
                do {
                    try await premiumManager.purchase(product)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
                isPurchasing = false
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Premium")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue.gradient)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .opacity(selectedProduct == nil || isPurchasing ? 0.6 : 1.0)
    }
    
    private var restoreButton: some View {
        Button {
            Task {
                await premiumManager.restorePurchases()
                if premiumManager.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func selectDefaultProduct() {
        selectedProduct = premiumManager.products.first { 
            $0.id == PremiumManager.ProductIdentifiers.yearly 
        } ?? premiumManager.products.first
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProductOptionButton: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.subheadline)
                        .bold()
                    if let subscription = product.subscription {
                        Text("\(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.headline)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

extension Product.SubscriptionPeriod.Unit {
    var displayName: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }
}
```

**When to Show**: Present this view when users hit premium features, in onboarding, or from settings.

### 2. Settings Integration

```swift
struct SettingsView: View {
    private let premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        Form {
            Section {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Label("Premium", systemImage: "star.fill")
                        Spacer()
                        if premiumManager.isPremium {
                            Text("Active")
                                .foregroundStyle(.green)
                        } else {
                            Text("Unlock")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            premiumManager.ensureInitialized()
        }
    }
}
```

### 3. Feature Gating

Throughout your app, gate premium features like this:

```swift
struct SomeView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            // Premium content
            AdvancedFeatureView()
        } else {
            // Free content + upgrade prompt
            BasicFeatureView()
            UpgradePromptView()
        }
    }
}
```

**The UI automatically updates** when `isPremium` changes because `PremiumManager` is `@Observable`.

---

## Product Configuration

### Subscription Group Strategy

**One subscription group** containing all auto-renewable subscriptions:
- Monthly subscription
- Yearly subscription (recommended/default)

**Why one group?**
- Users can only have one active subscription at a time
- Upgrading/downgrading is handled automatically
- Simpler to manage

### Lifetime Subscription

The lifetime product is a **non-renewing subscription**, not a separate non-consumable product:
- **Type**: Non-renewing subscription (part of the subscription group)
- **Duration**: Never expires in production
- **Debug Mode**: Expires after 10 minutes for testing purposes
- **Syncs**: Across devices automatically
- **Pricing**: Typically 2-3x yearly subscription price

**Important**: In DEBUG mode, the lifetime subscription expires 10 minutes after purchase. This allows developers to test:
- Subscription expiration behavior
- UI updates when premium status changes
- Re-purchase flows
- Status refresh logic

In production builds, the lifetime subscription never expires and acts as a permanent premium unlock.

### Pricing Strategy

Consider this typical pricing structure:
- Monthly: Base price (e.g., $4.99)
- Yearly: ~17% discount (e.g., $39.99 vs $59.88)
- Lifetime: 2-2.5x yearly (e.g., $99.99)

**Why this works:**
- Monthly is accessible for trials
- Yearly is best value for subscribers
- Lifetime is for committed users

---

## Testing Strategy

### 1. Local Testing (StoreKit Configuration)

**Setup**:
1. Create `.storekit` configuration file
2. Add to Xcode scheme (Product → Scheme → Edit Scheme → Options)
3. Run in Simulator

**Test Cases**:
- [ ] Products load correctly
- [ ] Prices display in local currency
- [ ] Purchase flow completes
- [ ] Premium status updates immediately
- [ ] Restore finds previous purchases
- [ ] Transaction verification works
- [ ] UI updates reactively

### 2. Sandbox Testing (Real Devices)

**Setup**:
1. Create sandbox tester in App Store Connect
2. Sign out of App Store on device
3. Launch app, attempt purchase
4. Sign in with sandbox account when prompted

**Test Cases**:
- [ ] All products appear
- [ ] Purchase completes
- [ ] Receipt validates
- [ ] Subscription renews
- [ ] Upgrade/downgrade works
- [ ] Restore works after reinstall
- [ ] Expired subscription detected

### 3. Debug Testing (Premium Override)

Add this environment variable in Xcode scheme:
```
PREMIUM_ENABLED = 1
```

This bypasses StoreKit and grants premium status instantly. Perfect for:
- Testing premium features during development
- QA without purchases
- Screenshots/demos

**Remember**: This only works in DEBUG builds, never in production.

---

## Design Decisions & Rationale

### Why @Observable Instead of ObservableObject?

**Choice**: Use Swift's modern `@Observable` macro

**Rationale**:
- Cleaner syntax (no `@Published` needed)
- Better performance (SwiftUI only updates when observed properties change)
- Future-proof (Apple's recommended approach as of iOS 17+)
- Less boilerplate

### Why Singleton Pattern?

**Choice**: `PremiumManager.shared` singleton

**Rationale**:
- Single source of truth for premium status
- Prevent duplicate StoreKit listeners
- Easy access from anywhere in app
- Consistent state across all views

**Alternatives Considered**:
- Environment object: Requires passing through view hierarchy
- Multiple instances: Risk of state inconsistencies

### Why Cache Premium Status?

**Choice**: Save `isPremium` to UserDefaults

**Rationale**:
- Instant UI updates on app launch
- Works offline
- Verified asynchronously in background
- Better user experience (no loading spinner)

**Risk Mitigation**:
- Always verify against actual entitlements
- Cache is just for initial UI state
- Real status takes precedence after verification

### Why Background Transaction Listener?

**Choice**: Continuous `Task.detached` monitoring `Transaction.updates`

**Rationale**:
- Catches purchases from other devices
- Detects refunds immediately
- Handles subscription renewals
- Responds to App Store changes

**Cost**: Minimal - the async sequence only fires on actual changes.

### Why Verify Every Transaction?

**Choice**: Always call `checkVerified()` before processing

**Rationale**:
- Security: Prevent fraud
- Apple requirement for App Review
- Free with StoreKit 2 (server-side verification)
- Protects against jailbreak exploits

### Why Both Paywall and Settings Views?

**Choice**: Multiple purchase entry points

**Rationale**:
- **Paywall**: Strategic prompts when users hit limits (higher conversion)
- **Settings**: User-initiated discovery (better for transparent pricing)
- **Different contexts**: Paywall is focused, Settings is comprehensive

### Why Sort Products by Price?

**Choice**: `products.sorted { $0.price < $1.price }`

**Rationale**:
- Predictable order (monthly → yearly → lifetime)
- Works regardless of StoreKit return order
- Prevents UI jumping when products load

---

## Best Practices

### 1. Free Tier Must Be Functional

**Rule**: Never block core functionality behind paywall

**Implementation**:
- Core features always work (e.g., daily logging)
- Premium adds depth, not access
- Free tier is genuinely useful

**Example**:
```swift
// ✅ Good: Free tier gets 7 days, premium unlimited
let visibleEntries = premiumManager.isPremium ? allEntries : Array(allEntries.prefix(7))

// ❌ Bad: Core feature blocked
guard premiumManager.isPremium else {
    return UpgradeRequiredView()
}
```

### 2. Non-Judgmental Language

**Rule**: Upgrade prompts should be inviting, not guilt-inducing

**Good Examples**:
- "Unlock advanced insights"
- "Get the most out of your data"
- "Continue your journey"

**Bad Examples**:
- "You're missing out!"
- "Upgrade to unlock" (implies locked out)
- "Limited access" (sounds restrictive)

### 3. Always Show Restore

**Rule**: Restore purchases button must be visible

**Why**:
- App Store requirement
- Users reinstall apps
- Switch devices frequently
- May not remember purchasing

**Implementation**:
```swift
Button("Restore Purchases") {
    Task {
        await premiumManager.restorePurchases()
    }
}
```

### 4. Handle All Purchase Results

**Rule**: Don't just handle success - handle all cases

```swift
switch result {
case .success(let verification):
    // Process purchase
case .userCancelled:
    // Track analytics, no error needed
case .pending:
    // Show "processing" message
@unknown default:
    // Future-proof
}
```

### 5. Error Handling

**Rule**: Fail gracefully, never crash

```swift
do {
    try await premiumManager.purchase(product)
} catch {
    // Show user-friendly error
    errorMessage = "Unable to complete purchase. Please try again."
    showingAlert = true
    
    // Log for debugging
    print("Purchase failed: \(error)")
}
```

### 6. Loading States

**Rule**: Show loading indicators during async operations

```swift
if premiumManager.isLoading {
    ProgressView("Loading products...")
} else if premiumManager.products.isEmpty {
    Text("Unable to load products")
    Button("Try Again") {
        Task { await premiumManager.loadProducts() }
    }
} else {
    // Show products
}
```

### 7. Analytics Integration

**Rule**: Track key events for business insights

Track these events:
- Paywall viewed (with source: onboarding, feature-limit, settings, etc.)
- Product selected
- Purchase initiated
- Purchase completed (with product ID and price)
- Purchase cancelled
- Purchase failed (with error)
- Restore attempted
- Restore successful/failed

**Example**:
```swift
func purchase(_ product: Product) async throws {
    // Track initiation
    analytics.track("purchase_initiated", properties: [
        "product_id": product.id,
        "price": product.price
    ])
    
    let result = try await product.purchase()
    
    switch result {
    case .success:
        analytics.track("purchase_completed", properties: [
            "product_id": product.id
        ])
    case .userCancelled:
        analytics.track("purchase_cancelled")
    // ...
    }
}
```

### 8. App Store Connect Requirements

Before submitting to App Store:

1. **Create Products**:
   - Go to App Store Connect → Your App → Monetization
   - Create each product with exact IDs from your code
   - Add descriptions and screenshots
   - Submit for review

2. **Legal Links**:
   - Privacy Policy URL (required)
   - Terms of Use URL (required if subscriptions)
   - Add to your paywall UI

3. **Screenshots**:
   - Show purchase flow
   - Show premium features
   - Show subscription management

4. **Testing**:
   - Test with sandbox accounts
   - Test restore on fresh install
   - Test subscription renewal
   - Test all edge cases

---

## Common Pitfalls & Solutions

### Pitfall 1: Products Don't Load

**Symptoms**: Empty products array, nothing to purchase

**Solutions**:
1. Check StoreKit configuration is selected in scheme
2. Verify product IDs match exactly (case-sensitive)
3. Check network connection
4. For production: Verify products are "Ready to Submit" in App Store Connect
5. Check console for errors: `print("Failed to load products: \(error)")`

### Pitfall 2: Purchases Don't Persist

**Symptoms**: User purchases but loses premium after restart

**Solutions**:
1. Ensure `finish()` is called on verified transactions
2. Check `updatePremiumStatus()` is called after purchase
3. Verify caching logic works: `cachedPremiumStatus = newStatus`
4. Check `listenForTransactions()` is running
5. Verify `Transaction.currentEntitlements` is checked on launch

### Pitfall 3: UI Doesn't Update

**Symptoms**: Premium status changes but UI stays the same

**Solutions**:
1. Ensure `PremiumManager` is marked `@Observable` and `@MainActor`
2. Verify views access manager correctly (not creating new instances)
3. Check initialization: Call `ensureInitialized()` in view's `onAppear`
4. Don't cache the manager in view's stored property incorrectly

### Pitfall 4: Subscription Conflicts

**Symptoms**: Can't purchase yearly after buying monthly

**Solutions**:
1. Ensure all subscriptions are in the **same subscription group**
2. Check group IDs match in code and App Store Connect
3. StoreKit automatically handles upgrades/downgrades within a group

### Pitfall 5: Restore Doesn't Work

**Symptoms**: "No purchases found" when user has purchased

**Solutions**:
1. User must be signed into same Apple ID
2. Subscriptions might have expired
3. Ensure `AppStore.sync()` is called before checking entitlements
4. Check for unfinished transactions: Some transactions might not be finished
5. Review transaction verification logic

### Pitfall 6: Testing in Production

**Symptoms**: Can't test purchases in production app

**Solution**: Use TestFlight
1. Upload build to TestFlight
2. Use sandbox accounts
3. Never test real purchases with your own Apple ID
4. Use promo codes for testing production builds

---

## Integration Checklist

Use this checklist when implementing:

### Phase 1: Setup
- [ ] Create `PremiumManager.swift`
- [ ] Update product IDs for your app
- [ ] Create `.storekit` configuration file
- [ ] Configure Xcode scheme to use StoreKit file
- [ ] Add initialization to app entry point

### Phase 2: UI
- [ ] Create `PaywallView.swift`
- [ ] Create benefit list specific to your app
- [ ] Add settings integration
- [ ] Implement feature gating throughout app
- [ ] Add loading/error states

### Phase 3: Testing
- [ ] Test product loading in Simulator
- [ ] Test monthly purchase
- [ ] Test yearly purchase
- [ ] Test lifetime purchase
- [ ] Test upgrade from monthly to yearly
- [ ] Test restore after reinstall
- [ ] Test offline behavior
- [ ] Test premium override flag

### Phase 4: App Store Connect
- [ ] Create all products in App Store Connect
- [ ] Add descriptions and localizations
- [ ] Create subscription group
- [ ] Configure pricing
- [ ] Add privacy policy and terms URLs
- [ ] Submit products for review

### Phase 5: Final Verification
- [ ] Test with sandbox account on real device
- [ ] Test restore process
- [ ] Verify all legal links work
- [ ] Check analytics tracking
- [ ] Test all edge cases
- [ ] Verify App Review guidelines compliance
- [ ] Document for your team

---

## Summary

This StoreKit 2 implementation provides:

✅ **Clean Architecture**: Centralized manager with reactive UI
✅ **Security**: Transaction verification built-in
✅ **User Experience**: Instant cached status, smooth purchase flow
✅ **Reliability**: Real-time updates, offline support
✅ **Testability**: Local testing, debug overrides, sandbox support
✅ **Best Practices**: Free tier protection, clear messaging, error handling

**Key Files to Create**:
1. `PremiumManager.swift` - Core business logic
2. `PaywallView.swift` - Purchase UI
3. `YourApp.storekit` - Local testing configuration

**Integration Points**:
- App initialization: `PremiumManager.shared.ensureInitialized()`
- Settings: Premium status display
- Feature gates: `if premiumManager.isPremium { ... }`
- Strategic prompts: Present `PaywallView`

Follow this guide and you'll have a robust, App Store-compliant subscription system that provides great user experience while protecting your business.
