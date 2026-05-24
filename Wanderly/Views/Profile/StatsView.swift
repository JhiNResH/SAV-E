import SwiftUI

struct StatsView: View {
    let profile: UserProfile
    var waitingClues: Int = 0

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ], spacing: 8) {
            StatItem(value: "\(profile.savedCount)", label: "Memories", color: .saveBerry, icon: "rectangle.stack.fill")
            StatItem(value: "\(profile.visitedCount)", label: "Verified", color: .saveSuccess, icon: "checkmark.seal.fill")
            StatItem(value: "\(profile.citiesCount)", label: "Cities", color: .saveHoney, icon: "building.2.fill")
            StatItem(value: "\(waitingClues)", label: "Waiting clues", color: .saveSignal, icon: "circle.hexagongrid.fill")
        }
        .padding(12)
        .saveNotebookPage(cornerRadius: 18)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundColor(.saveInk)
            }
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    StatsView(profile: .mock)
        .padding()
        .background(Color.wanderlyCream)
}
