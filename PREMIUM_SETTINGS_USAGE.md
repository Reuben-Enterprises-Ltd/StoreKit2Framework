# Premium Settings Components Usage Guide

## Overview

The Premium Settings Components provide ready-to-use SwiftUI views for integrating premium features into your app's settings screen. These components offer flexible options for displaying subscription status and managing premium access.

## Available Components

### 1. PremiumSettingsSection
A complete settings section with status display and action buttons.

### 2. PremiumStatusRow
A simple row view designed for use in SwiftUI Lists.

### 3. PremiumBadge
A compact "Pro" badge that appears when the user has premium access.

---

## PremiumSettingsSection

### Description
A comprehensive settings section that displays the user's premium status and provides all necessary actions (upgrade, restore, manage).

### Features
✅ Shows current status (Free / Premium)  
✅ Displays subscription type (Monthly/Yearly/Lifetime)  
✅ Shows renewal/expiry dates  
✅ Upgrade button for free users  
✅ Manage subscription link  
✅ Restore purchases functionality  
✅ Automatic reactive updates  

### Usage

#### Basic Usage in Form
```swift
import SwiftUI
import StoreKit2Framework

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                PremiumSettingsSection()
                
                Section("General") {
                    // Other settings...
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

#### Standalone Usage
```swift
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PremiumSettingsSection()
                    
                    // Other content...
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
}
```

### Visual States

#### Free User
```
┌─────────────────────────────────┐
│ Premium Status                  │
│ ○ Free                          │
│                                 │
│ [★ Upgrade to Premium]          │
│ [↻ Restore Purchases]           │
└─────────────────────────────────┘
```

#### Premium User - Monthly
```
┌─────────────────────────────────┐
│ Premium Status                  │
│ ✓ Premium (Monthly)             │
│ Renews: Mar 5, 2026             │
│                                 │
│ [⚙ Manage Subscription]         │
│ [↻ Restore Purchases]           │
└─────────────────────────────────┘
```

#### Premium User - Lifetime
```
┌─────────────────────────────────┐
│ Premium Status                  │
│ ✓ Premium (Lifetime)            │
│                                 │
│ [⚙ Manage Subscription]         │
│ [↻ Restore Purchases]           │
└─────────────────────────────────┘
```

---

## PremiumStatusRow

### Description
A compact row view that can be embedded in SwiftUI Lists. Perfect for settings screens with a consistent design.

### Features
✅ Shows premium status icon  
✅ Displays subscription type  
✅ Shows "Active" or "Unlock" indicator  
✅ Tappable to upgrade (free users only)  
✅ Integrates seamlessly with List  

### Usage

#### In a List
```swift
import SwiftUI
import StoreKit2Framework

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    PremiumStatusRow()
                }
                
                Section("General") {
                    Text("Notifications")
                    Text("Privacy")
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

#### In Form
```swift
struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                PremiumStatusRow()
            }
            
            Section("Preferences") {
                Toggle("Notifications", isOn: .constant(true))
                Toggle("Dark Mode", isOn: .constant(false))
            }
        }
    }
}
```

### Visual States

#### Free User
```
★ Premium                    Unlock ›
  (gray star)                 (blue)
```

#### Premium User - Active
```
★ Premium                    ✓ Active
  Monthly Subscription       (green)
  (yellow star)
```

---

## PremiumBadge

### Description
A minimal "Pro" badge that automatically appears when the user has premium access and hides when they don't.

### Features
✅ Automatic visibility based on premium status  
✅ Compact design  
✅ Gradient background  
✅ Takes zero space when hidden  

### Usage

#### In Navigation Title
```swift
import SwiftUI
import StoreKit2Framework

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Content")
                .navigationTitle("My App")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("My App")
                                .font(.headline)
                            PremiumBadge()
                        }
                    }
                }
        }
    }
}
```

#### Next to User Name
```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            HStack {
                Text("John Doe")
                    .font(.title)
                PremiumBadge()
            }
            
            // Rest of profile...
        }
    }
}
```

#### In Card Headers
```swift
struct FeatureCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Advanced Analytics")
                    .font(.headline)
                Spacer()
                PremiumBadge()
            }
            
            Text("Deep insights into your data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

### Visual Appearance

#### Premium User
```
┌─────┐
│ Pro │  ← Blue gradient background, white text
└─────┘
```

#### Free User
```
(nothing rendered - takes no space)
```

---

## Integration with PremiumManager

All components automatically integrate with `PremiumManager.shared`:

```swift
// Components observe these properties:
premiumManager.isPremium              // Boolean premium status
premiumManager.activeEntitlement      // Subscription details
```

### Reactive Updates

Because `PremiumManager` is `@Observable`, all components update automatically when premium status changes:

```swift
// When user purchases premium:
// 1. PremiumManager.isPremium changes to true
// 2. All components re-render automatically
// 3. UI shows premium state instantly

// No manual observation required!
```

---

## Complete Settings Example

Here's a complete example combining all components:

```swift
import SwiftUI
import StoreKit2Framework

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                // Option 1: Full section
                PremiumSettingsSection()
                
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text("john_doe")
                            .foregroundStyle(.secondary)
                        PremiumBadge()  // Badge next to username
                    }
                }
                
                Section("General") {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }
                
                Section("About") {
                    Text("Version 1.0.0")
                    Text("Terms of Service")
                    Text("Privacy Policy")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

Or with PremiumStatusRow:

```swift
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    PremiumStatusRow()  // Compact row instead of section
                    
                    HStack {
                        Text("Username")
                        Spacer()
                        Text("john_doe")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("General") {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

---

## Customization

### Opening Paywall from Other Locations

While the components handle showing the paywall internally, you can also show it from elsewhere:

```swift
struct ContentView: View {
    private let premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        VStack {
            if !premiumManager.isPremium {
                Button("Upgrade to Premium") {
                    showingPaywall = true
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}
```

### Manage Subscription Link

The "Manage Subscription" button opens the App Store subscriptions page:

```swift
// This is handled automatically in PremiumSettingsSection
// URL: https://apps.apple.com/account/subscriptions
```

If you need to open it manually:

```swift
import SwiftUI

struct CustomView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button("Manage Subscription") {
            Task {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await openURL(url)
                }
            }
        }
    }
}
```

---

## Testing with Previews

All components include preview providers for testing different states:

```swift
// Free user preview
#Preview("Free User") {
    PremiumSettingsSection()
}

// Premium user preview (will show premium state if PremiumManager has premium)
#Preview("Premium User") {
    PremiumSettingsSection()
}
```

Note: Previews reflect the actual state of `PremiumManager.shared`. To test premium states in previews, you can use the debug override by setting the `PREMIUM_ENABLED=1` environment variable in your scheme.

### Debug Override

For testing in the simulator without actual IAP:

1. Edit your scheme
2. Add environment variable: `PREMIUM_ENABLED=1`
3. Run the app - premium features will be enabled

---

## Best Practices

### 1. Choose the Right Component

- **Use PremiumSettingsSection** when you want a dedicated, detailed premium section
- **Use PremiumStatusRow** when you want premium status alongside other settings
- **Use PremiumBadge** for subtle premium indicators throughout your app

### 2. Placement Recommendations

```swift
// ✅ Good - Premium section first in settings
Form {
    PremiumSettingsSection()
    Section("Account") { ... }
    Section("General") { ... }
}

// ✅ Good - Status row in account section
Form {
    Section("Account") {
        PremiumStatusRow()
        Text("Profile")
        Text("Security")
    }
}

// ✅ Good - Badge for subtle branding
HStack {
    Text("John Doe")
    PremiumBadge()
}
```

### 3. Initialize PremiumManager

Always call `ensureInitialized()` early in your app:

```swift
@main
struct MyApp: App {
    init() {
        PremiumManager.shared.ensureInitialized()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 4. Don't Mix Approaches

```swift
// ❌ Don't use both section and row in same form
Form {
    PremiumSettingsSection()  // Complete section
    Section {
        PremiumStatusRow()    // Redundant!
    }
}

// ✅ Choose one approach
Form {
    PremiumSettingsSection()  // OR PremiumStatusRow, not both
    // Other settings...
}
```

---

## Troubleshooting

### Component Shows "Free" But User is Premium

**Solution:** Ensure `PremiumManager.shared.ensureInitialized()` is called early in app lifecycle.

### "Manage Subscription" Button Not Opening

**Solution:** The URL scheme requires iOS 15+. Ensure your deployment target is set correctly.

### Buttons Not Working

**Solution:** Components require StoreKit and SwiftUI. They're wrapped in `#if canImport(StoreKit) && canImport(SwiftUI)`.

### Preview Not Showing Premium State

**Solution:** Previews use the real `PremiumManager.shared` state. To test premium features in previews:

1. Edit your scheme
2. Add environment variable: `PREMIUM_ENABLED=1`
3. Run the app - premium features will be enabled

Or test on a device/simulator where you've already purchased/restored premium.

---

## Related Documentation

- [PremiumManager Usage Guide](PREMIUM_MANAGER_USAGE.md) - Core premium management
- [PaywallView Usage Guide](PAYWALL_VIEW_USAGE.md) - Paywall component
- [Quick Start Guide](QUICK_START.md) - Getting started
- [STOREKIT_COPILOT_AGENT_GUIDE.md](STOREKIT_COPILOT_AGENT_GUIDE.md) - Complete reference

---

## Support

For issues or questions:
- Check the [README](README.md)
- Review the [STOREKIT_COPILOT_AGENT_GUIDE.md](STOREKIT_COPILOT_AGENT_GUIDE.md)
- Open an issue on GitHub

---

## Summary

The Premium Settings Components provide three flexible ways to integrate premium features into your settings:

| Component | Use Case | Best For |
|-----------|----------|----------|
| `PremiumSettingsSection` | Complete premium section | Dedicated premium settings area |
| `PremiumStatusRow` | Compact status row | Mixed with other settings |
| `PremiumBadge` | Subtle indicator | Profile, navigation, cards |

All components:
- ✅ Are reactive and update automatically
- ✅ Integrate seamlessly with PremiumManager
- ✅ Follow SwiftUI conventions
- ✅ Support all premium states
- ✅ Work in light and dark mode
- ✅ Support Dynamic Type
- ✅ Include comprehensive previews
