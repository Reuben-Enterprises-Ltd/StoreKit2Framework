#if canImport(StoreKit) && canImport(SwiftUI)
import Foundation
import StoreKit

/// Protocol for analytics integration with the Premium framework
///
/// Implement this protocol to receive analytics events from the Premium framework.
/// All methods are optional and will only be called when analytics is enabled
/// in the configuration.
///
/// ## Privacy
/// All analytics events are opt-in and respect user privacy:
/// - Events only track high-level actions, not user data
/// - No personal information is included in events
/// - Integrators are responsible for their own privacy compliance
///
/// ## Example Implementation
/// ```swift
/// class MyAnalytics: PremiumAnalytics {
///     func trackPaywallShown(source: String) {
///         // Send to your analytics service
///         Analytics.log("paywall_shown", parameters: ["source": source])
///     }
///
///     func trackPurchaseCompleted(product: Product) {
///         // Track successful purchase
///         Analytics.log("purchase_completed", parameters: [
///             "product_id": product.id,
///             "price": product.displayPrice
///         ])
///     }
/// }
///
/// // Configure analytics
/// let config = PremiumManager.Configuration(
///     productIdentifiers: .default,
///     features: [],
///     analytics: MyAnalytics()
/// )
/// PremiumManager.shared.configure(config)
/// ```
@MainActor
public protocol PremiumAnalytics {
    /// Called when the paywall is shown to the user
    /// - Parameter source: The source/context where paywall was shown (e.g., "onboarding", "settings", "feature_gate")
    func trackPaywallShown(source: String)
    
    /// Called when a purchase is successfully completed
    /// - Parameter product: The product that was purchased
    func trackPurchaseCompleted(product: Product)
    
    /// Called when a purchase fails
    /// - Parameters:
    ///   - product: The product that failed to purchase (if available)
    ///   - error: The error that occurred
    func trackPurchaseFailed(product: Product?, error: Error)
    
    /// Called when the user cancels a purchase
    /// - Parameter product: The product that was being purchased
    func trackPurchaseCancelled(product: Product)
    
    /// Called when purchases are restored
    /// - Parameter success: Whether restoration was successful
    func trackRestorePurchases(success: Bool)
}

// MARK: - Default Implementations

public extension PremiumAnalytics {
    /// Default implementation (no-op) - can be overridden
    func trackPaywallShown(source: String) {}
    
    /// Default implementation (no-op) - can be overridden
    func trackPurchaseCompleted(product: Product) {}
    
    /// Default implementation (no-op) - can be overridden
    func trackPurchaseFailed(product: Product?, error: Error) {}
    
    /// Default implementation (no-op) - can be overridden
    func trackPurchaseCancelled(product: Product) {}
    
    /// Default implementation (no-op) - can be overridden
    func trackRestorePurchases(success: Bool) {}
}

#endif
