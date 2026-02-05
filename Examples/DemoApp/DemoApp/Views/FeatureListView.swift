import SwiftUI
import StoreKit2Framework

/// Feature list demonstrating various feature gating patterns
///
/// This view demonstrates all the different ways you can gate premium features:
/// 1. `.premiumOnly()` - Completely hides features from free users
/// 2. `.premiumRequired()` - Shows but disables features with lock icon
/// 3. `.premiumGated()` - Shows content but with blur overlay and unlock prompt
/// 4. Manual gating - Custom implementation for specific use cases
struct FeatureListView: View {
    @State private var showPaywall = false
    @State private var exportCount = 0
    
    private let premiumManager = PremiumManager.shared
    private let maxFreeExports = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Features")
                .font(.title2)
                .bold()
            
            // Free features section
            freeFeaturesSection
            
            // Premium features section
            premiumFeaturesSection
            
            // Usage limits example
            usageLimitsSection
        }
    }
    
    // MARK: - Free Features
    
    private var freeFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Free Features")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                FeatureCard(
                    icon: "doc.text",
                    title: "Basic Documents",
                    description: "Create and edit basic documents",
                    isFree: true
                )
                
                FeatureCard(
                    icon: "photo",
                    title: "Photo Library",
                    description: "Access your photo library",
                    isFree: true
                )
                
                FeatureCard(
                    icon: "list.bullet",
                    title: "Simple Lists",
                    description: "Create simple task lists",
                    isFree: true
                )
            }
        }
    }
    
    // MARK: - Premium Features
    
    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Premium Features")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if !premiumManager.isPremium {
                    Button("Unlock All", systemImage: "lock.open") {
                        showPaywall = true
                    }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            VStack(spacing: 8) {
                // Using .premiumRequired() - shows but disabled
                FeatureCard(
                    icon: "chart.xyaxis.line",
                    title: "Advanced Analytics",
                    description: "Deep insights and data visualization",
                    isFree: false
                )
                .premiumRequired()
                
                // Using .premiumRequired() - shows but disabled
                FeatureCard(
                    icon: "icloud.and.arrow.up",
                    title: "Cloud Sync",
                    description: "Sync across all your devices",
                    isFree: false
                )
                .premiumRequired()
                
                // Using .premiumRequired() - shows but disabled
                FeatureCard(
                    icon: "paintbrush.pointed",
                    title: "Custom Themes",
                    description: "Personalize your experience",
                    isFree: false
                )
                .premiumRequired()
                
                // This feature is completely hidden for free users
                FeatureCard(
                    icon: "person.3",
                    title: "Team Collaboration",
                    description: "Work together with your team",
                    isFree: false
                )
                .premiumOnly()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(headline: "Unlock All Premium Features")
        }
    }
    
    // MARK: - Usage Limits
    
    private var usageLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage-Based Gating")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Example of limit-based feature gating
            VStack(spacing: 12) {
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exports")
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        if premiumManager.isPremium {
                            Text("Unlimited")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("\(exportCount) of \(maxFreeExports) used")
                                .font(.caption)
                                .foregroundStyle(exportCount >= maxFreeExports ? .red : .secondary)
                        }
                    }
                    
                    if !premiumManager.isPremium {
                        ProgressView(value: Double(exportCount), total: Double(maxFreeExports))
                            .tint(exportCount >= maxFreeExports ? .red : .blue)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(.rect(cornerRadius: 12))
                
                // Export button with limit checking
                Button {
                    handleExport()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Document")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canExport ? .blue : .secondary.opacity(0.3))
                    .foregroundStyle(canExport ? .white : .secondary)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!canExport)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canExport: Bool {
        premiumManager.isPremium || exportCount < maxFreeExports
    }
    
    private func handleExport() {
        if premiumManager.isPremium {
            // Premium users can export unlimited
            exportCount += 1
            print("✅ Exported (Premium - Unlimited)")
        } else if exportCount < maxFreeExports {
            // Free users can export up to limit
            exportCount += 1
            print("✅ Exported (\(exportCount)/\(maxFreeExports))")
            
            // Show paywall if limit reached
            if exportCount >= maxFreeExports {
                showPaywall = true
            }
        } else {
            // Limit reached - show paywall
            showPaywall = true
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isFree: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isFree ? .blue : .purple)
                .frame(width: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .bold()
                    
                    if !isFree {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview("Feature List") {
    ScrollView {
        FeatureListView()
            .padding()
    }
}

#Preview("Single Feature Card - Free") {
    FeatureCard(
        icon: "doc.text",
        title: "Basic Documents",
        description: "Create and edit basic documents",
        isFree: true
    )
    .padding()
}

#Preview("Single Feature Card - Premium") {
    FeatureCard(
        icon: "chart.xyaxis.line",
        title: "Advanced Analytics",
        description: "Deep insights and data visualization",
        isFree: false
    )
    .padding()
}
