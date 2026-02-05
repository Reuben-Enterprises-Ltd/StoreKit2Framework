# Issue 011: App Store Connect Integration Guide

## Priority
**Medium** - Essential for production use

## Description
Create comprehensive guide for setting up products in App Store Connect and preparing the framework for production deployment.

## Requirements

### Documentation to Create

#### 1. App Store Connect Setup Guide
`docs/APP_STORE_CONNECT.md`

Step-by-step instructions for:
- Creating subscription groups
- Adding subscription products
- Adding non-consumable (lifetime) products
- Configuring pricing
- Adding product metadata
- Setting up test accounts
- Submitting for review

#### 2. Product Configuration Checklist
What users need to configure:
- Product IDs (must match code exactly)
- Pricing by region
- Subscription duration
- Trial offers (optional)
- Promotional offers (optional)
- Product descriptions
- Product screenshots

#### 3. Legal Requirements Guide
Document required legal items:
- Privacy Policy URL
- Terms of Service URL
- Subscription terms
- Auto-renewal disclosure
- Pricing display
- Free trial terms (if applicable)

#### 4. App Review Preparation
What App Review will check:
- Restore purchases button present
- Pricing clearly displayed
- Subscription terms visible
- Manage subscription link works
- Purchase flow works correctly
- Error handling graceful

#### 5. Localization Guide
How to localize products:
- Product names by region
- Product descriptions
- Pricing display
- Legal content
- Paywall UI text

### App Store Connect Screenshots

Include annotated screenshots showing:
- Where to create subscription group
- Where to add products
- Product configuration fields
- Pricing setup
- How to create sandbox testers
- Where to find product IDs

### Pre-Submission Checklist

```markdown
Before submitting to App Review:

Setup in App Store Connect:
- [ ] All products created with correct IDs
- [ ] Products submitted for review
- [ ] Products approved by Apple
- [ ] Pricing configured for all regions
- [ ] Subscription group created
- [ ] Test account created and tested

Legal Requirements:
- [ ] Privacy Policy URL added
- [ ] Terms of Service URL added
- [ ] EULA configured (if custom)
- [ ] Subscription terms clearly stated
- [ ] Auto-renewal disclosure present

In-App Requirements:
- [ ] Restore purchases button visible
- [ ] Manage subscription link present
- [ ] Pricing displayed accurately
- [ ] Purchase flow tested end-to-end
- [ ] Error states handled gracefully
- [ ] Loading states implemented

Testing:
- [ ] Tested with sandbox account
- [ ] Tested all product types
- [ ] Tested restore functionality
- [ ] Tested on multiple devices
- [ ] Tested all edge cases
- [ ] Checked in TestFlight
```

## Product Configuration Template

Provide template for users to fill out:

```markdown
# Product Configuration

## Subscription Group
- Group Name: _______________
- Group ID: _______________

## Monthly Subscription
- Product ID: com.company.app.monthly
- Display Name: Monthly Premium
- Description: Full access to all premium features
- Duration: 1 month
- Price: $4.99 USD
- Renewal: Auto-renewing

## Yearly Subscription
- Product ID: com.company.app.yearly
- Display Name: Yearly Premium
- Description: Full access to all premium features for a year
- Duration: 1 year
- Price: $39.99 USD
- Renewal: Auto-renewing
- Savings: 33% vs monthly

## Lifetime Purchase
- Product ID: com.company.app.lifetime
- Display Name: Lifetime Premium
- Description: Unlock all premium features forever
- Type: Non-consumable
- Price: $24.99 USD
```

## Common Issues Section

Document common App Store Connect issues:
- Product IDs don't match
- Products stuck in review
- Pricing tier confusion
- Localization missing
- Sandbox testing problems
- Product not appearing in app

## Acceptance Criteria
- [ ] APP_STORE_CONNECT.md created with full guide
- [ ] Screenshots included for key steps
- [ ] Legal requirements documented
- [ ] Pre-submission checklist created
- [ ] Product configuration template provided
- [ ] Common issues and solutions included
- [ ] Links to Apple documentation
- [ ] Guide tested by following step-by-step

## Resources to Link
- App Store Connect documentation
- App Review Guidelines (specifically IAP sections)
- StoreKit documentation
- Sandbox testing guide
- WWDC StoreKit sessions

## Technical Notes
- Product IDs are case-sensitive
- Must wait for product approval before testing in production
- Sandbox accounts must be separate from real accounts
- Family Sharing setup requires specific configuration
- Pricing tiers are predefined by Apple

## Related Issues
- Complements: #002 (Product IDs must match)
- Complements: #008 (Part of overall documentation)
- Required for: Production deployment

## Estimated Effort
3-4 hours
