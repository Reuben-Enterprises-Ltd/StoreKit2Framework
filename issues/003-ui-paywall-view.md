# Issue 003: Create PaywallView UI Component

## Priority
**High** - Core UI that users interact with

## Description
Create a beautiful, reusable PaywallView that can be presented from anywhere in an app. This view handles the purchase flow with a clean, modern design.

## Requirements

### View Features
- Display all available products (monthly, yearly, lifetime)
- Show pricing and descriptions from App Store
- Highlight recommended option (best value)
- Loading states while fetching products
- Error handling with retry
- Success/failure feedback
- Dismissible via environment dismiss action

### Customization
- Optional headline parameter for context
  - Example: "Unlock Premium Features"
  - Example: "Go Pro to Continue"
- Optional benefit list (can be provided by consuming app)
- Support for feature-specific paywalls

### User Experience
- Visual hierarchy (recommended tier highlighted)
- Price comparison (show savings for yearly)
- Clear call-to-action buttons
- "Restore Purchases" button prominently displayed
- Privacy policy and terms links
- Loading indicators during purchase
- Error alerts with retry options
- Smooth animations and transitions

### Purchase Flow
1. View loads products automatically
2. User selects product
3. Tap to purchase
4. Show loading state
5. Handle result (success/cancel/error)
6. Auto-dismiss on success
7. Update UI based on manager state

## Acceptance Criteria
- [ ] PaywallView.swift created
- [ ] Works with PremiumManager.shared
- [ ] Displays products dynamically
- [ ] Handles all purchase states (loading, success, error, cancelled)
- [ ] Restore purchases button works
- [ ] Can be customized via init parameters
- [ ] Follows SwiftUI best practices
- [ ] Uses Dynamic Type for accessibility
- [ ] Supports light and dark modes
- [ ] No hardcoded colors or fonts
- [ ] Preview provider included for development

## Design Patterns
```swift
// Usage example
.sheet(isPresented: $showPaywall) {
    PaywallView(headline: "Unlock Premium Features")
}

// Or in navigation
NavigationLink {
    PaywallView()
}

// Or as full screen cover
.fullScreenCover(isPresented: $showPaywall) {
    PaywallView(headline: "Go Pro")
}
```

## Technical Notes
- Reference implementation in STOREKIT_COPILOT_AGENT_GUIDE.md lines 480-724
- Use `@Environment(\.dismiss)` for closing
- Use `@State` for local UI state
- Access `PremiumManager.shared` (don't create new instance)
- Use `Task { }` for async operations
- Handle `@unknown default` in purchase result switch

## Related Issues
- Depends on: #002 (PremiumManager)
- Related: #004 (Settings integration)
- Related: #005 (Feature gating)

## Estimated Effort
3-4 hours
