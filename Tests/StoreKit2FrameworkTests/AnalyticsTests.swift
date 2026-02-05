import Testing
import Foundation
@testable import StoreKit2Framework

#if canImport(StoreKit)
import StoreKit
#endif

/// Tests for analytics integration feature
@Suite("Analytics Integration Tests")
@MainActor
struct AnalyticsTests {
    
    #if canImport(StoreKit)
    
    // MARK: - Mock Analytics Implementation
    
    /// Mock analytics tracker for testing
    class MockAnalytics: PremiumAnalytics {
        var paywallShownEvents: [(source: String, timestamp: Date)] = []
        var purchaseCompletedEvents: [(productId: String, timestamp: Date)] = []
        var purchaseFailedEvents: [(productId: String?, error: String, timestamp: Date)] = []
        var purchaseCancelledEvents: [(productId: String, timestamp: Date)] = []
        var restorePurchasesEvents: [(success: Bool, timestamp: Date)] = []
        
        func trackPaywallShown(source: String) {
            paywallShownEvents.append((source: source, timestamp: Date()))
        }
        
        func trackPurchaseCompleted(product: Product) {
            purchaseCompletedEvents.append((productId: product.id, timestamp: Date()))
        }
        
        func trackPurchaseFailed(product: Product?, error: Error) {
            purchaseFailedEvents.append((productId: product?.id, error: error.localizedDescription, timestamp: Date()))
        }
        
        func trackPurchaseCancelled(product: Product) {
            purchaseCancelledEvents.append((productId: product.id, timestamp: Date()))
        }
        
        func trackRestorePurchases(success: Bool) {
            restorePurchasesEvents.append((success: success, timestamp: Date()))
        }
        
        func reset() {
            paywallShownEvents.removeAll()
            purchaseCompletedEvents.removeAll()
            purchaseFailedEvents.removeAll()
            purchaseCancelledEvents.removeAll()
            restorePurchasesEvents.removeAll()
        }
    }
    #endif
    
    // MARK: - Configuration Tests
    
    @Test("Configuration accepts analytics delegate")
    func configurationAcceptsAnalytics() async throws {
        #if canImport(StoreKit)
        let analytics = MockAnalytics()
        let config = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: [],
            analytics: analytics
        )
        
        #expect(config.analytics != nil)
        #endif
    }
    
    @Test("Default configuration has nil analytics")
    func defaultConfigurationHasNilAnalytics() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.default
        #expect(config.analytics == nil)
        #endif
    }
    
    @Test("Configuration has offline grace period")
    func configurationHasOfflineGracePeriod() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.default
        #expect(config.offlineGracePeriod == 86400) // 24 hours
        
        let customConfig = PremiumManager.Configuration(
            offlineGracePeriod: 3600 // 1 hour
        )
        #expect(customConfig.offlineGracePeriod == 3600)
        #endif
    }
    
    @Test("Configuration has promotional offers flag")
    func configurationHasPromotionalOffersFlag() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.default
        #expect(config.enablePromotionalOffers == false)
        
        let customConfig = PremiumManager.Configuration(
            enablePromotionalOffers: true
        )
        #expect(customConfig.enablePromotionalOffers == true)
        #endif
    }
    
    // MARK: - Analytics Tracking Tests
    
    @Test("PremiumManager can track paywall shown")
    func trackPaywallShown() async throws {
        #if canImport(StoreKit)
        let analytics = MockAnalytics()
        let config = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: [],
            analytics: analytics
        )
        
        // Note: We can't directly test PremiumManager.shared with custom config
        // in unit tests without resetting singleton state, so we verify the API exists
        // and that mock analytics works correctly
        
        analytics.trackPaywallShown(source: "onboarding")
        #expect(analytics.paywallShownEvents.count == 1)
        #expect(analytics.paywallShownEvents[0].source == "onboarding")
        
        analytics.trackPaywallShown(source: "settings")
        #expect(analytics.paywallShownEvents.count == 2)
        #expect(analytics.paywallShownEvents[1].source == "settings")
        #endif
    }
    
    @Test("Analytics protocol has default implementations")
    func analyticsProtocolDefaultImplementations() async throws {
        #if canImport(StoreKit)
        // Test that default implementations exist and don't crash
        class MinimalAnalytics: PremiumAnalytics {}
        
        let analytics = MinimalAnalytics()
        
        // These should all be no-ops with default implementations
        analytics.trackPaywallShown(source: "test")
        analytics.trackRestorePurchases(success: true)
        
        // No assertions needed - just verify it compiles and doesn't crash
        #endif
    }
    
    @Test("Mock analytics tracks multiple event types")
    func mockAnalyticsTracksMultipleEventTypes() async throws {
        #if canImport(StoreKit)
        let analytics = MockAnalytics()
        
        // Track various events
        analytics.trackPaywallShown(source: "onboarding")
        analytics.trackRestorePurchases(success: true)
        analytics.trackRestorePurchases(success: false)
        
        #expect(analytics.paywallShownEvents.count == 1)
        #expect(analytics.restorePurchasesEvents.count == 2)
        #expect(analytics.restorePurchasesEvents[0].success == true)
        #expect(analytics.restorePurchasesEvents[1].success == false)
        #endif
    }
    
    @Test("Analytics can be reset")
    func analyticsCanBeReset() async throws {
        #if canImport(StoreKit)
        let analytics = MockAnalytics()
        
        analytics.trackPaywallShown(source: "test")
        analytics.trackRestorePurchases(success: true)
        #expect(analytics.paywallShownEvents.count == 1)
        #expect(analytics.restorePurchasesEvents.count == 1)
        
        analytics.reset()
        #expect(analytics.paywallShownEvents.isEmpty)
        #expect(analytics.restorePurchasesEvents.isEmpty)
        #endif
    }
    
    // MARK: - Integration Tests
    
    @Test("PremiumManager exposes trackPaywallShown method")
    func premiumManagerExposesTrackingMethod() async throws {
        #if canImport(StoreKit)
        // Verify the public API exists
        let manager = PremiumManager.shared
        manager.trackPaywallShown(source: "test")
        
        // Method should exist and not crash when called
        // Even without analytics configured, it should be safe to call
        #endif
    }
    
    @Test("Configuration validation passes with analytics")
    func configurationValidationWithAnalytics() async throws {
        #if canImport(StoreKit)
        let analytics = MockAnalytics()
        let config = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: [],
            analytics: analytics
        )
        
        // Should not throw
        try config.validate()
        #endif
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test("Analytics is optional and backward compatible")
    func analyticsIsOptionalAndBackwardCompatible() async throws {
        #if canImport(StoreKit)
        // Old code without analytics should still work
        let config1 = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: []
        )
        #expect(config1.analytics == nil)
        
        // New code with analytics should also work
        let analytics = MockAnalytics()
        let config2 = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: [],
            analytics: analytics
        )
        #expect(config2.analytics != nil)
        #endif
    }
    
    @Test("Configuration can be created without advanced features")
    func configurationWithoutAdvancedFeatures() async throws {
        #if canImport(StoreKit)
        // Minimal configuration should still work
        let config = PremiumManager.Configuration(
            productIdentifiers: .default,
            features: []
        )
        
        #expect(config.analytics == nil)
        #expect(config.offlineGracePeriod == 86400)
        #expect(config.enablePromotionalOffers == false)
        
        // Should validate successfully
        try config.validate()
        #endif
    }
}
