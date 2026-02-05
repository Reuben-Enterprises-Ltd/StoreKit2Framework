import SwiftUI
import StoreKit2Framework

/// Demo App Entry Point
///
/// This demonstrates the recommended way to initialize the StoreKit2Framework
/// with custom configuration. Configure the PremiumManager before calling
/// ensureInitialized() to customize product IDs and features.
@main
struct DemoApp: App {
    
    init() {
        // Configure PremiumManager with custom settings
        let config = PremiumManager.Configuration(
            productIdentifiers: PremiumManager.ProductIdentifiers(
                monthly: "com.yourcompany.yourapp.monthly",
                yearly: "com.yourcompany.yourapp.yearly",
                lifetime: "com.yourcompany.yourapp.lifetime"
            ),
            features: [
                "Unlimited exports",
                "Advanced analytics",
                "Cloud sync",
                "Priority support",
                "Remove ads",
                "Custom themes"
            ],
            enableDebugMode: true,
            cacheKey: "demo_app_premium_status"
        )
        
        // Apply configuration before initialization
        PremiumManager.shared.configure(config)
        
        // Initialize the premium manager to load products and check status
        // This ensures premium state is available by the time views appear
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
