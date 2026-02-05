import Testing
@testable import StoreKit2Framework

/// Basic tests for StoreKit2Framework package setup
@Suite("StoreKit2Framework Tests")
struct StoreKit2FrameworkTests {
    
    @Test("Package version is defined")
    func packageVersionIsDefined() async throws {
        #expect(!StoreKit2Framework.version.isEmpty)
        #expect(StoreKit2Framework.version == "0.1.0")
    }
}
