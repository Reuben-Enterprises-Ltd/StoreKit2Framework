import SwiftUI
import StoreKit2Framework

/// Demo App Entry Point
///
/// This demonstrates the recommended way to initialize the StoreKit2Framework.
/// Call `PremiumManager.shared.ensureInitialized()` early in your app's lifecycle
/// to start loading products and checking premium status.
@main
struct DemoApp: App {
    
    init() {
        // Initialize the premium manager early to load products and check status
        // This ensures premium state is available by the time views appear
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
