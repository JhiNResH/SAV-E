import SwiftUI
import MapKit

struct NavigationCardComponent: View {
    let place: Place
    let mode: WanderlyAIResponse.TransportMode

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: modeIcon)
                .font(.system(size: 48))
                .foregroundColor(.saveCocoa)

            VStack(spacing: 6) {
                Text(place.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.saveInk)
                    .multilineTextAlignment(.center)

                Text(place.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Label(modeLabel, systemImage: modeIcon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.saveCocoa)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.saveCocoa.opacity(0.12))
                .cornerRadius(12)

            Button(action: openInMaps) {
                Label("Start Navigation", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.headline)
                    .foregroundColor(.saveInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.saveHoney)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.saveNotebookLine.opacity(0.82), lineWidth: 1.1)
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var modeIcon: String {
        switch mode {
        case .walking: return "figure.walk"
        case .transit: return "tram.fill"
        case .driving: return "car.fill"
        }
    }

    private var modeLabel: String {
        switch mode {
        case .walking: return "Walking directions"
        case .transit: return "Transit directions"
        case .driving: return "Driving directions"
        }
    }

    private func openInMaps() {
        let navMode: NavigationService.Mode = switch mode {
        case .walking: .walking
        case .transit: .transit
        case .driving: .driving
        }
        NavigationService.navigate(to: place.coordinate, name: place.name, mode: navMode)
    }
}
