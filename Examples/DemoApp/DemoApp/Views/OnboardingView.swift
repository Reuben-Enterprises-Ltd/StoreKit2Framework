import SwiftUI
import StoreKit2Framework

/// Onboarding flow demonstrating paywall integration
///
/// This view shows how to integrate the paywall during your onboarding flow.
/// Key patterns demonstrated:
/// - Showing benefits before the paywall
/// - "Skip" option for users who want to continue with free tier
/// - Smooth transition after upgrade or skip
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let premiumManager = PremiumManager.shared
    
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "star.fill",
            title: "Welcome!",
            description: "Discover amazing features designed to enhance your experience"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Powerful Features",
            description: "Access advanced tools and capabilities to unlock your potential"
        ),
        OnboardingPage(
            icon: "crown.fill",
            title: "Go Premium",
            description: "Upgrade now to access all features and support development"
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? .blue : .secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Action buttons
                VStack(spacing: 12) {
                    if currentPage < pages.count - 1 {
                        // Continue button for first pages
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue.gradient)
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 16))
                        }
                    } else {
                        // Upgrade button on last page
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Upgrade to Premium")
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.gradient)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 16))
                        }
                    }
                    
                    // Skip button
                    Button {
                        dismiss()
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Skip" : "Maybe Later")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                // Show paywall with custom headline for onboarding context
                PaywallView(
                    configuration: .init(
                        headline: "Start Your Premium Journey",
                        features: premiumManager.currentConfiguration.features,
                        showRestoreButton: true,
                        showPrivacyLinks: true,
                        tintColor: nil
                    ),
                    analyticsSource: "onboarding"
                )
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

#Preview("Page 1") {
    OnboardingView()
}

#Preview("Paywall Sheet") {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            PaywallView(
                configuration: .init(
                    headline: "Start Your Premium Journey",
                    features: [],
                    showRestoreButton: true,
                    showPrivacyLinks: true,
                    tintColor: nil
                ),
                analyticsSource: "onboarding_preview"
            )
        }
}
