import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var draftDisplayName = ""
    var waitingClues: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PassportHero(
                        profile: viewModel.profile,
                        onEdit: {
                            draftDisplayName = viewModel.profile.displayName
                            showEditProfile = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)

                    StatsView(profile: viewModel.profile, waitingClues: waitingClues)

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

                    PassportStampSection(profile: viewModel.profile)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Passport Controls")
                            .font(.caption2.weight(.black))
                            .foregroundColor(.saveCocoa)
                            .padding(.horizontal, 16)

                        NavigationLink {
                            SaveMemoryDebugView()
                        } label: {
                            SettingsRow(icon: "tray.full", title: "Local Memory", color: .wanderlyTerracotta)
                        }
                        .buttonStyle(.plain)

                        SettingsRow(icon: "arrow.right.square", title: "Sign Out", color: .red) {
                            Task { await viewModel.signOut() }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color.saveCream, Color.saveBlush.opacity(0.72), Color.saveMint.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("SAV-E Passport")
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
                Section("SAV-E Passport") {
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
                    Text("This name appears on your SAV-E passport. Email and sign-in provider are managed by your login account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Passport")
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

// MARK: - Passport

private struct PassportHero: View {
    let profile: UserProfile
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.saveInk, Color.saveCocoa],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "passport.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.saveHoney)
                }
                .frame(width: 70, height: 78)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.saveSuccess)
                        .background(Circle().fill(Color.savePaper))
                        .offset(x: 5, y: 5)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("SAV-E Passport")
                        .font(.caption2.weight(.black))
                        .foregroundColor(.saveHoney)
                    Text(profile.displayName)
                        .font(.title2.weight(.black))
                        .foregroundColor(.savePaper)
                        .lineLimit(2)
                    Text(profile.email ?? "Local memory agent")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.savePaper.opacity(0.76))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                PassportBadge(text: "MEMORY AGENT", color: .saveHoney)
                PassportBadge(text: "REVIEW FIRST", color: .saveSky)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.black))
                        .foregroundColor(.saveInk)
                        .frame(width: 32, height: 32)
                        .background(Color.savePaper.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit Passport")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.saveInk)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.saveHoney)
                        .frame(height: 4)
                        .padding(.horizontal, 16)
                }
        )
    }
}

private struct PassportBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundColor(.savePaper)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.22))
            .clipShape(Capsule())
    }
}

private struct PassportStampSection: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent stamps")
                    .font(.headline.weight(.black))
                    .foregroundColor(.saveInk)
                Spacer()
                Text(profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2.weight(.black))
                    .foregroundColor(.saveCocoa)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.saveHoney.opacity(0.18))
                    .clipShape(Capsule())
            }

            if profile.collections.isEmpty {
                PassportStampRow(icon: "rectangle.stack.badge.plus", title: "No stamps yet", value: "Hatch a clue into your first memory card")
            } else {
                ForEach(profile.collections.prefix(3)) { collection in
                    PassportStampRow(
                        icon: "seal.fill",
                        title: collection.name,
                        value: "\(collection.placeIds.count) memory cards"
                    )
                }
            }

            PassportStampRow(icon: "calendar", title: "Joined", value: profile.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .padding()
        .background(Color.savePaper.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.saveCocoa.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }
}

private struct PassportStampRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.saveCocoa)
                .frame(width: 30, height: 30)
                .background(Color.saveHoney.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.saveInk)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
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
