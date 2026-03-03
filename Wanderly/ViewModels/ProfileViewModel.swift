import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .mock
    @Published var isLoading = false

    private let supabaseService: SupabaseServiceProtocol
    private let authService: PrivyAuthService

    init(
        supabaseService: SupabaseServiceProtocol = SupabaseService.shared,
        authService: PrivyAuthService = .shared
    ) {
        self.supabaseService = supabaseService
        self.authService = authService
    }

    func loadProfile() async {
        guard let userId = authService.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if let profile = try await supabaseService.fetchProfile(for: userId) {
                self.profile = profile
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            print("Failed to sign out: \(error)")
        }
    }
}
