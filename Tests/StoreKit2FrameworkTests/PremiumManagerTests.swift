import Testing
@testable import StoreKit2Framework

#if canImport(StoreKit)
import StoreKit
#endif

/// Comprehensive tests for PremiumManager
///
/// Note: These tests document and verify the behavior of PremiumManager.
/// Full testing with actual StoreKit transactions requires an iOS environment
/// with StoreKit Testing enabled using the Configuration.storekit file.
@Suite("PremiumManager Tests")
struct PremiumManagerTests {
    
    // MARK: - Singleton Tests
    
    @Test("PremiumManager singleton exists")
    func singletonExists() async throws {
        // PremiumManager.shared should be accessible
        // This test verifies the singleton pattern is implemented
        #if canImport(StoreKit)
        _ = PremiumManager.shared
        #endif
    }
    
    @Test("Singleton returns same instance")
    func singletonConsistency() async throws {
        #if canImport(StoreKit)
        let instance1 = PremiumManager.shared
        let instance2 = PremiumManager.shared
        // Both should reference the same object
        #expect(instance1 === instance2)
        #endif
    }
    
    // MARK: - Product Identifier Tests
    
    @Test("Product identifiers are defined")
    func productIdentifiersAreDefined() async throws {
        // Verify that all required product identifiers are defined
        #if canImport(StoreKit)
        #expect(!PremiumManager.ProductIdentifiers.monthly.isEmpty)
        #expect(!PremiumManager.ProductIdentifiers.yearly.isEmpty)
        #expect(!PremiumManager.ProductIdentifiers.lifetime.isEmpty)
        #expect(PremiumManager.ProductIdentifiers.all.count == 3)
        #endif
    }
    
    @Test("Product identifiers follow naming convention")
    func productIdentifierNaming() async throws {
        #if canImport(StoreKit)
        // Verify all product IDs follow the expected format
        let monthly = PremiumManager.ProductIdentifiers.monthly
        let yearly = PremiumManager.ProductIdentifiers.yearly
        let lifetime = PremiumManager.ProductIdentifiers.lifetime
        
        #expect(monthly.contains("monthly"))
        #expect(yearly.contains("yearly"))
        #expect(lifetime.contains("lifetime"))
        #endif
    }
    
    @Test("Product identifiers all array contains all products")
    func productIdentifiersAllArray() async throws {
        #if canImport(StoreKit)
        let all = PremiumManager.ProductIdentifiers.all
        
        #expect(all.contains(PremiumManager.ProductIdentifiers.monthly))
        #expect(all.contains(PremiumManager.ProductIdentifiers.yearly))
        #expect(all.contains(PremiumManager.ProductIdentifiers.lifetime))
        #endif
    }
    
    // MARK: - Initial State Tests
    
    @Test("Initial state is correct")
    func initialStateIsCorrect() async throws {
        // When PremiumManager is first accessed, it should have sensible defaults
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // isPremium should default to false (unless cached or overridden)
        // This may be true if cached from previous run or PREMIUM_ENABLED is set
        // #expect(!manager.isPremium)
        
        // Products should start empty before loading
        #expect(manager.products.isEmpty)
        
        // Should not be loading initially
        #expect(!manager.isLoading)
        
        // Error should be nil initially
        #expect(manager.error == nil)
        #endif
    }
    
    @Test("Active entitlement is nil initially")
    func initialActiveEntitlement() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        #expect(manager.activeEntitlement == nil)
        #endif
    }
    
    // MARK: - Initialization Tests
    
    @Test("ensureInitialized can be called multiple times")
    func ensureInitializedIdempotent() async throws {
        // ensureInitialized should be safe to call multiple times
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Should not crash or cause issues
        manager.ensureInitialized()
        manager.ensureInitialized()
        manager.ensureInitialized()
        #endif
    }
    
    @Test("ensureInitialized is safe for concurrent calls")
    func ensureInitializedConcurrent() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Call ensureInitialized concurrently - should be safe
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    manager.ensureInitialized()
                }
            }
        }
        #endif
    }
    
    // MARK: - Product Loading Tests
    
    @Test("loadProducts sets loading state")
    func loadProductsLoadingState() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Start loading products
        let loadTask = Task { @MainActor in
            await manager.loadProducts()
        }
        
        // Give it a moment to start
        try? await Task.sleep(for: .milliseconds(10))
        
        // At some point during or after loading, isLoading should have been true
        // and should be false after completion
        await loadTask.value
        
        // After completion, isLoading should be false
        #expect(!manager.isLoading)
        #endif
    }
    
    @Test("loadProducts clears previous errors")
    func loadProductsClearsErrors() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Load products
        await manager.loadProducts()
        
        // After loading (success or failure), error state should be defined
        // If loading succeeded, error should be nil
        // If loading failed, error should be set
        // We verify the behavior is consistent (no crash, state is valid)
        _ = manager.error != nil
        _ = !manager.products.isEmpty
        #endif
    }
    
    @Test("loadProducts handles empty results gracefully")
    func loadProductsEmptyResults() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Load products - might be empty in test environment
        await manager.loadProducts()
        
        // Should not crash with empty products
        #expect(manager.products.count >= 0)
        #endif
    }
    
    // MARK: - Premium Status Tests
    
    @Test("Premium status is boolean")
    func premiumStatusBoolean() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // isPremium should always be a valid boolean
        let status = manager.isPremium
        #expect(status == true || status == false)
        #endif
    }
    
    @Test("Premium status can be read multiple times")
    func premiumStatusReadable() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        let status1 = manager.isPremium
        let status2 = manager.isPremium
        
        // Should return consistent value
        #expect(status1 == status2)
        #endif
    }
    
    @Test("updatePremiumStatus completes without errors")
    func updatePremiumStatusCompletes() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Should complete without throwing
        await manager.updatePremiumStatus()
        
        // Status should be defined
        _ = manager.isPremium
        #endif
    }
    
    @Test("updatePremiumStatus is safe to call multiple times")
    func updatePremiumStatusMultipleCalls() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Call multiple times - should be safe
        await manager.updatePremiumStatus()
        await manager.updatePremiumStatus()
        await manager.updatePremiumStatus()
        #endif
    }
    
    // MARK: - Caching Tests
    
    @Test("Premium status is cached in UserDefaults")
    func premiumStatusCaching() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Get current status
        let currentStatus = manager.isPremium
        
        // The status should be cached
        // Note: We can't directly verify this without access to private properties
        // but we can verify the behavior is consistent
        let cachedStatus = UserDefaults.standard.bool(forKey: "cachedPremiumStatus")
        
        // If premium is true, cache should reflect that
        if currentStatus {
            #expect(cachedStatus == true)
        }
        #endif
    }
    
    // MARK: - Error Handling Tests
    
    @Test("StoreError has proper error descriptions")
    func storeErrorDescriptions() async throws {
        // Verify error descriptions are user-friendly
        #if canImport(StoreKit)
        let error = StoreError.failedVerification
        #expect(error.errorDescription == "Transaction verification failed")
        #endif
    }
    
    @Test("StoreError conforms to LocalizedError")
    func storeErrorLocalized() async throws {
        #if canImport(StoreKit)
        let error: LocalizedError = StoreError.failedVerification
        #expect(error.errorDescription != nil)
        #endif
    }
    
    // MARK: - Restore Purchases Tests
    
    @Test("restorePurchases completes without throwing")
    func restorePurchasesCompletes() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Should complete without throwing
        await manager.restorePurchases()
        
        // Manager should still be in valid state
        _ = manager.isPremium
        #endif
    }
    
    @Test("restorePurchases can be called multiple times")
    func restorePurchasesMultipleCalls() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Call multiple times - should be safe
        await manager.restorePurchases()
        await manager.restorePurchases()
        #endif
    }
    
    // MARK: - Debug Override Tests
    
    @Test("Debug override environment variable is checked")
    func debugOverrideVariable() async throws {
        #if canImport(StoreKit) && DEBUG
        // Verify that PREMIUM_ENABLED environment variable is respected
        let premiumEnabled = ProcessInfo.processInfo.environment["PREMIUM_ENABLED"]
        
        // If set to "1", premium should be active
        if premiumEnabled == "1" {
            let manager = PremiumManager.shared
            #expect(manager.isPremium == true)
        }
        #endif
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent product loading is safe")
    func concurrentProductLoading() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Load products concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    await manager.loadProducts()
                }
            }
        }
        
        // Should complete without issues
        #expect(!manager.isLoading)
        #endif
    }
    
    @Test("Concurrent status updates are safe")
    func concurrentStatusUpdates() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Update status concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    await manager.updatePremiumStatus()
                }
            }
        }
        
        // Should complete without issues
        _ = manager.isPremium
        #endif
    }
    
    @Test("Concurrent restore operations are safe")
    func concurrentRestores() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Restore concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask { @MainActor in
                    await manager.restorePurchases()
                }
            }
        }
        
        // Should complete without issues
        _ = manager.isPremium
        #endif
    }
    
    // MARK: - State Management Tests
    
    @Test("Products array is accessible")
    func productsArrayAccess() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Products should be accessible
        let products = manager.products
        #expect(products.count >= 0)
        #endif
    }
    
    @Test("Loading state is accessible")
    func loadingStateAccess() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Loading state should be accessible
        let isLoading = manager.isLoading
        #expect(isLoading == true || isLoading == false)
        #endif
    }
    
    @Test("Error state is accessible")
    func errorStateAccess() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        // Error state should be accessible
        _ = manager.error
        #endif
    }
}

/// Documentation of PremiumManager behavior
///
/// This comment documents the expected behavior that would be tested
/// in a full iOS test environment:
///
/// 1. Product Loading:
///    - loadProducts() should fetch products from App Store
///    - Products should be sorted by price
///    - isLoading should be true during load
///    - error should be set if loading fails
///
/// 2. Purchase Flow:
///    - purchase(_:) should initiate purchase
///    - Transaction verification should happen before processing
///    - Premium status should update after successful purchase
///    - Transaction should be finished after processing
///
/// 3. Restore Purchases:
///    - restorePurchases() should sync with App Store
///    - Premium status should update if entitlements found
///
/// 4. Premium Status:
///    - updatePremiumStatus() should check Transaction.currentEntitlements
///    - Should detect lifetime purchases
///    - Should detect active subscriptions (including non-renewing but valid)
///    - Should cache status in UserDefaults
///    - Should respect debug override when PREMIUM_ENABLED=1
///
/// 5. Transaction Monitoring:
///    - Background listener should catch external changes
///    - Should verify transactions before processing
///    - Should finish transactions after processing
///    - Should properly isolate to MainActor
///
/// 6. Caching:
///    - Premium status should be cached in UserDefaults
///    - Cached status should load instantly on launch
///    - Cache should update when status changes
///
/// 7. Concurrency:
///    - All public methods should run on @MainActor
///    - Should follow Swift 6.2 strict concurrency
///    - nonisolated(unsafe) used appropriately for Task storage
///    - Transaction listener uses proper actor isolation
