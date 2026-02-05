# Feature Gating Utilities - Usage Guide

This guide covers how to use the feature gating utilities provided by StoreKit2Framework to lock features behind premium status.

## Overview

Feature gating utilities provide simple SwiftUI view modifiers and components to easily control access to premium features in your app. The framework provides three main modifiers and supporting components:

- **`.premiumOnly()`** - Hides content completely if not premium
- **`.premiumGated(headline:)`** - Shows blur overlay with upgrade button if not premium
- **`.premiumRequired()`** - Disables and shows lock icon if not premium
- **`PremiumOverlay`** - Standalone overlay component for custom implementations

All modifiers automatically react to premium status changes because they use `PremiumManager`'s `@Observable` properties.

## Installation

```swift
import StoreKit2Framework
```

## View Modifiers

### 1. `.premiumOnly()` - Hide Content

Use this modifier to completely hide features that should only be visible to premium users.

#### Example: Hide Navigation Link

```swift
NavigationStack {
    List {
        NavigationLink("Basic Settings") {
            BasicSettingsView()
        }
        
        NavigationLink("Advanced Settings") {
            AdvancedSettingsView()
        }
        .premiumOnly()  // Hidden if not premium
    }
}
```

#### Example: Conditional Section

```swift
Form {
    Section("Basic Features") {
        Toggle("Notifications", isOn: $notifications)
    }
    
    Section("Premium Features") {
        Toggle("Cloud Sync", isOn: $cloudSync)
        Toggle("Advanced Analytics", isOn: $analytics)
    }
    .premiumOnly()  // Entire section hidden if not premium
}
```

#### When to Use

- Features that shouldn't be visible at all to free users
- Menu items that lead to premium-only sections
- Settings that don't apply to free users
- Advanced tools that are premium-exclusive

### 2. `.premiumGated(headline:)` - Show with Overlay

Use this modifier to show content but overlay it with a blur effect and upgrade button when the user isn't premium.

#### Example: Locked Chart

```swift
struct AnalyticsView: View {
    var body: some View {
        VStack {
            Text("Analytics")
                .font(.largeTitle)
            
            ChartView()
                .frame(height: 300)
                .premiumGated(headline: "Unlock Advanced Analytics")
        }
    }
}
```

#### Example: Custom Headline

```swift
PremiumFeatureView()
    .premiumGated(headline: "Go Pro to Access This Feature")
```

#### Default Headline

If you don't provide a headline, it defaults to "Unlock Premium Features":

```swift
MyContentView()
    .premiumGated()  // Uses default headline
```

#### When to Use

- Large content areas where you want to show what's available
- Features where users should see what they're missing
- To encourage upgrades by teasing premium content
- Dashboard widgets or charts

### 3. `.premiumRequired()` - Disable with Lock

Use this modifier to show a feature but disable it with a lock icon when the user isn't premium.

#### Example: Export Button

```swift
Button("Export All Data") {
    exportAllData()
}
.buttonStyle(.borderedProminent)
.premiumRequired()  // Disabled with lock icon if not premium
```

#### Example: Multiple Buttons

```swift
VStack(spacing: 16) {
    Button("Share Report") {
        shareReport()
    }
    .premiumRequired()
    
    Button("Export PDF") {
        exportPDF()
    }
    .premiumRequired()
    
    Button("Sync to Cloud") {
        syncToCloud()
    }
    .premiumRequired()
}
```

#### Behavior

When not premium:
- Button is disabled (cannot be tapped)
- Opacity is reduced to 60%
- Lock icon appears on the trailing edge
- Tapping anywhere shows the paywall

#### When to Use

- Action buttons that require premium
- Toolbar buttons for premium features
- List items that trigger premium actions
- Form buttons that perform premium operations

## PremiumOverlay Component

For more control, use the `PremiumOverlay` component directly.

### Basic Usage

```swift
struct CustomView: View {
    @State private var showPaywall = false
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        ZStack {
            // Your content
            MyPremiumContentView()
            
            // Overlay when not premium
            if !premiumManager.isPremium {
                PremiumOverlay(
                    headline: "Unlock This Feature",
                    showPaywall: $showPaywall
                )
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(headline: "Unlock This Feature")
        }
    }
}
```

### Custom Layout

```swift
ScrollView {
    VStack {
        ContentSection1()
        ContentSection2()
            .overlay {
                if !premiumManager.isPremium {
                    PremiumOverlay(
                        headline: "Pro Feature",
                        showPaywall: $showPaywall
                    )
                }
            }
    }
}
```

## PremiumManager Extension

The framework adds a helper method to `PremiumManager` for programmatic feature gating:

```swift
func requirePremium(feature: String, onUpgrade: @escaping () -> Void)
```

### Example Usage

```swift
func exportData() {
    premiumManager.requirePremium(feature: "Export") {
        // This closure is called if user has premium
        performExport()
    }
    
    // If not premium, show paywall manually
    if !premiumManager.isPremium {
        showPaywall = true
    }
}
```

## Complete Examples

### Example 1: Feature Grid

```swift
struct FeaturesView: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]) {
            FeatureCard(title: "Basic Stats", icon: "chart.bar")
            
            FeatureCard(title: "Advanced Analytics", icon: "chart.line.uptrend.xyaxis")
                .premiumGated(headline: "Unlock Advanced Analytics")
            
            FeatureCard(title: "Export", icon: "square.and.arrow.up")
                .premiumGated(headline: "Unlock Export")
            
            FeatureCard(title: "Cloud Sync", icon: "icloud")
                .premiumGated(headline: "Unlock Cloud Sync")
        }
    }
}
```

### Example 2: Settings Screen

```swift
struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                Toggle("Notifications", isOn: $notifications)
                Toggle("Sounds", isOn: $sounds)
            }
            
            Section("Premium") {
                Button("Advanced Settings") {
                    navigateToAdvancedSettings()
                }
                .premiumRequired()
                
                Button("Manage Cloud Storage") {
                    navigateToCloudStorage()
                }
                .premiumRequired()
            }
            
            PremiumSettingsSection()
        }
    }
}
```

### Example 3: Toolbar Actions

```swift
struct DocumentView: View {
    var body: some View {
        DocumentContent()
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Share") {
                        shareDocument()
                    }
                    
                    Button("Export") {
                        exportDocument()
                    }
                    .premiumRequired()
                    
                    Button("Print") {
                        printDocument()
                    }
                    .premiumRequired()
                }
            }
    }
}
```

### Example 4: Conditional Navigation

```swift
struct MainView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Features") {
                    NavigationLink("Dashboard") {
                        DashboardView()
                    }
                    
                    NavigationLink("Reports") {
                        ReportsView()
                    }
                    
                    NavigationLink("Analytics") {
                        AnalyticsView()
                    }
                    .premiumOnly()
                    
                    NavigationLink("Export Center") {
                        ExportView()
                    }
                    .premiumOnly()
                }
            }
            .navigationTitle("My App")
        }
    }
}
```

### Example 5: Tab Bar

```swift
struct AppTabView: View {
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            
            Tab("Analytics", systemImage: "chart.line.uptrend.xyaxis") {
                if premiumManager.isPremium {
                    AnalyticsView()
                } else {
                    PremiumLockedView(feature: "Analytics")
                }
            }
            
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
```

## Best Practices

### 1. Be Transparent

Don't frustrate users by hiding too much. Let them know what premium offers:

```swift
// ❌ Bad - User doesn't know what they're missing
NavigationLink("Feature") {
    FeatureView()
}
.premiumOnly()

// ✅ Good - User can see what's available
NavigationLink("Advanced Analytics") {
    AnalyticsView()
        .premiumGated(headline: "Unlock Advanced Analytics")
}
```

### 2. Provide Easy Upgrade Path

All modifiers automatically show the paywall when appropriate, but make sure your paywall is configured:

```swift
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

### 3. Use Consistent Terminology

```swift
// Use consistent headlines
.premiumGated(headline: "Unlock Premium Features")
.premiumGated(headline: "Go Pro to Continue")

// Pick one style and stick with it
```

### 4. Don't Overuse Disabled States

```swift
// ❌ Bad - Too many disabled buttons frustrate users
Button("Feature 1") { }.premiumRequired()
Button("Feature 2") { }.premiumRequired()
Button("Feature 3") { }.premiumRequired()
Button("Feature 4") { }.premiumRequired()

// ✅ Good - Hide some, gate others
Button("Feature 1") { }.premiumRequired()
Button("Feature 2") { }
    .premiumGated(headline: "Unlock More Features")
```

### 5. Combine with Premium Badge

```swift
HStack {
    Text("Advanced Settings")
    PremiumBadge()
}
```

## Testing

### Preview Providers

The framework includes preview providers for testing different premium states:

```swift
#Preview("Free User") {
    MyFeatureView()
        .premiumGated(headline: "Unlock Feature")
}

#Preview("Premium User") {
    MyFeatureView()
        .premiumGated(headline: "Unlock Feature")
}
```

### Debug Override

In DEBUG builds, set environment variable to test premium features:

```bash
PREMIUM_ENABLED=1
```

```swift
// In your scheme settings
Environment Variables:
PREMIUM_ENABLED = 1
```

## Automatic Reactivity

All feature gating modifiers automatically update when premium status changes:

```swift
// This view automatically updates when user purchases
struct MyView: View {
    var body: some View {
        ContentView()
            .premiumGated(headline: "Go Pro")
        
        // After purchase completes:
        // - Overlay automatically disappears
        // - Content becomes accessible
        // - No manual refresh needed
    }
}
```

This works because `PremiumManager` is `@Observable`, so SwiftUI automatically re-renders views when `isPremium` changes.

## Integration with Other Components

### With PaywallView

```swift
struct FeatureView: View {
    @State private var showPaywall = false
    
    var body: some View {
        MyContent()
            .premiumGated(headline: "Unlock This Feature")
        // Paywall is shown automatically by the modifier
    }
}
```

### With PremiumSettingsSection

```swift
struct SettingsView: View {
    var body: some View {
        Form {
            PremiumSettingsSection()
            
            Section("Features") {
                Button("Advanced Tools") { }
                    .premiumRequired()
            }
        }
    }
}
```

### With PremiumBadge

```swift
Label {
    HStack {
        Text("Pro Feature")
        PremiumBadge()
    }
} icon: {
    Image(systemName: "star.fill")
}
.premiumRequired()
```

## Troubleshooting

### Modifier Not Working

Ensure `PremiumManager` is initialized:

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

### Paywall Not Showing

Check that you're not in debug mode with premium override:

```swift
// Remove or set to 0 in your scheme:
PREMIUM_ENABLED = 0
```

### UI Not Updating After Purchase

This should happen automatically. If not, verify:

1. `PremiumManager` transaction listener is running
2. Purchase is completing successfully
3. `isPremium` is being set correctly

## API Reference

### View Modifiers

```swift
extension View {
    /// Hides view if not premium
    func premiumOnly() -> some View
    
    /// Shows blur overlay with paywall if not premium
    func premiumGated(headline: String = "Unlock Premium Features") -> some View
    
    /// Disables and shows lock icon if not premium
    func premiumRequired() -> some View
}
```

### Components

```swift
struct PremiumOverlay: View {
    init(headline: String = "Unlock Premium Features", showPaywall: Binding<Bool>)
}
```

### PremiumManager Extension

```swift
extension PremiumManager {
    func requirePremium(feature: String, onUpgrade: @escaping () -> Void)
}
```

## See Also

- [PREMIUM_MANAGER_USAGE.md](PREMIUM_MANAGER_USAGE.md) - Core PremiumManager guide
- [PAYWALL_VIEW_USAGE.md](PAYWALL_VIEW_USAGE.md) - PaywallView usage guide
- [PREMIUM_SETTINGS_USAGE.md](PREMIUM_SETTINGS_USAGE.md) - Settings components guide
- [QUICK_START.md](QUICK_START.md) - Quick start guide

---

**Questions?** Check the example previews in `PremiumFeatureGating.swift` for more usage examples.
