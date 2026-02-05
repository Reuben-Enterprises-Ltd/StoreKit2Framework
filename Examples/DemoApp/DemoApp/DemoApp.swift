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
                .init(title: "Unlimited exports", systemImageName: "square.and.arrow.up"),
                .init(title: "Advanced analytics", systemImageName: "chart.xyaxis.line"),
                .init(title: "Cloud sync", systemImageName: "icloud.and.arrow.up"),
                .init(title: "Priority support", systemImageName: "person.fill.questionmark"),
                .init(title: "Remove ads", systemImageName: "nosign"),
                .init(title: "Custom themes", systemImageName: "paintbrush.pointed")
            ],
            enableDebugMode: true,
            cacheKey: "demo_app_premium_status",
            analytics: ExampleAnalytics.shared
            // Legal URLs use defaults:
            // - privacyPolicyURL: https://support.reubenenterprises.com/privacy
            // - termsOfServiceURL: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
            // To customize, add: privacyPolicyURL: URL(string: "https://yourapp.com/privacy")!
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
