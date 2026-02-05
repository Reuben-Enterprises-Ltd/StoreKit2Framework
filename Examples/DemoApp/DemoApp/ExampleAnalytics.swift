import Foundation
import StoreKit
import StoreKit2Framework

/// Example analytics implementation demonstrating how to integrate
/// custom analytics tracking with the StoreKit2Framework
///
/// This example uses simple console logging, but in a real app you would
/// send these events to your analytics service (e.g., Firebase, Mixpanel, Amplitude)
@MainActor
class ExampleAnalytics: PremiumAnalytics {
    
    // MARK: - Singleton
    
    static let shared = ExampleAnalytics()
    
    // MARK: - Properties
    
    /// Track events for debugging/testing
    private var eventLog: [(event: String, timestamp: Date)] = []
    
    private init() {}
    
    // MARK: - PremiumAnalytics Protocol
    
    func trackPaywallShown(source: String) {
        let event = "paywall_shown"
        logEvent(event, parameters: ["source": source])
        
        // In a real app, send to your analytics service:
        // Analytics.logEvent(event, parameters: ["source": source])
        // Mixpanel.track(event, properties: ["source": source])
        // Amplitude.track(event, eventProperties: ["source": source])
    }
    
    func trackPurchaseCompleted(product: Product) {
        let event = "purchase_completed"
        let parameters: [String: Any] = [
            "product_id": product.id,
            "price_string": product.displayPrice,
            "type": product.type.localizedDescription
        ]
        logEvent(event, parameters: parameters)
        
        // In a real app:
        // Analytics.logEvent(event, parameters: parameters)
        // Also consider tracking revenue events with numeric price
        // let priceDouble = NSDecimalNumber(decimal: product.price).doubleValue
        // Analytics.logRevenue(amount: priceDouble, currency: product.priceFormatStyle.currencyCode)
    }
    
    func trackPurchaseFailed(product: Product?, error: Error) {
        let event = "purchase_failed"
        let parameters: [String: Any] = [
            "product_id": product?.id ?? "unknown",
            "error": error.localizedDescription,
            "error_code": (error as NSError).code
        ]
        logEvent(event, parameters: parameters)
        
        // In a real app:
        // Analytics.logEvent(event, parameters: parameters)
    }
    
    func trackPurchaseCancelled(product: Product) {
        let event = "purchase_cancelled"
        let parameters = [
            "product_id": product.id,
            "display_price": product.displayPrice
        ]
        logEvent(event, parameters: parameters)
        
        // In a real app:
        // Analytics.logEvent(event, parameters: parameters)
    }
    
    func trackRestorePurchases(success: Bool) {
        let event = "restore_purchases"
        let parameters = ["success": success]
        logEvent(event, parameters: parameters)
        
        // In a real app:
        // Analytics.logEvent(event, parameters: parameters)
    }
    
    // MARK: - Helper Methods
    
    private func logEvent(_ event: String, parameters: [String: Any]) {
        let timestamp = Date()
        eventLog.append((event: event, timestamp: timestamp))
        
        // Log to console in debug builds
        #if DEBUG
        print("📊 Analytics Event: \(event)")
        print("   Parameters: \(parameters)")
        print("   Timestamp: \(timestamp)")
        #endif
    }
    
    /// Get event log for debugging
    func getEventLog() -> [(event: String, timestamp: Date)] {
        eventLog
    }
    
    /// Clear event log
    func clearEventLog() {
        eventLog.removeAll()
    }
}
