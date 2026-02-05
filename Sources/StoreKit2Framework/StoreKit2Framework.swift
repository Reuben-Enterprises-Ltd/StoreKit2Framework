import Foundation

/// StoreKit2Framework - A modern Swift Package for implementing StoreKit 2 subscriptions.
///
/// This framework provides a simple, reusable API for managing in-app purchases and subscriptions
/// using StoreKit 2's modern async/await APIs.
///
/// ## Topics
///
/// ### Getting Started
/// - ``PremiumManager`` - The main manager class for handling all StoreKit operations
/// - ``StoreError`` - Error types for StoreKit operations
///
/// ### Core Functionality
/// - Product loading from App Store
/// - Purchase processing with transaction verification
/// - Restore purchases functionality
/// - Real-time transaction monitoring
/// - Premium status caching for instant UI updates
///
public struct StoreKit2Framework {
    /// The version of the StoreKit2Framework
    public static let version = "0.1.0"
    
    private init() {}
}
