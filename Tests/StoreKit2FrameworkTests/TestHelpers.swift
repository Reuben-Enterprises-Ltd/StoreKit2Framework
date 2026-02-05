import Foundation
@testable import StoreKit2Framework

#if canImport(StoreKit) && canImport(SwiftUI)
import StoreKit
import SwiftUI

/// Mock data and helpers for testing
@MainActor
enum TestHelpers {
    
    // MARK: - Mock PremiumManager Instances
    
    #if DEBUG
    /// Creates a mock PremiumManager instance configured as premium
    /// Note: This uses environment variable override which only works in DEBUG builds
    static func createMockPremiumManager() -> PremiumManager {
        // Use the existing PREMIUM_ENABLED environment variable
        // In tests, we would set this via ProcessInfo mock if needed
        return PremiumManager.shared
    }
    
    /// Creates a mock PremiumManager instance configured as free
    /// Note: This returns the shared instance in its default state
    static func createMockFreeManager() -> PremiumManager {
        // Return shared instance - it will be free if no override is set
        return PremiumManager.shared
    }
    #endif
    
    // MARK: - Test Product Identifiers
    
    /// Test product identifiers for use in tests
    enum TestProductIdentifiers {
        static let monthly = "com.yourcompany.yourapp.monthly"
        static let yearly = "com.yourcompany.yourapp.yearly"
        static let lifetime = "com.yourcompany.yourapp.lifetime"
        
        static var all: [String] {
            [monthly, yearly, lifetime]
        }
    }
    
    // MARK: - Mock Product Data
    
    /// Mock product information for testing
    struct MockProductInfo {
        let id: String
        let displayName: String
        let description: String
        let price: Decimal
        let displayPrice: String
        
        static let monthly = MockProductInfo(
            id: TestProductIdentifiers.monthly,
            displayName: "Monthly Premium",
            description: "Full access to all premium features",
            price: 4.99,
            displayPrice: "$4.99"
        )
        
        static let yearly = MockProductInfo(
            id: TestProductIdentifiers.yearly,
            displayName: "Yearly Premium",
            description: "Full access to all premium features for a whole year",
            price: 39.99,
            displayPrice: "$39.99"
        )
        
        static let lifetime = MockProductInfo(
            id: TestProductIdentifiers.lifetime,
            displayName: "Lifetime Premium",
            description: "Unlock all premium features forever with a one-time purchase",
            price: 24.99,
            displayPrice: "$24.99"
        )
        
        static var all: [MockProductInfo] {
            [monthly, yearly, lifetime]
        }
    }
    
    // MARK: - Mock Transaction Data
    
    /// Mock transaction information for testing
    struct MockTransactionInfo {
        let productID: String
        let purchaseDate: Date
        let isVerified: Bool
        
        static func verified(productID: String, purchaseDate: Date = Date()) -> MockTransactionInfo {
            MockTransactionInfo(
                productID: productID,
                purchaseDate: purchaseDate,
                isVerified: true
            )
        }
        
        static func unverified(productID: String, purchaseDate: Date = Date()) -> MockTransactionInfo {
            MockTransactionInfo(
                productID: productID,
                purchaseDate: purchaseDate,
                isVerified: false
            )
        }
    }
    
    // MARK: - Test Utilities
    
    /// Reset UserDefaults cache for testing
    /// Note: Uses the same key as PremiumManager.cachedPremiumStatusKey
    static func clearPremiumCache() {
        UserDefaults.standard.removeObject(forKey: "cachedPremiumStatus")
    }
    
    /// Wait for async operations to complete
    static func waitForAsync(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(for: .seconds(timeout))
    }
}

// MARK: - Debug Testing Extensions

extension PremiumManager {
    #if DEBUG
    /// Creates a mock instance for testing premium state
    /// - Note: This uses the environment variable override
    static func mockPremium() -> PremiumManager {
        // The existing implementation uses PREMIUM_ENABLED environment variable
        // To test, set PREMIUM_ENABLED=1 in scheme or test environment
        return TestHelpers.createMockPremiumManager()
    }
    
    /// Creates a mock instance for testing free state
    /// - Note: This returns the shared instance without premium override
    static func mockFree() -> PremiumManager {
        return TestHelpers.createMockFreeManager()
    }
    #endif
}

#endif
