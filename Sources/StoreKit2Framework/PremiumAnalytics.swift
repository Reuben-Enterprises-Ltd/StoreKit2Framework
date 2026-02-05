#if canImport(StoreKit) && canImport(SwiftUI)
import Foundation
import StoreKit

/// Protocol for analytics integration with the premium subscription framework.
///
/// Implement this protocol to receive analytics events from the framework.
/// All methods have default no-op implementations, so you only need to implement
/// the events you care about tracking.
///
/// ## Overview
///
/// The framework calls your analytics delegate at key points in the subscription lifecycle:
/// - When users see the paywall
/// - When purchases succeed, fail, or are cancelled
/// - When purchases are restored
///
/// This enables you to:
/// - Track conversion funnels
/// - Measure revenue
/// - Understand user behavior
/// - Optimize pricing and messaging
///
/// ## Privacy
///
/// All analytics events are opt-in and respect user privacy:
/// - Events only track high-level actions, not user data
/// - No personal information is included in events
/// - You are responsible for your own privacy compliance
/// - Consider user consent before tracking
///
/// ## Implementation Example
///
/// ```swift
/// import StoreKit2Framework
/// import FirebaseAnalytics
///
/// class MyAnalytics: PremiumAnalytics {
///     func trackPaywallShown(source: String) {
///         Analytics.logEvent("paywall_shown", parameters: [
///             "source": source
///         ])
///     }
///
///     func trackPurchaseCompleted(product: Product) {
///         Analytics.logEvent("purchase", parameters: [
///             "product_id": product.id,
///             "price": product.price as NSNumber,
///             "currency": product.priceFormatStyle.currencyCode ?? "USD"
///         ])
///     }
///
///     func trackPurchaseFailed(product: Product?, error: Error) {
///         Analytics.logEvent("purchase_failed", parameters: [
///             "error": error.localizedDescription
///         ])
///     }
/// }
///
/// // Configure with analytics
/// let config = PremiumManager.Configuration(
///     productIdentifiers: .default,
///     features: [],
///     analytics: MyAnalytics()
/// )
/// PremiumManager.shared.configure(config)
/// ```
///
/// ## Topics
///
/// ### Event Tracking
///
/// - ``trackPaywallShown(source:)``
/// - ``trackPurchaseCompleted(product:)``
/// - ``trackPurchaseFailed(product:error:)``
/// - ``trackPurchaseCancelled(product:)``
/// - ``trackRestorePurchases(success:)``
///
/// - Note: This protocol is marked `@MainActor` for thread safety.
@MainActor
public protocol PremiumAnalytics {
    /// Called when the paywall is shown to the user.
    ///
    /// Track this to understand where users encounter the paywall
    /// and measure conversion rates by source.
    ///
    /// - Parameter source: The source/context where paywall was shown
    ///
    /// ## Common Sources
    /// - `"onboarding"`: During initial app setup
    /// - `"settings"`: User-initiated from settings
    /// - `"feature_gate"`: Attempting to access premium feature
    /// - `"feature_limit"`: When user hits a usage limit
    func trackPaywallShown(source: String)
    
    /// Called when a purchase is successfully completed.
    ///
    /// Track this to measure revenue and understand which products users prefer.
    ///
    /// - Parameter product: The product that was purchased
    ///
    /// ## Example
    ///
    /// ```swift
    /// func trackPurchaseCompleted(product: Product) {
    ///     Analytics.logEvent("purchase", parameters: [
    ///         "product_id": product.id,
    ///         "value": product.price as NSNumber,
    ///         "currency": product.priceFormatStyle.currencyCode ?? "USD"
    ///     ])
    /// }
    /// ```
    func trackPurchaseCompleted(product: Product)
    
    /// Called when a purchase fails.
    ///
    /// Track this to identify and resolve purchase issues.
    ///
    /// - Parameters:
    ///   - product: The product that failed to purchase (may be nil)
    ///   - error: The error that occurred
    ///
    /// ## Example
    ///
    /// ```swift
    /// func trackPurchaseFailed(product: Product?, error: Error) {
    ///     Analytics.logEvent("purchase_failed", parameters: [
    ///         "product_id": product?.id ?? "unknown",
    ///         "error": error.localizedDescription,
    ///         "error_code": (error as NSError).code
    ///     ])
    /// }
    /// ```
    func trackPurchaseFailed(product: Product?, error: Error)
    
    /// Called when the user cancels a purchase.
    ///
    /// Track this to understand drop-off in the purchase flow.
    ///
    /// - Parameter product: The product that was being purchased
    ///
    /// - Note: This is not an error condition - user intentionally cancelled.
    func trackPurchaseCancelled(product: Product)
    
    /// Called when purchases are restored.
    ///
    /// Track this to monitor restore success rates and identify issues.
    ///
    /// - Parameter success: Whether restoration was successful
    ///
    /// ## Example
    ///
    /// ```swift
    /// func trackRestorePurchases(success: Bool) {
    ///     Analytics.logEvent("restore_purchases", parameters: [
    ///         "success": success
    ///     ])
    /// }
    /// ```
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
