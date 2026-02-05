# Issue 006: Testing Infrastructure

## Priority
**High** - Essential for reliability

## Description
Create comprehensive testing infrastructure for the framework. This includes unit tests, integration tests, and tools for testing in consuming apps.

## Requirements

### Unit Tests
Create tests for PremiumManager logic:
- Product loading
- Premium status calculation
- Caching behavior
- Error handling
- Transaction verification logic
- State management

### Mock Objects
Create mock/stub implementations for testing:
- MockStoreKit (if possible)
- MockProduct
- MockTransaction
- Test product identifiers

### StoreKit Configuration
- Create `.storekit` configuration file for local testing
- Include test products (monthly, yearly, lifetime)
- Reasonable test prices
- Test subscription group

### Testing Utilities
```swift
// Helper for testing premium features
extension PremiumManager {
    #if DEBUG
    static func mockPremium() -> PremiumManager
    static func mockFree() -> PremiumManager
    #endif
}
```

### Debug Tools
- Environment variable for premium override
- Scheme configuration documentation
- Debug UI for toggling states

## Test Coverage Areas

### PremiumManager Tests
- [ ] Singleton initialization
- [ ] Product loading success
- [ ] Product loading failure
- [ ] Purchase flow
- [ ] Restore purchases
- [ ] Premium status updates
- [ ] Caching mechanism
- [ ] Transaction verification
- [ ] Real-time listener behavior
- [ ] Concurrent access safety

### UI Tests (if feasible)
- [ ] Paywall displays correctly
- [ ] Purchase button interaction
- [ ] Restore button works
- [ ] Error states display
- [ ] Loading states display

### Integration Tests
- [ ] End-to-end purchase flow
- [ ] Status persistence across launches
- [ ] Multi-device sync scenarios

## Acceptance Criteria
- [ ] Test target created in Package.swift
- [ ] Unit tests for PremiumManager (>80% coverage)
- [ ] Mock objects for all external dependencies
- [ ] .storekit configuration file created
- [ ] Documentation on running tests
- [ ] CI-friendly test execution
- [ ] All tests pass consistently
- [ ] Debug tools documented

## Technical Notes
- Reference STOREKIT_COPILOT_AGENT_GUIDE.md lines 822-871
- Use XCTest framework
- Mock StoreKit interactions where possible
- Test async/await code properly
- Consider using `@MainActor` in tests
- Document scheme configuration for StoreKit file

## .storekit Configuration Example
Based on guide lines 349-428, include:
- Monthly subscription: $4.99
- Yearly subscription: $39.99
- Lifetime purchase: $24.99
- All subscriptions in same group
- Test renewal periods (shorter for testing)

## Related Issues
- Depends on: #002 (PremiumManager to test)
- Enhances: #003, #004, #005 (All components need tests)

## Estimated Effort
4-6 hours
