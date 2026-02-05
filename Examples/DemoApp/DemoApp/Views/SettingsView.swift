import SwiftUI
import StoreKit2Framework

/// Settings view demonstrating premium status management
///
/// This view shows how to integrate premium features in your settings:
/// - Display current premium status
/// - Upgrade button for free users
/// - Manage subscription for premium users
/// - Restore purchases functionality
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Premium section using the framework's component
                PremiumSettingsSection()
                
                // App info section
                appInfoSection
                
                // About section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section("App Information") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://github.com/Reuben-Enterprises-Ltd/StoreKit2Framework")!) {
                HStack {
                    Label("GitHub Repository", systemImage: "link")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                // Would open privacy policy in real app
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            
            Button {
                // Would open terms in real app
            } label: {
                Label("Terms of Service", systemImage: "doc.text")
            }
        } header: {
            Text("About")
        } footer: {
            Text("This is a demo app for the StoreKit2Framework. It demonstrates all the integration patterns and best practices.")
                .font(.caption)
        }
    }
}

#Preview("Free User") {
    SettingsView()
}

#Preview("Premium User - Form Style") {
    NavigationStack {
        Form {
            PremiumSettingsSection()
            
            Section("Other Settings") {
                Text("Setting 1")
                Text("Setting 2")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("Premium Status Row in List") {
    NavigationStack {
        List {
            PremiumStatusRow()
            Text("Other Setting")
            Text("Another Setting")
        }
        .navigationTitle("Settings")
    }
}
