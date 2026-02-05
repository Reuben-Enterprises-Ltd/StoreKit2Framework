# Examples

This directory contains example applications demonstrating how to integrate and use the StoreKit2Framework.

## Available Examples

### 📱 DemoApp

**Location:** `Examples/DemoApp/`

A complete iOS app showcasing all framework features and integration patterns.

**Features Demonstrated:**
- Framework initialization
- Onboarding with paywall integration
- Settings with premium management
- Feature gating (multiple patterns)
- Purchase flows
- Subscription management
- Restore purchases
- Premium status display

**Quick Start:**
```bash
cd Examples/DemoApp
open DemoApp.xcodeproj
```

Then select a simulator and press ⌘R to build and run.

**Full Documentation:** See [DemoApp/README.md](DemoApp/README.md)

## Testing StoreKit

All example apps include a StoreKit configuration file for testing in-app purchases without real transactions:

1. Open the project in Xcode
2. Edit the scheme (Product → Scheme → Edit Scheme...)
3. Select "Run" in the left sidebar
4. Go to the "Options" tab
5. Under "StoreKit Configuration", the `DemoApp.storekit` file should already be selected
6. Build and run

You can now test purchases in the simulator without any real App Store setup!

## Integration Steps

To integrate StoreKit2Framework into your own app:

1. **Add the Framework**
   - File → Add Package Dependencies...
   - Enter: `https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework.git`

2. **Initialize**
   ```swift
   import StoreKit2Framework
   
   @main
   struct YourApp: App {
       init() {
           PremiumManager.shared.ensureInitialized()
       }
   }
   ```

3. **Show Paywall**
   ```swift
   .sheet(isPresented: $showPaywall) {
       PaywallView()
   }
   ```

4. **Gate Features**
   ```swift
   PremiumFeature()
       .premiumRequired()
   ```

See the [DemoApp](DemoApp/) for complete examples of all integration patterns.

## Need Help?

- 📖 [Main README](../README.md)
- 🚀 [Quick Start Guide](../QUICK_START.md)
- 🎯 [DemoApp Integration Guide](DemoApp/README.md)
- 💬 [GitHub Discussions](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/discussions)
- 🐛 [Report Issues](https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework/issues)
