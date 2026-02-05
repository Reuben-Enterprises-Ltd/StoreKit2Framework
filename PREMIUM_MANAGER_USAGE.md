# PremiumManager Usage Guide

## Overview

`PremiumManager` is the core component of StoreKit2Framework. It handles all StoreKit operations including product loading, purchases, transaction verification, and premium status tracking.

## Features

✅ **Singleton Pattern** - Access via `PremiumManager.shared`  
✅ **Observable** - Reactive state updates for SwiftUI  
✅ **Main Actor** - Thread-safe UI updates  
✅ **Transaction Verification** - Security-first approach  
✅ **Offline Support** - Cached premium status  
✅ **Real-time Updates** - Background transaction listener  
✅ **Debug Override** - Test premium features without IAP  

## Quick Start

### 1. Initialize Early in App Lifecycle

```swift
import SwiftUI
import StoreKit2Framework

@main
struct MyApp: App {
    init() {
        // Initialize PremiumManager early
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Configure Product Identifiers

Update the product IDs in `PremiumManager.ProductIdentifiers`:

```swift
public enum ProductIdentifiers {
    public static let monthly = "com.yourcompany.yourapp.monthly"
    public static let yearly = "com.yourcompany.yourapp.yearly"
    public static let lifetime = "com.yourcompany.yourapp.lifetime"
}
```

### 3. Use in SwiftUI Views

```swift
import SwiftUI
import StoreKit
import StoreKit2Framework

struct ContentView: View {
    // Access the shared manager
    @State private var manager = PremiumManager.shared
    
    var body: some View {
        VStack {
            if manager.isPremium {
                Text("✨ Premium Active")
                    .font(.headline)
            } else {
                Text("Free Version")
                    .font(.headline)
                
                Button("Upgrade to Premium") {
                    Task {
                        await showPaywall()
                    }
                }
            }
        }
        .task {
            // Load products when view appears
            await manager.loadProducts()
        }
    }
    
    private func showPaywall() async {
        // Show your paywall UI
    }
}
```

### 4. Implement Purchase Flow

```swift
struct PaywallView: View {
    @State private var manager = PremiumManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock Premium Features")
                .font(.title)
            
            if manager.isLoading {
                ProgressView()
            } else {
                ForEach(manager.products, id: \.id) { product in
                    ProductRow(product: product) {
                        await purchase(product)
                    }
                }
            }
            
            Button("Restore Purchases") {
                Task {
                    await manager.restorePurchases()
                }
            }
        }
        .alert("Error", isPresented: .constant(manager.error != nil)) {
            Button("OK") {
                // Handle error
            }
        } message: {
            if let error = manager.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func purchase(_ product: Product) async {
        do {
            try await manager.purchase(product)
            // Purchase successful
        } catch {
            // Handle purchase error
            print("Purchase failed: \(error)")
        }
    }
}

struct ProductRow: View {
    let product: Product
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.title3)
                    .bold()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(.rect(cornerRadius: 12))
        }
    }
}
```

## Observable State

The `PremiumManager` exposes the following observable properties:

- **`isPremium: Bool`** - Current premium status (cached and reactive)
- **`products: [Product]`** - Available products from App Store
- **`isLoading: Bool`** - Loading state for UI feedback
- **`error: Error?`** - Last error encountered

## Public Methods

### `ensureInitialized()`
Call early in app lifecycle to start initialization.

```swift
PremiumManager.shared.ensureInitialized()
```

### `loadProducts() async`
Load products from the App Store.

```swift
await manager.loadProducts()
```

### `purchase(_ product: Product) async throws`
Purchase a product with transaction verification.

```swift
try await manager.purchase(product)
```

### `restorePurchases() async`
Restore previous purchases.

```swift
await manager.restorePurchases()
```

### `updatePremiumStatus() async`
Manually update premium status (normally automatic).

```swift
await manager.updatePremiumStatus()
```

## Testing

### Debug Override

Enable premium features without IAP during development:

1. In Xcode, edit scheme
2. Add environment variable: `PREMIUM_ENABLED=1`
3. Run the app - premium will be enabled

### Unit Tests

Tests are included to verify core functionality:

```swift
swift test
```

## Security

- ✅ All transactions are verified before processing
- ✅ Unverified transactions are rejected
- ✅ Transactions are finished after processing
- ✅ No trust in unverified data

## Caching

Premium status is cached in `UserDefaults` for:
- Instant UI updates on app launch
- Offline access to premium status
- Improved user experience

## Transaction Monitoring

A background task monitors `Transaction.updates` to catch:
- Purchases made on other devices
- Subscription renewals
- External transaction changes
- Family Sharing changes

## Error Handling

```swift
public enum StoreError: Error, LocalizedError {
    case failedVerification
    
    public var errorDescription: String? {
        "Transaction verification failed"
    }
}
```

## Best Practices

1. **Initialize Early** - Call `ensureInitialized()` in app initialization
2. **Handle Errors** - Always handle errors from purchase operations
3. **Show Loading States** - Use `isLoading` to provide feedback
4. **Test Thoroughly** - Test with StoreKit Configuration files
5. **Verify Transactions** - Never trust unverified transactions

## App Store Connect Setup

Before using PremiumManager in production:

1. Create your products in App Store Connect
2. Update product IDs in `ProductIdentifiers`
3. Set up subscription groups
4. Configure subscription levels
5. Test with StoreKit Configuration file
6. Test with TestFlight

## Platform Requirements

- iOS 18.0+
- Swift 6.2+
- StoreKit 2
- SwiftUI

## Thread Safety

All public methods are marked `@MainActor` and run on the main thread. The implementation follows Swift 6.2 strict concurrency rules.

## License

See LICENSE file in repository.
