import SwiftUI

struct SaveMemoryDebugView: View {
    @State private var records: [SaveMemoryRecord] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if records.isEmpty && errorMessage == nil {
                ContentUnavailableView(
                    "No Local Memory Yet",
                    systemImage: "tray",
                    description: Text("Use Share Sheet or Siri Shortcuts to save a source into SAV-E memory.")
                )
            }

            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(record.displayTitle)
                            .font(.headline)
                            .foregroundColor(.wanderlyCharcoal)
                        Spacer()
                        Text(record.state.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.wanderlyTerracotta)
                    }

                    if let address = record.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let sourceURL = record.sourceURL {
                        Text(sourceURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Local Memory")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadRecords() }
        .refreshable { loadRecords() }
    }

    private func loadRecords() {
        do {
            records = try SaveLocalVaultService.shared.recentRecords(limit: 50)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SaveMemoryDebugView()
    }
}
