#if canImport(StoreKit) && canImport(SwiftUI)
import SwiftUI
import StoreKit

// MARK: - View Modifiers

extension View {
    /// Hides the view completely if the user doesn't have premium access
    ///
    /// Example usage:
    /// ```swift
    /// NavigationLink("Advanced Settings") {
    ///     AdvancedSettingsView()
    /// }
    /// .premiumOnly()
    /// ```
    public func premiumOnly() -> some View {
        modifier(PremiumOnlyModifier())
    }
    
    /// Shows a blur overlay with paywall button when tapped if user doesn't have premium
    ///
    /// Example usage:
    /// ```swift
    /// ContentView()
    ///     .premiumGated(headline: "Unlock Advanced Features")
    /// ```
    public func premiumGated(headline: String = "Unlock Premium Features") -> some View {
        modifier(PremiumGatedModifier(headline: headline))
    }
    
    /// Disables the view and shows a lock icon if user doesn't have premium
    ///
    /// Example usage:
    /// ```swift
    /// Button("Export All") {
    ///     exportAll()
    /// }
    /// .premiumRequired()
    /// ```
    public func premiumRequired() -> some View {
        modifier(PremiumRequiredModifier())
    }
}

// MARK: - Premium Only Modifier

private struct PremiumOnlyModifier: ViewModifier {
    private let premiumManager = PremiumManager.shared
    
    func body(content: Content) -> some View {
        if premiumManager.isPremium {
            content
        }
    }
}

// MARK: - Premium Gated Modifier

private struct PremiumGatedModifier: ViewModifier {
    private let premiumManager = PremiumManager.shared
    let headline: String
    
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if !premiumManager.isPremium {
                    PremiumOverlay(headline: headline, showPaywall: $showPaywall)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(headline: headline)
            }
            .onAppear {
                premiumManager.ensureInitialized()
            }
    }
}

// MARK: - Premium Required Modifier

private struct PremiumRequiredModifier: ViewModifier {
    private let premiumManager = PremiumManager.shared
    
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .disabled(!premiumManager.isPremium)
            .opacity(premiumManager.isPremium ? 1.0 : 0.6)
            .overlay(alignment: .trailing) {
                if !premiumManager.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
            }
            .onTapGesture {
                if !premiumManager.isPremium {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(headline: "Unlock Premium Features")
            }
            .onAppear {
                premiumManager.ensureInitialized()
            }
    }
}

// MARK: - Premium Overlay

/// Overlay component for locked premium content
///
/// Displays a blur effect with a lock icon and upgrade button over premium content.
///
/// Example usage:
/// ```swift
/// ZStack {
///     PremiumContentView()
///     
///     if !premiumManager.isPremium {
///         PremiumOverlay(headline: "Unlock This Feature", showPaywall: $showPaywall)
///     }
/// }
/// ```
public struct PremiumOverlay: View {
    let headline: String
    @Binding var showPaywall: Bool
    
    public init(headline: String = "Unlock Premium Features", showPaywall: Binding<Bool>) {
        self.headline = headline
        self._showPaywall = showPaywall
    }
    
    public var body: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Lock content
            VStack(spacing: 20) {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
                
                // Headline
                Text(headline)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Upgrade button
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Premium")
                    }
                    .bold()
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}

// MARK: - PremiumManager Extension

extension PremiumManager {
    /// Check if user has premium and show paywall if not
    ///
    /// This method can be used for programmatic feature gating. The feature parameter
    /// can be used for analytics or logging to track which features users are trying to access.
    ///
    /// Example usage:
    /// ```swift
    /// premiumManager.requirePremium(feature: "Export") {
    ///     // User has premium, can proceed
    ///     performExport()
    /// }
    /// 
    /// // If not premium, show paywall manually
    /// if !premiumManager.isPremium {
    ///     showPaywall = true
    /// }
    /// ```
    public func requirePremium(
        feature: String,
        onUpgrade: @escaping () -> Void
    ) {
        if isPremium {
            onUpgrade()
        } else {
            // Feature access denied - calling code should show paywall
            // The feature parameter can be used for analytics/logging:
            // print("Premium feature '\(feature)' access denied")
        }
    }
}

// MARK: - Preview Providers

#Preview("Premium Only - Free User") {
    VStack(spacing: 20) {
        Text("Always Visible")
            .font(.headline)
        
        Text("Premium Only Content")
            .font(.headline)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 8))
            .premiumOnly()
        
        Text("Also Always Visible")
            .font(.headline)
    }
    .padding()
}

#Preview("Premium Only - Premium User") {
    VStack(spacing: 20) {
        Text("Always Visible")
            .font(.headline)
        
        Text("Premium Only Content")
            .font(.headline)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 8))
            .premiumOnly()
        
        Text("Also Always Visible")
            .font(.headline)
    }
    .padding()
}

#Preview("Premium Gated - Free User") {
    VStack {
        Text("My Premium Content")
            .font(.largeTitle)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
    .premiumGated(headline: "Unlock Advanced Features")
}

#Preview("Premium Gated - Premium User") {
    VStack {
        Text("My Premium Content")
            .font(.largeTitle)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
    .premiumGated(headline: "Unlock Advanced Features")
}

#Preview("Premium Required Button - Free User") {
    VStack(spacing: 20) {
        Button("Regular Button") {
            print("Tapped")
        }
        .buttonStyle(.borderedProminent)
        
        Button("Export All Data") {
            print("Export tapped")
        }
        .buttonStyle(.borderedProminent)
        .premiumRequired()
        
        Button("Share Report") {
            print("Share tapped")
        }
        .buttonStyle(.borderedProminent)
        .premiumRequired()
    }
    .padding()
}

#Preview("Premium Required Button - Premium User") {
    VStack(spacing: 20) {
        Button("Regular Button") {
            print("Tapped")
        }
        .buttonStyle(.borderedProminent)
        
        Button("Export All Data") {
            print("Export tapped")
        }
        .buttonStyle(.borderedProminent)
        .premiumRequired()
        
        Button("Share Report") {
            print("Share tapped")
        }
        .buttonStyle(.borderedProminent)
        .premiumRequired()
    }
    .padding()
}

#Preview("Premium Overlay Standalone") {
    @Previewable @State var showPaywall = false
    
    ZStack {
        // Simulated premium content
        VStack {
            Text("Premium Content")
                .font(.largeTitle)
                .bold()
            Text("This is locked behind premium")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blue.gradient)
        
        // Overlay
        PremiumOverlay(headline: "Unlock This Feature", showPaywall: $showPaywall)
    }
    .sheet(isPresented: $showPaywall) {
        PaywallView(headline: "Unlock This Feature")
    }
}

#Preview("Navigation with Premium Only") {
    NavigationStack {
        List {
            NavigationLink("Regular Feature") {
                Text("Available to all")
            }
            
            NavigationLink("Advanced Analytics") {
                Text("Premium feature")
            }
            .premiumOnly()
            
            NavigationLink("Export Data") {
                Text("Premium feature")
            }
            .premiumOnly()
        }
        .navigationTitle("Features")
    }
}

#endif
