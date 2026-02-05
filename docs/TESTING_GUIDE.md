# Testing Guide for StoreKit2Framework

This document provides comprehensive guidance on testing the StoreKit2Framework, including setup, running tests, and using the various testing tools provided.

## Table of Contents

1. [Test Infrastructure Overview](#test-infrastructure-overview)
2. [Running Tests](#running-tests)
3. [StoreKit Configuration File](#storekit-configuration-file)
4. [Mock Objects and Test Helpers](#mock-objects-and-test-helpers)
5. [Debug Tools](#debug-tools)
6. [Test Coverage](#test-coverage)
7. [Testing in Consumer Apps](#testing-in-consumer-apps)

---

## Test Infrastructure Overview

The testing infrastructure includes:

- **Unit Tests**: Comprehensive tests for `PremiumManager` and all UI components
- **StoreKit Configuration**: `Configuration.storekit` file for local testing with Xcode
- **Mock Objects**: Test helpers for simulating premium states
- **Debug Tools**: Environment variables and utilities for testing premium features

### Test Target Structure

```
Tests/
└── StoreKit2FrameworkTests/
    ├── PremiumManagerTests.swift         # Core business logic tests
    ├── PaywallViewTests.swift            # UI component tests
    ├── PremiumFeatureGatingTests.swift   # Feature gating tests
    ├── PremiumSettingsComponentsTests.swift  # Settings UI tests
    ├── StoreKit2FrameworkTests.swift     # Basic framework tests
    └── TestHelpers.swift                 # Mock objects and utilities
```

---

## Running Tests

### Command Line

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test suite
swift test --filter "PremiumManager Tests"

# Run specific test
swift test --filter "PremiumManagerTests.singletonExists"
```

### Xcode

1. Open the package in Xcode
2. Select the test target
3. Press `⌘U` to run all tests
4. Or click the diamond icon next to individual tests to run them

### CI/CD

The tests are designed to be CI-friendly and run on Linux:

```yaml
# Example GitHub Actions configuration
- name: Run Tests
  run: swift test
```

---

## StoreKit Configuration File

The `Configuration.storekit` file enables local testing in Xcode Simulator without requiring App Store Connect setup.

### Products Configured

| Product Type | Product ID | Price | Description |
|-------------|-----------|-------|-------------|
| Monthly Subscription | `com.yourcompany.yourapp.monthly` | $4.99 | Recurring monthly |
| Yearly Subscription | `com.yourcompany.yourapp.yearly` | $39.99 | Recurring yearly |
| Lifetime Purchase | `com.yourcompany.yourapp.lifetime` | $24.99 | One-time purchase |

### Setting Up in Xcode

1. **Open Your App's Scheme**:
   - Product → Scheme → Edit Scheme...
   - Or press `⌘<`

2. **Configure StoreKit Testing**:
   - Select "Run" in the left sidebar
   - Go to "Options" tab
   - Under "StoreKit Configuration", select `Configuration.storekit`

3. **Run Your App**:
   - Build and run in Simulator
   - StoreKit will use the configuration file instead of connecting to App Store

### Testing Scenarios

With the StoreKit configuration file, you can test:

- ✅ Product loading and display
- ✅ Purchase flows (success, cancellation, pending)
- ✅ Transaction verification
- ✅ Premium status updates
- ✅ Restore purchases functionality
- ✅ Subscription renewals (accelerated time)
- ✅ Error handling

### Managing Test Transactions

In Simulator, you can:
- View transactions: Settings → StoreKit Testing
- Clear purchase history
- Refund purchases
- Manage subscriptions
- Test renewal scenarios

---

## Mock Objects and Test Helpers

The `TestHelpers.swift` file provides utilities for testing:

### Mock PremiumManager Instances

```swift
#if DEBUG
// Create a mock premium manager (uses environment variable)
let premiumManager = PremiumManager.mockPremium()

// Create a mock free manager
let freeManager = PremiumManager.mockFree()
#endif
```

### Test Product Identifiers

```swift
// Use consistent test identifiers
let monthlyID = TestHelpers.TestProductIdentifiers.monthly
let yearlyID = TestHelpers.TestProductIdentifiers.yearly
let lifetimeID = TestHelpers.TestProductIdentifiers.lifetime
```

### Mock Product Information

```swift
// Access mock product data
let mockMonthly = TestHelpers.MockProductInfo.monthly
print("Price: \(mockMonthly.displayPrice)")
```

### Mock Transaction Data

```swift
// Create verified transaction
let transaction = TestHelpers.MockTransactionInfo.verified(
    productID: "com.yourcompany.yourapp.monthly"
)

// Create unverified transaction
let badTransaction = TestHelpers.MockTransactionInfo.unverified(
    productID: "com.yourcompany.yourapp.monthly"
)
```

### Test Utilities

```swift
// Clear cached premium status
TestHelpers.clearPremiumCache()

// Wait for async operations
await TestHelpers.waitForAsync(timeout: 2.0)
```

---

## Debug Tools

### Environment Variable Override

The framework includes a debug-only environment variable to bypass StoreKit and grant premium access instantly.

#### Setting the Variable

**In Xcode Scheme**:
1. Product → Scheme → Edit Scheme... (or `⌘<`)
2. Select "Run" → "Arguments" tab
3. Under "Environment Variables", add:
   - Name: `PREMIUM_ENABLED`
   - Value: `1`

**In Tests**:
```swift
// Set for test process
ProcessInfo.processInfo.environment["PREMIUM_ENABLED"] = "1"
```

#### Use Cases

Perfect for:
- 🎬 **Screenshots and Demos**: Show premium features without purchasing
- 🧪 **QA Testing**: Test premium features without StoreKit setup
- 🏗️ **Development**: Work on premium features without purchases
- 🔍 **UI Testing**: Verify premium UI states

#### Important Notes

- ⚠️ **DEBUG builds only**: This override never works in production builds
- 🔒 **Security**: No security risk - compiled out of release builds
- 🔄 **Requires rebuild**: Changes take effect after app rebuild

### Debug Methods

```swift
#if DEBUG
// Extension methods for testing
extension PremiumManager {
    static func mockPremium() -> PremiumManager
    static func mockFree() -> PremiumManager
}
#endif
```

---

## Test Coverage

### Current Test Coverage

The test suite covers the following areas:

#### PremiumManager (Core Logic)
- ✅ Singleton initialization and consistency
- ✅ Product identifier validation
- ✅ Initial state verification
- ✅ Initialization safety (multiple calls, concurrent)
- ✅ Product loading state management
- ✅ Error clearing and handling
- ✅ Premium status calculation
- ✅ Status caching in UserDefaults
- ✅ Restore purchases functionality
- ✅ Debug override behavior
- ✅ Concurrent access safety
- ✅ State management (products, loading, errors)

#### PaywallView (UI Component)
- ✅ Component instantiation
- ✅ Custom headline support
- ✅ Custom benefits configuration
- ✅ Legal URL handling
- ✅ Benefit items and rows
- ✅ Subscription period display

#### PremiumFeatureGating (Access Control)
- ✅ `.premiumOnly()` modifier
- ✅ `.premiumGated()` modifier
- ✅ `.premiumRequired()` modifier
- ✅ `PremiumOverlay` component
- ✅ `requirePremium()` method
- ✅ Modifier chaining
- ✅ Integration in various contexts

#### PremiumSettingsComponents (Settings UI)
- ✅ `PremiumSettingsSection` component
- ✅ `PremiumStatusRow` component
- ✅ `PremiumBadge` component
- ✅ PremiumManager integration

### Coverage Goals

Target: **>80% code coverage** for `PremiumManager`

Current coverage: The test suite provides comprehensive coverage of:
- Public API surface
- State management
- Concurrency safety
- Error handling
- Initialization logic

### Running Coverage Reports

```bash
# Generate coverage report (requires Xcode)
swift test --enable-code-coverage

# View coverage in Xcode
# Product → Test (⌘U)
# Then Report Navigator → Coverage tab
```

---

## Testing in Consumer Apps

### Integration Testing

When integrating StoreKit2Framework into your app:

1. **Copy the StoreKit Configuration**:
   - Copy `Configuration.storekit` to your app project
   - Update product IDs to match your app's products
   - Configure in your app's scheme

2. **Update Product Identifiers**:
   ```swift
   // In your app, extend or configure product IDs
   extension PremiumManager.ProductIdentifiers {
       // Update to your actual product IDs
   }
   ```

3. **Test Premium Features**:
   ```swift
   // Use environment variable for development
   // Set PREMIUM_ENABLED=1 in your app's scheme
   
   // Or test with StoreKit configuration file
   // for actual purchase flows
   ```

### Unit Testing Your App

```swift
import XCTest
@testable import YourApp
import StoreKit2Framework

@MainActor
final class YourAppTests: XCTestCase {
    
    func testPremiumFeature() async throws {
        #if DEBUG
        // Use mock for testing
        let manager = PremiumManager.mockPremium()
        
        // Test your premium feature
        XCTAssertTrue(manager.isPremium)
        #endif
    }
}
```

### UI Testing Your App

```swift
import XCTest

final class YourAppUITests: XCTestCase {
    
    func testPaywallAppears() throws {
        let app = XCUIApplication()
        
        // Set environment variable
        app.launchEnvironment["PREMIUM_ENABLED"] = "0"
        app.launch()
        
        // Test that paywall appears for free users
        // ...
    }
    
    func testPremiumFeaturesAccessible() throws {
        let app = XCUIApplication()
        
        // Enable premium for testing
        app.launchEnvironment["PREMIUM_ENABLED"] = "1"
        app.launch()
        
        // Test that premium features are accessible
        // ...
    }
}
```

---

## Best Practices

### Test Writing

1. **Use `#if canImport(StoreKit)`** to ensure tests work on all platforms
2. **Test on @MainActor** for `PremiumManager` methods
3. **Handle async properly** with `async throws` functions
4. **Test both success and failure paths**
5. **Test concurrent access** for thread safety

### Debugging Failed Tests

1. **Check Environment Variables**: Ensure `PREMIUM_ENABLED` is not set when testing free state
2. **Clear Test State**: Use `TestHelpers.clearPremiumCache()` between tests
3. **Verify StoreKit Configuration**: Ensure product IDs match in tests
4. **Check Async Timing**: Add appropriate delays for async operations

### Continuous Integration

The tests are designed to run in CI environments:

- ✅ No Xcode required for basic tests
- ✅ Work on Linux (Swift Testing framework)
- ✅ No external dependencies
- ✅ Fast execution (< 1 second for full suite)

---

## Troubleshooting

### Common Issues

**Tests fail with "StoreKit not available"**
- Tests use `#if canImport(StoreKit)` guards
- This is expected on Linux - tests will skip
- Run on macOS/Xcode for full StoreKit tests

**Premium status is `true` when expecting `false`**
- Check `PREMIUM_ENABLED` environment variable
- Clear UserDefaults cache: `TestHelpers.clearPremiumCache()`
- Check for cached status from previous runs

**Products don't load in tests**
- StoreKit configuration file only works in Xcode Simulator
- Unit tests don't simulate actual product loading
- Use mock objects for unit testing

**Async tests timeout**
- Increase timeout: `TestHelpers.waitForAsync(timeout: 5.0)`
- Check for deadlocks in concurrent code
- Verify `@MainActor` isolation

---

## Additional Resources

- [StoreKit Testing Documentation](https://developer.apple.com/documentation/storekit/testing)
- [Swift Testing Framework](https://github.com/apple/swift-testing)
- [STOREKIT_COPILOT_AGENT_GUIDE.md](./STOREKIT_COPILOT_AGENT_GUIDE.md) - Lines 822-871 for testing strategy

---

## Summary

This testing infrastructure provides:

- ✅ Comprehensive unit tests (>80% coverage goal)
- ✅ StoreKit configuration for local testing
- ✅ Mock objects and test helpers
- ✅ Debug tools for premium override
- ✅ CI-friendly test execution
- ✅ Clear documentation for all testing scenarios

Start testing by running `swift test` or pressing `⌘U` in Xcode!
