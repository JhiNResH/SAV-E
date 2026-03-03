import Foundation

// MARK: - Protocol

protocol AuthServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUserId: String? { get }
    func signInWithApple() async throws
    func signInWithGoogle() async throws
    func signInWithEmail(_ email: String) async throws
    func verifyEmailCode(_ code: String) async throws
    func signOut() async throws
}

// MARK: - Auth State

enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticated(userId: String)
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notConfigured
    case signInFailed(String)
    case signOutFailed
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Privy SDK not configured"
        case .signInFailed(let reason): return "Sign in failed: \(reason)"
        case .signOutFailed: return "Sign out failed"
        case .invalidCode: return "Invalid verification code"
        }
    }
}

// MARK: - Stub Implementation

final class PrivyAuthService: ObservableObject, AuthServiceProtocol {
    static let shared = PrivyAuthService()

    @Published var authState: AuthState = .unauthenticated

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var currentUserId: String? {
        if case .authenticated(let userId) = authState { return userId }
        return nil
    }

    private let appId: String?

    init(appId: String? = nil) {
        self.appId = appId ?? ProcessInfo.processInfo.environment["PRIVY_APP_ID"]
    }

    func signInWithApple() async throws {
        // TODO: Implement Privy Apple Sign In
        // Privy.shared.loginWithApple()
        await MainActor.run {
            authState = .authenticated(userId: "mock-user-\(UUID().uuidString.prefix(8))")
        }
    }

    func signInWithGoogle() async throws {
        // TODO: Implement Privy Google Sign In
        await MainActor.run {
            authState = .authenticated(userId: "mock-user-\(UUID().uuidString.prefix(8))")
        }
    }

    func signInWithEmail(_ email: String) async throws {
        // TODO: Implement Privy Email OTP
        // Privy.shared.sendOTP(to: email)
    }

    func verifyEmailCode(_ code: String) async throws {
        // TODO: Implement Privy OTP verification
        await MainActor.run {
            authState = .authenticated(userId: "mock-user-\(UUID().uuidString.prefix(8))")
        }
    }

    func signOut() async throws {
        // TODO: Implement Privy sign out
        await MainActor.run {
            authState = .unauthenticated
        }
    }
}
