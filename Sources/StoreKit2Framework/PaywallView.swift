#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

// MARK: - Paywall Configuration

/// Configuration for PaywallView appearance and behavior
public struct PaywallConfiguration {
    /// Custom headline text
    public var headline: String
    
    /// Custom features/benefits list
    public var features: [String]
    
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
        features: [String] = [],
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
    
    /// Paywall configuration
    public let configuration: PaywallConfiguration
    
    /// Optional headline to customize the paywall context (deprecated - use configuration)
    public let headline: String?
    
    /// Optional benefits list (deprecated - use configuration)
    public let benefits: [BenefitItem]?
    
    /// Privacy policy URL (required for App Store submission)
    public let privacyPolicyURL: URL?
    
    /// Terms of service URL (required for App Store submission)
    public let termsOfServiceURL: URL?
    
    @State private var selectedProduct: Product?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false
    @State private var isRestoring = false
    
    /// Initialize paywall with configuration
    /// - Parameters:
    ///   - configuration: Paywall configuration (default uses PremiumManager configuration)
    ///   - privacyPolicyURL: URL to privacy policy (required for App Store)
    ///   - termsOfServiceURL: URL to terms of service (required for App Store)
    public init(
        configuration: PaywallConfiguration? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil
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
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
    }
    
    /// Initialize paywall with optional customization (legacy API)
    /// - Parameters:
    ///   - headline: Custom headline text (default: "Unlock Premium Features")
    ///   - benefits: Custom benefits list (default: nil - uses built-in benefits)
    ///   - privacyPolicyURL: URL to privacy policy (required for App Store)
    ///   - termsOfServiceURL: URL to terms of service (required for App Store)
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
            features: benefits?.map { $0.title } ?? managerConfig.features,
            showRestoreButton: true,
            showPrivacyLinks: true,
            tintColor: nil
        )
        
        self.headline = headline
        self.benefits = benefits
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
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
                    Button("Maybe Later") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Failed", isPresented: $showingErrorAlert) {
                Button("OK") {
                    showingErrorAlert = false
                }
                Button("Try Again") {
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
            
            Text("Get the most out of your experience")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading products...")
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
                    icon: Self.defaultFeatureIcons[index % Self.defaultFeatureIcons.count],
                    title: feature,
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
                title: "Advanced Analytics",
                description: "Deep insights into your data"
            ),
            BenefitItem(
                icon: "icloud",
                title: "Cloud Sync",
                description: "Access everywhere, anytime"
            ),
            BenefitItem(
                icon: "paintbrush",
                title: "Premium Themes",
                description: "Customize your experience"
            ),
            BenefitItem(
                icon: "bolt.fill",
                title: "Priority Support",
                description: "Get help when you need it"
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
                    Text("Start Premium")
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
                        Text("Restore Purchases")
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
        if configuration.showPrivacyLinks && (privacyPolicyURL != nil || termsOfServiceURL != nil) {
            HStack(spacing: 12) {
                if let privacyURL = privacyPolicyURL {
                    Link("Privacy Policy", destination: privacyURL)
                }
                
                if privacyPolicyURL != nil && termsOfServiceURL != nil {
                    Text("•")
                        .foregroundStyle(.secondary)
                }
                
                if let termsURL = termsOfServiceURL {
                    Link("Terms of Service", destination: termsURL)
                }
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
            
            Text("Unable to Load Products")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
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
                        Text("Best Value")
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
                        
                        if let subscription = product.subscription {
                            let period = subscription.subscriptionPeriod
                            Text("\(period.value) \(period.unit.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Show savings for yearly
                        if isRecommended, let subscription = product.subscription,
                           subscription.subscriptionPeriod.unit == .year {
                            Text("Save up to 40%")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.headline)
                        
                        if let subscription = product.subscription,
                           subscription.subscriptionPeriod.unit == .year,
                           let monthlyPrice = calculateMonthlyPrice(product.price) {
                            Text("\(monthlyPrice)/month")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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
