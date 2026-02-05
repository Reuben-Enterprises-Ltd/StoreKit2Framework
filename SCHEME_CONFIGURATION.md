# Xcode Scheme Configuration for StoreKit Testing

Quick reference for configuring Xcode schemes to test StoreKit2Framework.

## StoreKit Configuration File Setup

### Step 1: Open Scheme Editor
- **Product** → **Scheme** → **Edit Scheme...**
- Or press `⌘<` (Command + Shift + Comma)

### Step 2: Select StoreKit Configuration
1. Click on **"Run"** in the left sidebar
2. Go to the **"Options"** tab
3. Under **"StoreKit Configuration"**, select `Configuration.storekit`
4. Click **"Close"**

### Step 3: Run Your App
- Build and run in Simulator (`⌘R`)
- StoreKit will use the local configuration file
- No App Store Connect required!

---

## Premium Override for Development

Use this to bypass StoreKit completely and grant premium access instantly.

### Step 1: Open Scheme Editor
- **Product** → **Scheme** → **Edit Scheme...**
- Or press `⌘<`

### Step 2: Add Environment Variable
1. Click on **"Run"** in the left sidebar
2. Go to the **"Arguments"** tab
3. Under **"Environment Variables"**, click **"+"**
4. Add:
   - **Name**: `PREMIUM_ENABLED`
   - **Value**: `1`
5. Click **"Close"**

### Step 3: Run Your App
- Build and run (`⌘R`)
- Premium features will be instantly available
- No purchases required!

### When to Use Premium Override

✅ **Perfect for:**
- Screenshots and demos
- QA testing premium features
- Development of premium UI
- Testing premium flows

⚠️ **Remember:**
- Only works in DEBUG builds
- Requires app rebuild to take effect
- Automatically disabled in production

---

## Combining Both

You can use both configurations simultaneously:

1. **Set StoreKit Configuration** in Options tab → for testing purchases
2. **Set PREMIUM_ENABLED=1** in Arguments tab → for testing premium state

---

## Quick Troubleshooting

**Products don't appear in app:**
- ✓ Verify `Configuration.storekit` is selected in scheme
- ✓ Make sure you're running in Simulator (not real device)
- ✓ Check product IDs match between code and .storekit file

**Premium override not working:**
- ✓ Verify environment variable name is exactly `PREMIUM_ENABLED`
- ✓ Verify value is exactly `1`
- ✓ Rebuild app after changing scheme
- ✓ Make sure you're running a DEBUG build

**Changes not taking effect:**
- ✓ Clean build folder: **Product** → **Clean Build Folder** (`⌘⇧K`)
- ✓ Rebuild app (`⌘B`)
- ✓ Restart Xcode if needed

---

## Testing Different States

### Test as Free User
1. Remove or set `PREMIUM_ENABLED` to `0`
2. Clear app data (delete app from Simulator)
3. Rebuild and run

### Test as Premium User
1. Set `PREMIUM_ENABLED` to `1`
2. Rebuild and run
3. Or use StoreKit config and make a test purchase

### Test Purchase Flow
1. Remove `PREMIUM_ENABLED` variable
2. Set StoreKit configuration
3. Run app and complete purchase in app

---

## Simulator StoreKit Testing Features

When using StoreKit Configuration in Simulator, you can:

- **View Transactions**: Settings → StoreKit Testing
- **Clear Purchase History**: Reset all test purchases
- **Refund Purchases**: Test refund scenarios
- **Manage Subscriptions**: Test renewal, cancellation
- **Accelerated Time**: Subscriptions renew faster for testing

---

## For More Information

See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for complete testing documentation.
