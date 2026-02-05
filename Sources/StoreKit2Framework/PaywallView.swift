#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

// MARK: - Paywall Configuration

/// Configuration for PaywallView appearance and behavior
public struct PaywallConfiguration {
    /// Custom headline text
    public var headline: String
    
    /// Custom features/benefits list
    public var features: [PremiumManager.Feature]
    
    /// Whether to show the restore purchases button
    public var showRestoreButton: Bool
    
    /// Whether to show privacy policy and terms links
    public var showPrivacyLinks: Bool
    
    /// Optional custom tint color for the paywall
    public var tintColor: Color?
    
    /// Default configuration
    public static var `default`: PaywallConfiguration {
        PaywallConfiguration(
            headline: "Unlock Premium Features",
            features: [],
            showRestoreButton: true,
            showPrivacyLinks: true,
            tintColor: nil
        )
    }
    
    /// Initialize with custom configuration
    public init(
        headline: String = "Unlock Premium Features",
        features: [PremiumManager.Feature] = [],
        showRestoreButton: Bool = true,
        showPrivacyLinks: Bool = true,
        tintColor: Color? = nil
    ) {
        self.headline = headline
        self.features = features
        self.showRestoreButton = showRestoreButton
        self.showPrivacyLinks = showPrivacyLinks
        self.tintColor = tintColor
    }
}

/// A beautiful, reusable PaywallView that displays available products and handles purchases
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let premiumManager = PremiumManager.shared
    
    /// Default analytics source when none is provided
    public static let defaultAnalyticsSource = "unknown"
    
    /// Paywall configuration
    public let configuration: PaywallConfiguration
    
    /// Optional headline to customize the paywall context (deprecated - use configuration)
    public let headline: String?
    
    /// Optional benefits list (deprecated - use configuration)
    public let benefits: [BenefitItem]?
    
    /// Privacy policy URL (deprecated - use Configuration.privacyPolicyURL)
    @available(*, deprecated, message: "Use Configuration.privacyPolicyURL instead")
    public let privacyPolicyURL: URL?
    
    /// Terms of service URL (deprecated - use Configuration.termsOfServiceURL)
    @available(*, deprecated, message: "Use Configuration.termsOfServiceURL instead")
    public let termsOfServiceURL: URL?
    
    /// Source/context for analytics tracking (e.g., "onboarding", "settings", "feature_gate")
    public let analyticsSource: String
    
    @State private var selectedProduct: Product?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false
    @State private var isRestoring = false
    
    /// Initialize paywall with configuration
    /// - Parameters:
    ///   - configuration: Paywall configuration (default uses PremiumManager configuration)
    ///   - privacyPolicyURL: URL to privacy policy (deprecated - use Configuration.privacyPolicyURL)
    ///   - termsOfServiceURL: URL to terms of service (deprecated - use Configuration.termsOfServiceURL)
    ///   - analyticsSource: Source/context for analytics tracking (default: "unknown")
    public init(
        configuration: PaywallConfiguration? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil,
        analyticsSource: String = PaywallView.defaultAnalyticsSource
    ) {
        // Use provided configuration or create one from PremiumManager
        let managerConfig = PremiumManager.shared.currentConfiguration
        self.configuration = configuration ?? PaywallConfiguration(
            headline: "Unlock Premium Features",
            features: managerConfig.features,
            showRestoreButton: true,
            showPrivacyLinks: true,
            tintColor: nil
        )
        
        self.headline = nil
        self.benefits = nil
        // Store deprecated parameters for backwards compatibility
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
        self.analyticsSource = analyticsSource
    }
    
    /// Initialize paywall with optional customization (legacy API)
    /// - Parameters:
    ///   - headline: Custom headline text (default: "Unlock Premium Features")
    ///   - benefits: Custom benefits list (default: nil - uses built-in benefits)
    ///   - privacyPolicyURL: URL to privacy policy (deprecated - use Configuration.privacyPolicyURL)
    ///   - termsOfServiceURL: URL to terms of service (deprecated - use Configuration.termsOfServiceURL)
    public init(
        headline: String? = nil,
        benefits: [BenefitItem]? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil
    ) {
        // Legacy initialization - convert to configuration
        let managerConfig = PremiumManager.shared.currentConfiguration
        
        self.configuration = PaywallConfiguration(
            headline: headline ?? "Unlock Premium Features",
            features: benefits?.map { benefit in
                    .init(title: benefit.title, systemImageName: benefit.icon)
            } ?? managerConfig.features,
            showRestoreButton: true,
            showPrivacyLinks: true,
            tintColor: nil
        )
        
        self.headline = headline
        self.benefits = benefits
        // Store deprecated parameters for backwards compatibility
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
        self.analyticsSource = PaywallView.defaultAnalyticsSource
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero section
                    heroSection
                    
                    // Benefits
                    if premiumManager.isLoading {
                        loadingSection
                    } else if !premiumManager.products.isEmpty {
                        benefitsSection
                        
                        // Product selection
                        productSelection
                        
                        // Purchase button
                        purchaseButton
                        
                        // Restore button
                        restoreButton
                        
                        // Legal links
                        legalSection
                    } else if let error = premiumManager.error {
                        errorSection(error: error)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Maybe Later", comment: "Button to dismiss paywall")) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "Purchase Failed", comment: "Alert title for failed purchase"), isPresented: $showingErrorAlert) {
                Button(String(localized: "OK", comment: "Button to dismiss alert")) {
                    showingErrorAlert = false
                }
                Button(String(localized: "Try Again", comment: "Button to retry failed purchase")) {
                    showingErrorAlert = false
                    if let product = selectedProduct {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                premiumManager.ensureInitialized()
                premiumManager.trackPaywallShown(source: analyticsSource)
                selectDefaultProduct()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle((configuration.tintColor ?? .blue).gradient)
            
            Text(headline ?? configuration.headline)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text(String(localized: "Get the most out of your experience", comment: "Paywall subtitle text"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(String(localized: "Loading products...", comment: "Loading message while fetching products"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Benefits Section
    
    /// Default icons for feature benefits when converting from configuration
    private static let defaultFeatureIcons = [
        "chart.line.uptrend.xyaxis",
        "icloud",
        "paintbrush",
        "bolt.fill",
        "star.fill",
        "shield.fill",
        "gift.fill",
        "heart.fill"
    ]
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let benefitList = benefits ?? benefitItemsFromConfiguration
            ForEach(benefitList) { benefit in
                BenefitRow(
                    icon: benefit.icon,
                    title: benefit.title,
                    description: benefit.description
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
    }
    
    private var benefitItemsFromConfiguration: [BenefitItem] {
        // If configuration has features, convert them to benefit items
        if !configuration.features.isEmpty {
            return configuration.features.enumerated().map { index, feature in
                BenefitItem(
                    icon: feature.systemImageName,
                    title: feature.title,
                    description: ""
                )
            }
        }
        
        // Fall back to default benefits
        return defaultBenefits
    }
    
    private var defaultBenefits: [BenefitItem] {
        [
            BenefitItem(
                icon: "chart.line.uptrend.xyaxis",
                title: String(localized: "Advanced Analytics", comment: "Default benefit title"),
                description: String(localized: "Deep insights into your data", comment: "Default benefit description")
            ),
            BenefitItem(
                icon: "icloud",
                title: String(localized: "Cloud Sync", comment: "Default benefit title"),
                description: String(localized: "Access everywhere, anytime", comment: "Default benefit description")
            ),
            BenefitItem(
                icon: "paintbrush",
                title: String(localized: "Premium Themes", comment: "Default benefit title"),
                description: String(localized: "Customize your experience", comment: "Default benefit description")
            ),
            BenefitItem(
                icon: "bolt.fill",
                title: String(localized: "Priority Support", comment: "Default benefit title"),
                description: String(localized: "Get help when you need it", comment: "Default benefit description")
            )
        ]
    }
    
    // MARK: - Product Selection
    
    private var productSelection: some View {
        VStack(spacing: 12) {
            ForEach(premiumManager.products, id: \.id) { product in
                ProductOptionButton(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isRecommended: isRecommendedProduct(product)
                ) {
                    selectedProduct = product
                }
            }
        }
    }
    
    private func isRecommendedProduct(_ product: Product) -> Bool {
        // Recommend yearly subscription as best value
        product.id == premiumManager.currentConfiguration.productIdentifiers.yearly
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                await purchaseProduct(product)
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(localized: "Start Premium", comment: "Button to start premium purchase"))
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background((configuration.tintColor ?? .blue).gradient)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .opacity(selectedProduct == nil || isPurchasing ? 0.6 : 1.0)
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        do {
            try await premiumManager.purchase(product)
            // Auto-dismiss on success
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
        isPurchasing = false
    }
    
    // MARK: - Restore Button
    
    @ViewBuilder
    private var restoreButton: some View {
        if configuration.showRestoreButton {
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
                        Text(String(localized: "Restore Purchases", comment: "Button to restore previous purchases"))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .disabled(isRestoring)
        }
    }
    
    private func restorePurchases() async {
        isRestoring = true
        await premiumManager.restorePurchases()
        if premiumManager.isPremium {
            dismiss()
        }
        isRestoring = false
    }
    
    // MARK: - Legal Section
    
    @ViewBuilder
    private var legalSection: some View {
        if configuration.showPrivacyLinks {
            HStack(spacing: 12) {
                // Use deprecated parameter if provided, otherwise use configuration
                let privacyURL = privacyPolicyURL ?? premiumManager.currentConfiguration.privacyPolicyURL
                Link(String(localized: "Privacy", comment: "Link to privacy policy"), destination: privacyURL)
                
                // Show separator
                Text("•")
                    .foregroundStyle(.secondary)
                
                // Use deprecated parameter if provided, otherwise use configuration
                let termsURL = termsOfServiceURL ?? premiumManager.currentConfiguration.termsOfServiceURL
                Link(String(localized: "Terms", comment: "Link to terms of service/EULA"), destination: termsURL)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text(String(localized: "Unable to Load Products", comment: "Error message when products fail to load"))
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(String(localized: "Try Again", comment: "Button to retry loading products")) {
                Task {
                    await premiumManager.loadProducts()
                    selectDefaultProduct()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func selectDefaultProduct() {
        // Default to yearly (best value) or first product
        let yearlyId = premiumManager.currentConfiguration.productIdentifiers.yearly
        selectedProduct = premiumManager.products.first {
            $0.id == yearlyId
        } ?? premiumManager.products.first
    }
}

// MARK: - Benefit Item

/// Represents a benefit item to display in the paywall
public struct BenefitItem: Identifiable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let description: String
    
    public init(icon: String, title: String, description: String) {
        self.icon = icon
        self.title = title
        self.description = description
    }
}

// MARK: - Benefit Row

/// A row displaying a single benefit with icon, title, and description
public struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Product Option Button

/// A button for selecting a product option in the paywall
public struct ProductOptionButton: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    private let premiumManager = PremiumManager.shared
    
    public init(
        product: Product,
        isSelected: Bool,
        isRecommended: Bool = false,
        action: @escaping () -> Void
    ) {
        self.product = product
        self.isSelected = isSelected
        self.isRecommended = isRecommended
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Recommended badge
                if isRecommended {
                    HStack {
                        Spacer()
                        Text(String(localized: "Best Value", comment: "Badge for recommended subscription option"))
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.gradient)
                            .clipShape(.capsule)
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.subheadline)
                            .bold()
                        
                        Text(periodText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Show savings for yearly
                        if isRecommended, let subscription = product.subscription,
                           subscription.subscriptionPeriod.unit == .year {
                            Text(String(localized: "Save up to 40%", comment: "Savings message for yearly subscription"))
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.headline)
                        
                        Text(pricePerPeriodText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .imageScale(.large)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    /// Returns the period description text for the product
    private var periodText: String {
        // Check if this is a lifetime product
        if let lifetimeId = premiumManager.currentConfiguration.productIdentifiers.lifetime,
           product.id == lifetimeId {
            return String(localized: "Lifetime", comment: "Period description for lifetime/non-renewing subscription")
        }
        
        // For subscription products, show the period
        if let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            return "\(period.value) \(period.unit.displayName)"
        }
        
        // Fallback for other non-renewing subscriptions
        return String(localized: "Lifetime", comment: "Period description for lifetime/non-renewing subscription")
    }
    
    /// Returns the price per period text (e.g., "$2.08/month" for yearly)
    private var pricePerPeriodText: String {
        // Check if this is a lifetime product
        if let lifetimeId = premiumManager.currentConfiguration.productIdentifiers.lifetime,
           product.id == lifetimeId {
            return String(localized: "one off", comment: "Price description for lifetime purchase - pay once")
        }
        
        // For yearly subscriptions, show monthly price
        if let subscription = product.subscription,
           subscription.subscriptionPeriod.unit == .year,
           let monthlyPrice = calculateMonthlyPrice(product.price) {
            // Use a format string for proper localization
            let format = String(localized: "%@/month", comment: "Monthly price breakdown for yearly subscription - %@ is replaced with price")
            return String(format: format, monthlyPrice)
        }
        
        // For monthly subscriptions, show per month
        if let subscription = product.subscription,
           subscription.subscriptionPeriod.unit == .month {
            return String(localized: "per month", comment: "Price period for monthly subscription")
        }
        
        // Default empty
        return ""
    }
    
    private func calculateMonthlyPrice(_ yearlyPrice: Decimal) -> String? {
        let monthlyPrice = yearlyPrice / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }
}

// MARK: - Product.SubscriptionPeriod.Unit Extension

extension Product.SubscriptionPeriod.Unit {
    /// Human-readable display name for subscription period units
    public var displayName: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return "period"
        }
    }
}

// MARK: - Preview Provider

#Preview {
    PaywallView(
        headline: "Go Pro to Continue",
        privacyPolicyURL: URL(string: "https://example.com/privacy"),
        termsOfServiceURL: URL(string: "https://example.com/terms")
    )
}

#Preview("Custom Benefits") {
    PaywallView(
        headline: "Unlock Premium Features",
        benefits: [
            BenefitItem(
                icon: "star.fill",
                title: "Unlimited Access",
                description: "No restrictions or limits"
            ),
            BenefitItem(
                icon: "trophy.fill",
                title: "Exclusive Features",
                description: "Premium-only tools and options"
            )
        ],
        privacyPolicyURL: URL(string: "https://example.com/privacy"),
        termsOfServiceURL: URL(string: "https://example.com/terms")
    )
}
#endif
