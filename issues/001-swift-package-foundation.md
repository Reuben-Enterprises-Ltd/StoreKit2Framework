# Issue 001: Create Swift Package Foundation

## Priority
**High** - This is the foundation for all other work

## Description
Set up the basic Swift Package structure for the StoreKit2Framework. This package should be easily droppable into any iOS project.

## Requirements

### Package Structure
- Create `Package.swift` with proper configuration
  - Target iOS 26.0+
  - Swift 6.2+
  - Swift concurrency support
- Define package name: `StoreKit2Framework`
- Set up library product that can be imported

### Directory Structure
```
StoreKit2Framework/
├── Package.swift
├── Sources/
│   └── StoreKit2Framework/
│       └── (source files will go here)
├── Tests/
│   └── StoreKit2FrameworkTests/
│       └── (test files will go here)
├── README.md
└── LICENSE
```

### Dependencies
- StoreKit (system framework)
- SwiftUI (system framework)
- No third-party dependencies (per project guidelines)

## Acceptance Criteria
- [ ] Package.swift exists with correct configuration
- [ ] Package can be added to an iOS project via Swift Package Manager
- [ ] Builds successfully without errors
- [ ] Follows modern Swift 6.2 concurrency patterns
- [ ] README explains how to add package to projects

## Technical Notes
- Use `.library(name: "StoreKit2Framework", targets: ["StoreKit2Framework"])` in products
- Include platforms: `.iOS(.v26)`
- Enable strict concurrency checking
- Ensure it's a library package, not executable

## Related Issues
- Blocks: #002 (Core PremiumManager)
- Blocks: #003 (UI Components)

## Estimated Effort
1-2 hours
