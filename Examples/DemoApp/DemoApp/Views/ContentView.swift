import SwiftUI
import StoreKit2Framework

/// Main content view demonstrating navigation and feature organization
///
/// This view shows how to structure your app with the framework:
/// - Navigation to different sections
/// - Premium badge in navigation bar
/// - Feature list with gating
/// - Settings integration
struct ContentView: View {
    @State private var showSettings = false
    @State private var showOnboarding = false
    
    private let premiumManager = PremiumManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Feature list
                    FeatureListView()
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Demo App")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Premium badge (only shows if premium)
                        PremiumBadge()
                        
                        // Settings button
                        Button("Settings", systemImage: "gearshape") {
                            showSettings = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            Text("Welcome to StoreKit2Framework Demo")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Explore all the integration patterns and features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 8) {
                // View onboarding
                Button {
                    showOnboarding = true
                } label: {
                    Label("View Onboarding", systemImage: "hand.wave")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                // Settings
                Button {
                    showSettings = true
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ContentView()
}
