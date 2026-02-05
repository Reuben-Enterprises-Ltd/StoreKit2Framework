# Issue 002: Implement Core PremiumManager

## Priority
**Critical** - The brain of the entire framework

## Description
Implement the PremiumManager class as described in STOREKIT_COPILOT_AGENT_GUIDE.md. This is the centralized manager that handles all StoreKit interactions.

## Requirements

### Core Functionality
- Singleton pattern with `shared` instance
- `@Observable` and `@MainActor` for SwiftUI integration
- Product loading from App Store
- Purchase processing with verification
- Restore purchases functionality
- Real-time transaction monitoring
- Premium status caching for instant UI updates

### Public API
```swift
@MainActor
@Observable
final class PremiumManager {
    // Singleton
    static let shared: PremiumManager
    
    // Observable State
    var isPremium: Bool
    var products: [Product]
    var isLoading: Bool
    var error: Error?
    
    // Methods
    func ensureInitialized()
    func loadProducts() async
    func purchase(_ product: Product) async throws
    func restorePurchases() async
    func updatePremiumStatus() async
}
```

### Product Identifiers
- Make product IDs configurable
- Support monthly subscription
- Support yearly subscription
- Support lifetime purchase (non-consumable)
- All subscriptions in same group for automatic upgrade/downgrade

### Security Features
- Transaction verification before processing
- Fail-safe error handling
- Never trust unverified transactions
- Proper error types defined

### Performance Features
- Cached premium status in UserDefaults
- Instant UI updates on launch
- Background transaction listener
- Async/await throughout

## Acceptance Criteria
- [ ] PremiumManager.swift created with all functionality
- [ ] Follows @Observable pattern (not ObservableObject)
- [ ] All public methods marked @MainActor
- [ ] Transaction verification implemented
- [ ] Caching works for offline access
- [ ] Background listener catches external changes
- [ ] Debug override flag for testing (#if DEBUG)
- [ ] Comprehensive error handling
- [ ] Unit tests for core logic
- [ ] Code follows Swift 6.2 strict concurrency

## Technical Notes
- Reference implementation in STOREKIT_COPILOT_AGENT_GUIDE.md lines 76-335
- Use `nonisolated(unsafe)` for updateListenerTask if needed
- Call `transaction.finish()` after verification
- Check both subscriptions AND lifetime purchases
- Support premium override via environment variable for testing

## Related Issues
- Depends on: #001 (Package foundation)
- Blocks: #003 (UI Components)
- Blocks: #005 (Feature gating)

## Estimated Effort
4-6 hours
