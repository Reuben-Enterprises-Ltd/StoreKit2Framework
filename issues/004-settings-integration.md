# Issue 004: Settings Integration Component

## Priority
**Medium** - Important for user management

## Description
Create a reusable view/component for integrating premium status into an app's settings screen. Users should be able to see their subscription status and manage it.

## Requirements

### Premium Status Display
- Show current status (Free / Premium)
- For premium users, show:
  - Subscription type (Monthly/Yearly/Lifetime)
  - Renewal date (for subscriptions)
  - Expiry information
  - Manage subscription link (opens App Store)

### Actions Available
- "Upgrade to Premium" button (shows paywall) for free users
- "Restore Purchases" button
- "Manage Subscription" button (opens App Store subscriptions)
- Clear status indicators

### Component Options
Create flexible components that can be used in different ways:

**Option 1**: Complete Settings Section
```swift
PremiumSettingsSection()
```

**Option 2**: Status Row for List
```swift
List {
    PremiumStatusRow()
    // other settings...
}
```

**Option 3**: Badge/Indicator
```swift
PremiumBadge() // Shows "Pro" badge if premium
```

## Acceptance Criteria
- [ ] PremiumSettingsSection view created
- [ ] PremiumStatusRow view created
- [ ] PremiumBadge view created
- [ ] Shows accurate subscription information
- [ ] Links to App Store subscription management work
- [ ] Integrates with PremiumManager
- [ ] Updates reactively when status changes
- [ ] Handles all premium states (free, monthly, yearly, lifetime)
- [ ] Preview providers for all states
- [ ] Follows SwiftUI conventions

## Technical Notes
- Reference STOREKIT_COPILOT_AGENT_GUIDE.md lines 725-786
- Use `PremiumManager.shared.isPremium` for status
- Use `PremiumManager.shared.activeEntitlement` for details
- Open subscription management:
  ```swift
  if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
      await UIApplication.shared.open(url)
  }
  ```
- Consider using `@Environment(\.openURL)` for opening links

## UI Examples

### Free User View
```
┌─────────────────────────┐
│ Premium Status          │
│ Free                    │
│                         │
│ [Upgrade to Premium]    │
│ [Restore Purchases]     │
└─────────────────────────┘
```

### Premium User View
```
┌─────────────────────────┐
│ Premium Status          │
│ ✓ Premium (Yearly)      │
│ Renews: Jan 1, 2027     │
│                         │
│ [Manage Subscription]   │
│ [Restore Purchases]     │
└─────────────────────────┘
```

## Related Issues
- Depends on: #002 (PremiumManager)
- Related: #003 (PaywallView)

## Estimated Effort
2-3 hours
