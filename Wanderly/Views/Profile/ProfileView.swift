import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var draftDisplayName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar & Name
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.wanderlySage)

                        Text(viewModel.profile.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.wanderlyCharcoal)

                        Button {
                            draftDisplayName = viewModel.profile.displayName
                            showEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.wanderlyTerracotta)
                        }
                        .buttonStyle(.plain)

                        if let email = viewModel.profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if viewModel.profile.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                Text("Premium")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.wanderlyAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.wanderlyAmber.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 16)

                    // Stats
                    StatsView(profile: viewModel.profile)

                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                            Text(errorMessage)
                                .lineLimit(2)
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    ProfileSummaryCard(profile: viewModel.profile)

                    // Collections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collections")
                            .font(.headline)
                            .foregroundColor(.wanderlyCharcoal)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.profile.collections) { collection in
                                    CollectionCard(collection: collection)
                                }

                                // Add collection
                                Button(action: {}) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.wanderlyTerracotta)
                                        Text("New")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Color.wanderlyTerracotta.opacity(0.08))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.wanderlyTerracotta.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Settings section
                    VStack(spacing: 0) {
                        SettingsRow(icon: "crown", title: "Upgrade to Premium", color: .wanderlyAmber)
                        SettingsRow(icon: "bell", title: "Notifications", color: .wanderlyTerracotta)
                        SettingsRow(icon: "questionmark.circle", title: "Help & Feedback", color: .wanderlySage)
                        SettingsRow(icon: "arrow.right.square", title: "Sign Out", color: .red) {
                            Task { await viewModel.signOut() }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color.wanderlyCream)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draftDisplayName = viewModel.profile.displayName
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(
                displayName: $draftDisplayName,
                isSaving: viewModel.isSaving,
                errorMessage: viewModel.errorMessage,
                onCancel: { showEditProfile = false },
                onSave: {
                    let saved = await viewModel.updateDisplayName(draftDisplayName)
                    if saved { showEditProfile = false }
                }
            )
        }
    }
}

// MARK: - Edit Profile

private struct EditProfileSheet: View {
    @Binding var displayName: String
    let isSaving: Bool
    let errorMessage: String?
    let onCancel: () -> Void
    let onSave: () async -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .focused($isNameFocused)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Text("This name appears on your SAV-E profile. Email and sign-in provider are managed by your login account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await onSave() }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

// MARK: - Profile Summary

private struct ProfileSummaryCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .foregroundColor(.wanderlyCharcoal)

            VStack(spacing: 12) {
                ProfileInfoRow(
                    icon: "person.crop.circle",
                    title: "Name",
                    value: profile.displayName
                )

                ProfileInfoRow(
                    icon: "envelope",
                    title: "Email",
                    value: profile.email ?? "Not available"
                )

                ProfileInfoRow(
                    icon: "calendar",
                    title: "Joined",
                    value: profile.createdAt.formatted(date: .abbreviated, time: .omitted)
                )

                ProfileInfoRow(
                    icon: "checkmark.seal",
                    title: "Plan",
                    value: profile.isPremium ? "Premium" : "Standard"
                )
            }
        }
        .padding()
        .wanderlyCard()
        .padding(.horizontal)
    }
}

private struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.wanderlyTerracotta)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.wanderlyCharcoal)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: PlaceCollection

    var body: some View {
        VStack(spacing: 8) {
            Text(collection.emoji)
                .font(.largeTitle)
            Text(collection.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.wanderlyCharcoal)
            Text("\(collection.placeIds.count) places")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .wanderlyCard()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.wanderlyCharcoal)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ProfileView()
}
