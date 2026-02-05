# PaywallView Usage Guide

The `PaywallView` is a beautiful, reusable SwiftUI component that displays available products and handles the purchase flow with a clean, modern design.

## Basic Usage

### Simple Presentation

```swift
import SwiftUI
import StoreKit2Framework

struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Go Premium") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
```

### With Custom Headline

```swift
.sheet(isPresented: $showPaywall) {
    PaywallView(headline: "Unlock Premium Features")
}

// Or for feature-specific context
.sheet(isPresented: $showPaywall) {
    PaywallView(headline: "Go Pro to Continue")
}
```

### Full Screen Presentation

```swift
.fullScreenCover(isPresented: $showPaywall) {
    PaywallView(headline: "Upgrade to Premium")
}
```

### In Navigation

```swift
NavigationLink {
    PaywallView(headline: "Premium Access")
} label: {
    Text("Upgrade to Premium")
}
```

## Customization

### Custom Benefits List

```swift
let customBenefits = [
    BenefitItem(
        icon: "star.fill",
        title: "Unlimited Access",
        description: "No restrictions or limits"
    ),
    BenefitItem(
        icon: "chart.bar.fill",
        title: "Advanced Analytics",
        description: "Detailed insights and reports"
    ),
    BenefitItem(
        icon: "icloud.fill",
        title: "Cloud Sync",
        description: "Access on all your devices"
    ),
    BenefitItem(
        icon: "paintbrush.fill",
        title: "Premium Themes",
        description: "Exclusive design options"
    )
]

PaywallView(
    headline: "Unlock All Features",
    benefits: customBenefits
)
```

### With Legal Links (Required for App Store)

```swift
PaywallView(
    headline: "Go Premium",
    benefits: customBenefits,
    privacyPolicyURL: URL(string: "https://yourapp.com/privacy"),
    termsOfServiceURL: URL(string: "https://yourapp.com/terms")
)
```

## Features

### Automatic Product Loading
- Products are loaded automatically from the App Store when the view appears
- Shows a loading indicator while fetching products
- Displays an error view with retry if loading fails

### Product Selection
- All available products are displayed (monthly, yearly, lifetime)
- Yearly subscription is highlighted as "Best Value"
- Shows monthly price breakdown for yearly plans
- Displays savings percentage
- Visual feedback for selected product

### Purchase Flow
1. User selects a product
2. Taps "Start Premium" button
3. Loading indicator appears during purchase
4. On success: View dismisses automatically
5. On cancellation: No error shown (normal behavior)
6. On error: Alert with retry option

### Restore Purchases
- Prominent "Restore Purchases" button
- Shows loading state during restore
- Auto-dismisses on successful restoration
- Updates UI based on PremiumManager state

### Error Handling
- Product loading errors show error section with retry
- Purchase errors show alert with retry option
- Network issues handled gracefully
- User-friendly error messages

### Accessibility
- Uses Dynamic Type for all text
- Semantic colors for light/dark mode support
- Proper VoiceOver labels
- No hardcoded font sizes or colors

## Integration with PremiumManager

The PaywallView works seamlessly with `PremiumManager.shared`:

```swift
// The view automatically:
// 1. Calls premiumManager.ensureInitialized() on appear
// 2. Displays premiumManager.products
// 3. Shows premiumManager.isLoading state
// 4. Handles premiumManager.error
// 5. Calls premiumManager.purchase(_:) for purchases
// 6. Calls premiumManager.restorePurchases() for restore
```

## Presentation Patterns

### Feature-Gated Access

```swift
struct PremiumFeatureView: View {
    @State private var showPaywall = false
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        if premiumManager.isPremium {
            // Show premium content
            PremiumContent()
        } else {
            // Show paywall or upgrade prompt
            Button("Unlock This Feature") {
                showPaywall = true
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(headline: "Unlock Premium Features")
            }
        }
    }
}
```

### Onboarding Flow

```swift
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Onboarding pages...
            
            // Final page with paywall
            PaywallView(headline: "Start Your Premium Experience")
                .tag(3)
        }
        .tabViewStyle(.page)
    }
}
```

### Settings Integration

```swift
struct SettingsView: View {
    @State private var showPaywall = false
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        Form {
            Section("Premium") {
                if premiumManager.isPremium {
                    Label("Premium Active", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Upgrade to Premium") {
                        showPaywall = true
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(headline: "Unlock All Features")
        }
    }
}
```

## Best Practices

### Do's
✅ Present early in user journey when appropriate  
✅ Provide clear value proposition in headline  
✅ Customize benefits to match your app's features  
✅ Include privacy policy and terms links (required by App Store)  
✅ Test with real product IDs in production  
✅ Use StoreKit Configuration file for testing  

### Don'ts
❌ Don't show paywall on every app launch (annoying)  
❌ Don't block core functionality behind paywall  
❌ Don't use aggressive or dark patterns  
❌ Don't forget to test purchase and restore flows  
❌ Don't hardcode product IDs in the view (use PremiumManager)  

## SwiftUI Previews

The PaywallView includes preview providers for development:

```swift
#Preview {
    PaywallView(
        headline: "Go Pro to Continue",
        privacyPolicyURL: URL(string: "https://example.com/privacy"),
        termsOfServiceURL: URL(string: "https://example.com/terms")
    )
}

#Preview("Custom Benefits") {
    PaywallView(
        headline: "Unlock Premium Features",
        benefits: [
            BenefitItem(
                icon: "star.fill",
                title: "Unlimited Access",
                description: "No restrictions or limits"
            ),
            BenefitItem(
                icon: "trophy.fill",
                title: "Exclusive Features",
                description: "Premium-only tools and options"
            )
        ],
        privacyPolicyURL: URL(string: "https://example.com/privacy"),
        termsOfServiceURL: URL(string: "https://example.com/terms")
    )
}
```

## Testing

### StoreKit Configuration
Create a StoreKit Configuration file in Xcode to test purchases without real transactions:
1. File → New → StoreKit Configuration File
2. Add your products with IDs matching `PremiumManager.ProductIdentifiers`
3. Run your app with the configuration file selected

### Simulator Testing
- Test purchase flow
- Test restore purchases
- Test error handling
- Test different product types (monthly, yearly, lifetime)
- Test dark/light mode appearance
- Test Dynamic Type sizes

## Troubleshooting

### Products Not Loading
- Verify product IDs in `PremiumManager.ProductIdentifiers`
- Check StoreKit Configuration file is selected
- Ensure valid App Store Connect setup for production

### Purchases Not Working
- Verify in-app purchase capability is enabled
- Check App Store Connect agreement status
- Ensure products are in "Ready to Submit" status
- Test with sandbox Apple ID

### UI Issues
- Check Dynamic Type support
- Verify light/dark mode appearance
- Test on different screen sizes
- Ensure no hardcoded colors or fonts

## See Also

- `PremiumManager` - Core purchase logic
- `PREMIUM_MANAGER_USAGE.md` - PremiumManager documentation
- `QUICK_START.md` - Quick start guide
- Apple's [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
