# Issue 005: Feature Gating Utilities

## Priority
**High** - Essential for protecting premium features

## Description
Create utilities and components that make it easy to gate features behind premium status throughout an app. These should be simple to use and consistent.

## Requirements

### View Modifiers
Create SwiftUI view modifiers for easy feature gating:

```swift
// Premium-only content
someView
    .premiumOnly()

// Custom paywall shown when tapped
someView
    .premiumGated(headline: "Unlock this feature")

// Disabled state for non-premium
Button("Export") { }
    .premiumRequired()
```

### Property Wrappers (Optional)
Consider property wrapper for premium checks:
```swift
@Premium var canExport: Bool
```

### Helper Methods
```swift
extension PremiumManager {
    func requirePremium(
        feature: String,
        onUpgrade: @escaping () -> Void
    )
}
```

### Visual Indicators
- Lock icon overlay for premium content
- "Pro" badge for premium features
- Blur effect for locked content
- Custom overlays

## Acceptance Criteria
- [ ] `.premiumOnly()` view modifier created
- [ ] `.premiumGated(headline:)` view modifier created
- [ ] `.premiumRequired()` view modifier created
- [ ] `PremiumOverlay` view component created
- [ ] `PremiumBadge` component created (if not in #004)
- [ ] Easy to use in any view
- [ ] Shows paywall automatically when needed
- [ ] Visual feedback for locked features
- [ ] Respects PremiumManager state changes
- [ ] Preview providers showing locked/unlocked states
- [ ] Documentation with usage examples

## Usage Examples

### Example 1: Hide feature completely
```swift
if premiumManager.isPremium {
    AdvancedSettingsView()
}
```

### Example 2: Show but disable
```swift
Button("Export All") {
    exportAll()
}
.premiumRequired()  // Disabled with lock icon if not premium
```

### Example 3: Show with overlay
```swift
ContentView()
    .premiumGated(headline: "Unlock Advanced Features")
    // Shows blur + paywall button if not premium
```

### Example 4: In navigation
```swift
NavigationLink("Advanced") {
    AdvancedView()
}
.premiumOnly()  // Hidden if not premium
```

## Technical Notes
- Reference STOREKIT_COPILOT_AGENT_GUIDE.md lines 762-786
- Use `@Environment` to pass PremiumManager if needed
- Consider using `@ViewBuilder` for flexible content
- Modifiers should be composable
- Use opacity/overlay for visual effects
- Show SF Symbols lock icon: `Image(systemName: "lock.fill")`

## Design Considerations
- Don't frustrate users - be clear about what's locked
- Provide easy upgrade path
- Make premium value obvious
- Consistent visual language across all gates

## Related Issues
- Depends on: #002 (PremiumManager)
- Related: #003 (PaywallView for upgrade flow)

## Estimated Effort
3-4 hours
