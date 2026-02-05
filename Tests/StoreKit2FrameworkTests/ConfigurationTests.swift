import Testing
@testable import StoreKit2Framework
import Foundation

#if canImport(StoreKit)
import StoreKit
#endif

/// Comprehensive tests for Configuration System
@Suite("Configuration System Tests")
struct ConfigurationTests {
    
    // MARK: - ProductIdentifiers Tests
    
    @Test("ProductIdentifiers initializes with all parameters")
    func productIdentifiersInit() async throws {
        #if canImport(StoreKit)
        let ids = PremiumManager.ProductIdentifiers(
            monthly: "com.test.monthly",
            yearly: "com.test.yearly",
            lifetime: "com.test.lifetime"
        )
        
        #expect(ids.monthly == "com.test.monthly")
        #expect(ids.yearly == "com.test.yearly")
        #expect(ids.lifetime == "com.test.lifetime")
        #expect(ids.all.count == 3)
        #endif
    }
    
    @Test("ProductIdentifiers initializes without lifetime")
    func productIdentifiersWithoutLifetime() async throws {
        #if canImport(StoreKit)
        let ids = PremiumManager.ProductIdentifiers(
            monthly: "com.test.monthly",
            yearly: "com.test.yearly"
        )
        
        #expect(ids.monthly == "com.test.monthly")
        #expect(ids.yearly == "com.test.yearly")
        #expect(ids.lifetime == nil)
        #expect(ids.all.count == 2)
        #endif
    }
    
    @Test("ProductIdentifiers all property excludes nil lifetime")
    func productIdentifiersAllExcludesNil() async throws {
        #if canImport(StoreKit)
        let ids = PremiumManager.ProductIdentifiers(
            monthly: "com.test.monthly",
            yearly: "com.test.yearly",
            lifetime: nil
        )
        
        let all = ids.all
        #expect(all.count == 2)
        #expect(all.contains("com.test.monthly"))
        #expect(all.contains("com.test.yearly"))
        #expect(!all.contains { $0.isEmpty })
        #endif
    }
    
    @Test("ProductIdentifiers default contains all products")
    func productIdentifiersDefault() async throws {
        #if canImport(StoreKit)
        let ids = PremiumManager.ProductIdentifiers.default
        
        #expect(!ids.monthly.isEmpty)
        #expect(!ids.yearly.isEmpty)
        #expect(ids.lifetime != nil)
        #expect(ids.all.count == 3)
        #endif
    }
    
    // MARK: - Configuration Tests
    
    @Test("Configuration initializes with default values")
    func configurationDefaultInit() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration()
        
        #expect(!config.productIdentifiers.monthly.isEmpty)
        #expect(!config.productIdentifiers.yearly.isEmpty)
        #expect(config.features.isEmpty)
        #expect(config.enableDebugMode == false)
        #expect(config.cacheKey == "premium_status")
        #endif
    }
    
    @Test("Configuration initializes with custom values")
    func configurationCustomInit() async throws {
        #if canImport(StoreKit)
        let customIds = PremiumManager.ProductIdentifiers(
            monthly: "com.custom.monthly",
            yearly: "com.custom.yearly",
            lifetime: "com.custom.lifetime"
        )
        
        let config = PremiumManager.Configuration(
            productIdentifiers: customIds,
            features: ["Feature 1", "Feature 2", "Feature 3"],
            enableDebugMode: true,
            cacheKey: "custom_key"
        )
        
        #expect(config.productIdentifiers.monthly == "com.custom.monthly")
        #expect(config.features.count == 3)
        #expect(config.enableDebugMode == true)
        #expect(config.cacheKey == "custom_key")
        #endif
    }
    
    @Test("Configuration default preset is valid")
    func configurationDefaultPreset() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.default
        
        #expect(!config.productIdentifiers.monthly.isEmpty)
        #expect(!config.productIdentifiers.yearly.isEmpty)
        #expect(config.features.count > 0)
        #expect(config.enableDebugMode == false)
        #endif
    }
    
    @Test("Configuration debug preset has debug enabled")
    func configurationDebugPreset() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.debug
        
        #expect(config.enableDebugMode == true)
        #expect(!config.productIdentifiers.monthly.isEmpty)
        #endif
    }
    
    @Test("Configuration production preset has debug disabled")
    func configurationProductionPreset() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration.production
        
        #expect(config.enableDebugMode == false)
        #expect(!config.productIdentifiers.monthly.isEmpty)
        #endif
    }
    
    // MARK: - Validation Tests
    
    @Test("Valid configuration passes validation")
    func validConfigurationValidates() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "com.test.yearly",
                lifetime: "com.test.lifetime"
            ),
            features: ["Feature 1", "Feature 2"],
            enableDebugMode: false,
            cacheKey: "test_key"
        )
        
        // Should not throw
        try config.validate()
        #endif
    }
    
    @Test("Empty monthly product ID fails validation")
    func emptyMonthlyProductIDFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "",
                yearly: "com.test.yearly",
                lifetime: "com.test.lifetime"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Empty yearly product ID fails validation")
    func emptyYearlyProductIDFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "",
                lifetime: "com.test.lifetime"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Invalid monthly product ID format fails validation")
    func invalidMonthlyFormatFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "invalidformat",
                yearly: "com.test.yearly",
                lifetime: "com.test.lifetime"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Invalid yearly product ID format fails validation")
    func invalidYearlyFormatFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "invalidformat",
                lifetime: "com.test.lifetime"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Invalid lifetime product ID format fails validation")
    func invalidLifetimeFormatFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "com.test.yearly",
                lifetime: "invalidformat"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Duplicate product IDs fail validation")
    func duplicateProductIDsFail() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.same",
                yearly: "com.test.same",
                lifetime: "com.test.lifetime"
            )
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Empty cache key fails validation")
    func emptyCacheKeyFails() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "com.test.yearly"
            ),
            cacheKey: ""
        )
        
        #expect(throws: ConfigurationError.self) {
            try config.validate()
        }
        #endif
    }
    
    @Test("Configuration without lifetime is valid")
    func configurationWithoutLifetimeIsValid() async throws {
        #if canImport(StoreKit)
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.test.monthly",
                yearly: "com.test.yearly",
                lifetime: nil
            ),
            features: ["Feature 1"]
        )
        
        // Should not throw
        try config.validate()
        #endif
    }
    
    // MARK: - PremiumManager Configure Tests
    
    @Test("PremiumManager accepts configuration")
    func premiumManagerAcceptsConfiguration() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.configured.monthly",
                yearly: "com.configured.yearly"
            ),
            features: ["Configured Feature"]
        )
        
        // Configure should not throw
        manager.configure(config)
        
        // Verify configuration was applied
        let currentConfig = manager.currentConfiguration
        #expect(currentConfig.productIdentifiers.monthly == "com.configured.monthly")
        #expect(currentConfig.features.contains("Configured Feature"))
        #endif
    }
    
    @Test("PremiumManager currentConfiguration is accessible")
    func currentConfigurationAccessible() async throws {
        #if canImport(StoreKit)
        let manager = PremiumManager.shared
        let config = manager.currentConfiguration
        
        // Should have valid configuration
        #expect(!config.productIdentifiers.monthly.isEmpty)
        #expect(!config.productIdentifiers.yearly.isEmpty)
        #endif
    }
    
    // MARK: - ConfigurationError Tests
    
    @Test("ConfigurationError has descriptive messages")
    func configurationErrorDescriptions() async throws {
        #if canImport(StoreKit)
        let emptyIDError = ConfigurationError.emptyProductID(field: "monthly")
        let invalidFormatError = ConfigurationError.invalidProductIDFormat(id: "badid")
        let duplicateError = ConfigurationError.duplicateProductIDs
        let emptyCacheError = ConfigurationError.emptyCacheKey
        
        #expect(emptyIDError.errorDescription != nil)
        #expect(invalidFormatError.errorDescription != nil)
        #expect(duplicateError.errorDescription != nil)
        #expect(emptyCacheError.errorDescription != nil)
        
        #expect(emptyIDError.errorDescription?.contains("monthly") == true)
        #expect(invalidFormatError.errorDescription?.contains("badid") == true)
        #endif
    }
    
    @Test("ConfigurationError conforms to LocalizedError")
    func configurationErrorLocalized() async throws {
        #if canImport(StoreKit)
        let error: LocalizedError = ConfigurationError.emptyProductID(field: "test")
        #expect(error.errorDescription != nil)
        #endif
    }
    
    // MARK: - PaywallConfiguration Tests
    
    @Test("PaywallConfiguration initializes with defaults")
    func paywallConfigurationDefaults() async throws {
        #if canImport(StoreKit)
        let config = PaywallConfiguration()
        
        #expect(config.headline == "Unlock Premium Features")
        #expect(config.features.isEmpty)
        #expect(config.showRestoreButton == true)
        #expect(config.showPrivacyLinks == true)
        #expect(config.tintColor == nil)
        #endif
    }
    
    @Test("PaywallConfiguration initializes with custom values")
    func paywallConfigurationCustom() async throws {
        #if canImport(StoreKit)
        let config = PaywallConfiguration(
            headline: "Custom Headline",
            features: ["Feature 1", "Feature 2"],
            showRestoreButton: false,
            showPrivacyLinks: false,
            tintColor: .red
        )
        
        #expect(config.headline == "Custom Headline")
        #expect(config.features.count == 2)
        #expect(config.showRestoreButton == false)
        #expect(config.showPrivacyLinks == false)
        #expect(config.tintColor != nil)
        #endif
    }
    
    @Test("PaywallConfiguration default preset is valid")
    func paywallConfigurationDefaultPreset() async throws {
        #if canImport(StoreKit)
        let config = PaywallConfiguration.default
        
        #expect(!config.headline.isEmpty)
        #expect(config.showRestoreButton == true)
        #expect(config.showPrivacyLinks == true)
        #endif
    }
    
    // MARK: - Integration Tests
    
    @Test("Configuration and PaywallConfiguration work together")
    func configurationIntegration() async throws {
        #if canImport(StoreKit)
        let managerConfig = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.integration.monthly",
                yearly: "com.integration.yearly"
            ),
            features: ["Integration Feature 1", "Integration Feature 2"]
        )
        
        let paywallConfig = PaywallConfiguration(
            headline: "Integration Test",
            features: managerConfig.features
        )
        
        #expect(paywallConfig.features.count == 2)
        #expect(paywallConfig.features.contains("Integration Feature 1"))
        #endif
    }
}
