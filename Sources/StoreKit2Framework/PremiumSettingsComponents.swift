#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

// MARK: - PremiumSettingsSection

/// Complete settings section showing premium status and actions
///
/// This view provides a complete settings section that can be embedded in any settings screen.
/// It displays the user's current premium status and provides actions to upgrade, restore, or manage subscriptions.
///
/// Example usage:
/// ```swift
/// Form {
///     PremiumSettingsSection()
///     // other settings...
/// }
/// ```
public struct PremiumSettingsSection: View {
    private let premiumManager = PremiumManager.shared
    @Environment(\.openURL) private var openURL
    
    @State private var showingPaywall = false
    @State private var isRestoring = false
    
    public init() {}
    
    public var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Status header
                Text("Premium Status")
                    .font(.headline)
                
                // Status display
                statusView
                
                // Action buttons
                VStack(spacing: 8) {
                    if !premiumManager.isPremium {
                        upgradeButton
                    }
                    
                    if premiumManager.isPremium {
                        manageSubscriptionButton
                    }
                    
                    restoreButton
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            premiumManager.ensureInitialized()
        }
    }
    
    // MARK: - Status View
    
    @ViewBuilder
    private var statusView: some View {
        if premiumManager.isPremium {
            premiumStatusView
        } else {
            freeStatusView
        }
    }
    
    private var freeStatusView: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .imageScale(.large)
            
            Text("Free")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var premiumStatusView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.large)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let subscriptionType = subscriptionTypeName {
                        Text("Premium (\(subscriptionType))")
                            .font(.body)
                            .bold()
                    } else {
                        Text("Premium")
                            .font(.body)
                            .bold()
                    }
                    
                    if let renewalDate = renewalDateText {
                        Text(renewalDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var upgradeButton: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue.gradient)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var manageSubscriptionButton: some View {
        Button {
            Task {
                await openSubscriptionManagement()
            }
        } label: {
            HStack {
                Image(systemName: "gearshape")
                Text("Manage Subscription")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .foregroundStyle(.primary)
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            HStack {
                if isRestoring {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Restore Purchases")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .foregroundStyle(.primary)
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }
    
    // MARK: - Helpers
    
    private var subscriptionTypeName: String? {
        guard let activeEntitlement = premiumManager.activeEntitlement else { return nil }
        
        // Check the product ID
        guard case .verified(let transaction) = activeEntitlement.transaction else { return nil }
        
        let productId = transaction.productID
        
        if productId == PremiumManager.ProductIdentifiers.monthly {
            return "Monthly"
        } else if productId == PremiumManager.ProductIdentifiers.yearly {
            return "Yearly"
        } else if productId == PremiumManager.ProductIdentifiers.lifetime {
            return "Lifetime"
        }
        
        return nil
    }
    
    private var renewalDateText: String? {
        guard let activeEntitlement = premiumManager.activeEntitlement else { return nil }
        
        // For lifetime, show no renewal date
        guard case .verified(let transaction) = activeEntitlement.transaction else { return nil }
        if transaction.productID == PremiumManager.ProductIdentifiers.lifetime {
            return nil
        }
        
        // For subscriptions, show renewal info
        guard case .verified(let renewalInfo) = activeEntitlement.renewalInfo else { return nil }
        
        if let expirationDate = renewalInfo.expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            if renewalInfo.willAutoRenew {
                return "Renews: \(formatter.string(from: expirationDate))"
            } else {
                return "Expires: \(formatter.string(from: expirationDate))"
            }
        }
        
        return nil
    }
    
    private func openSubscriptionManagement() async {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await openURL(url)
        }
    }
    
    private func restorePurchases() async {
        isRestoring = true
        await premiumManager.restorePurchases()
        isRestoring = false
    }
}

// MARK: - PremiumStatusRow

/// Status row for displaying in a List
///
/// This view provides a simple row that can be embedded in a List.
/// It shows the premium status and can be tapped to navigate to more details.
///
/// Example usage:
/// ```swift
/// List {
///     PremiumStatusRow()
///     // other settings...
/// }
/// ```
public struct PremiumStatusRow: View {
    private let premiumManager = PremiumManager.shared
    
    @State private var showingPaywall = false
    
    public init() {}
    
    public var body: some View {
        Button {
            if !premiumManager.isPremium {
                showingPaywall = true
            }
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium")
                            .foregroundStyle(.primary)
                        
                        if premiumManager.isPremium, let subscriptionType = subscriptionTypeName {
                            Text(subscriptionType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(premiumManager.isPremium ? .yellow : .secondary)
                }
                
                Spacer()
                
                if premiumManager.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Active")
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                } else {
                    Text("Unlock")
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            premiumManager.ensureInitialized()
        }
    }
    
    private var subscriptionTypeName: String? {
        guard let activeEntitlement = premiumManager.activeEntitlement else { return nil }
        
        guard case .verified(let transaction) = activeEntitlement.transaction else { return nil }
        
        let productId = transaction.productID
        
        if productId == PremiumManager.ProductIdentifiers.monthly {
            return "Monthly Subscription"
        } else if productId == PremiumManager.ProductIdentifiers.yearly {
            return "Yearly Subscription"
        } else if productId == PremiumManager.ProductIdentifiers.lifetime {
            return "Lifetime Purchase"
        }
        
        return nil
    }
}

// MARK: - PremiumBadge

/// Badge/Indicator showing "Pro" badge if premium
///
/// This view displays a "Pro" badge when the user has premium access.
/// It automatically hides when the user is not premium.
///
/// Example usage:
/// ```swift
/// HStack {
///     Text("My App")
///     PremiumBadge()
/// }
/// ```
public struct PremiumBadge: View {
    private let premiumManager = PremiumManager.shared
    
    public init() {}
    
    public var body: some View {
        if premiumManager.isPremium {
            Text("Pro")
                .font(.caption2)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.gradient)
                .clipShape(.capsule)
        }
    }
}

// MARK: - Preview Providers

#Preview("Free User - Settings Section") {
    NavigationStack {
        Form {
            PremiumSettingsSection()
        }
        .navigationTitle("Settings")
    }
}

#Preview("Premium User - Settings Section") {
    NavigationStack {
        Form {
            PremiumSettingsSection()
        }
        .navigationTitle("Settings")
    }
    .environment(\.premiumOverridePreview, true)
}

#Preview("Free User - Status Row") {
    NavigationStack {
        List {
            PremiumStatusRow()
            Text("Other Setting 1")
            Text("Other Setting 2")
        }
        .navigationTitle("Settings")
    }
}

#Preview("Premium User - Status Row") {
    NavigationStack {
        List {
            PremiumStatusRow()
            Text("Other Setting 1")
            Text("Other Setting 2")
        }
        .navigationTitle("Settings")
    }
    .environment(\.premiumOverridePreview, true)
}

#Preview("Premium Badge - With Premium") {
    HStack {
        Text("My App")
            .font(.title)
        PremiumBadge()
    }
    .padding()
    .environment(\.premiumOverridePreview, true)
}

#Preview("Premium Badge - Without Premium") {
    HStack {
        Text("My App")
            .font(.title)
        PremiumBadge()
    }
    .padding()
}

// MARK: - Preview Environment Key

/// Environment key for overriding premium status in previews
private struct PremiumOverridePreviewKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    fileprivate var premiumOverridePreview: Bool {
        get { self[PremiumOverridePreviewKey.self] }
        set { self[PremiumOverridePreviewKey.self] = newValue }
    }
}

#endif
