# Issue 007: Example App / Demo

## Priority
**High** - Critical for documentation and validation

## Description
Create a complete example iOS app that demonstrates how to integrate and use the StoreKit2Framework. This serves as both documentation and validation that the framework works as intended.

## Requirements

### Example App Structure
```
Examples/
└── DemoApp/
    ├── DemoApp.swift (app entry point)
    ├── ContentView.swift (main interface)
    ├── OnboardingView.swift (shows paywall integration)
    ├── SettingsView.swift (shows settings integration)
    ├── FeaturesView.swift (shows feature gating)
    └── DemoApp.storekit (test products)
```

### Demonstrated Features

#### 1. App Initialization
Show proper framework initialization:
```swift
@main
struct DemoApp: App {
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

#### 2. Onboarding Integration
- Show paywall during onboarding flow
- "Skip" vs "Upgrade" options
- Smooth transition to main app

#### 3. Settings Integration
- Premium status display
- Subscription management
- Restore purchases

#### 4. Feature Gating Examples
- Free features available
- Premium features locked with visual indicators
- Unlock prompts
- Various gating patterns

#### 5. Strategic Paywall Triggers
- Limit reached (e.g., "You've used 3 of 3 free exports")
- Feature tap (e.g., tap locked feature)
- Settings upgrade button
- Explicit "Go Premium" button

### UI Screens

**Home Screen**
- List of features (some free, some premium)
- Premium badge in navigation
- Settings button

**Feature List**
- ✓ Basic Features (free)
- 🔒 Advanced Features (premium)
- Clear value proposition

**Settings**
- Premium status section
- Upgrade/Manage buttons
- App info

## Acceptance Criteria
- [ ] Separate example app target created
- [ ] Framework added via Swift Package Manager (local path)
- [ ] All integration patterns demonstrated
- [ ] Clean, well-commented code
- [ ] Screenshots in README
- [ ] Step-by-step integration guide
- [ ] Works in Simulator with StoreKit config
- [ ] Builds and runs without errors
- [ ] Follows all Swift/SwiftUI guidelines
- [ ] Demonstrates both success and error states

## Documentation to Include
1. How to add framework to project
2. How to initialize framework
3. How to show paywall
4. How to integrate in settings
5. How to gate features
6. How to test with StoreKit config
7. Common pitfalls and solutions

## Technical Notes
- Create as separate target/directory, not in main package
- Use local package dependency for development
- Include comprehensive inline comments
- Make it beautiful - first impression matters
- Show best practices throughout
- Include both SwiftUI patterns

## Files to Create
```
Examples/
└── DemoApp/
    ├── DemoApp.xcodeproj
    ├── DemoApp/
    │   ├── DemoApp.swift
    │   ├── Views/
    │   │   ├── ContentView.swift
    │   │   ├── OnboardingView.swift
    │   │   ├── SettingsView.swift
    │   │   └── FeatureListView.swift
    │   ├── Assets.xcassets
    │   └── DemoApp.storekit
    └── README.md (integration guide)
```

## Related Issues
- Depends on: #001, #002, #003, #004, #005 (All core components)
- Helps validate: #006 (Testing)

## Estimated Effort
6-8 hours
