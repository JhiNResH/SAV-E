import SwiftUI

struct PlaceCard: View {
    let place: Place

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            categoryStamp

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(place.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyCharcoal)
                        .lineLimit(1)

                    Spacer()

                    sourceBadge
                }

                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let rating = place.googleRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let priceRange = place.priceRange {
                        Text(priceRange)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(statusLabel)
                        .font(.system(size: 10))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(place.status == .visited ? Color.saveMint : Color.saveBlush)
                        .foregroundColor(place.status == .visited ? Color.saveCocoa : Color.saveBerry)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .wanderlyCard()
    }

    private var categoryStamp: some View {
        Image(systemName: place.category.iconName)
            .font(.title3.weight(.bold))
            .foregroundColor(Color.saveStampForeground(for: place.category))
            .frame(width: 46, height: 46)
            .background(Color.saveStampColor(for: place.category))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 2)
            )
    }

    private var sourceBadge: some View {
        HStack(spacing: 4) {
            PlatformIcon(platform: place.sourcePlatform, size: 12)
            Text(sourceLabel)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.saveRose)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.saveBlush)
        .clipShape(Capsule())
    }

    private var sourceLabel: String {
        place.sourcePlatform == .other ? "Memory" : "\(place.sourcePlatform.displayName) memory"
    }

    private var statusLabel: String {
        place.status == .visited ? "Visited" : "Memory saved"
    }
}

#Preview {
    VStack {
        PlaceCard(place: .mock)
        PlaceCard(place: Place.mockList[1])
    }
    .padding()
    .background(Color.wanderlyCream)
}
