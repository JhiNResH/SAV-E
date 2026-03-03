import SwiftUI
import MapKit

struct ClipContentView: View {
    @State private var tripName: String = "Shared Trip"
    @State private var stops: [ClipTripStop] = ClipTripStop.mockList
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Map preview
                    Map(coordinateRegion: $region, annotationItems: stops) { stop in
                        MapMarker(coordinate: stop.coordinate, tint: Color(hex: "C75B39"))
                    }
                    .frame(height: 200)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Trip info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tripName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "2C2C2E"))

                        Text("\(stops.count) stops")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Stops list
                    VStack(spacing: 12) {
                        ForEach(stops) { stop in
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "C75B39"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stop.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: "2C2C2E"))
                                    Text(stop.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(Color(hex: "FFF8F0"))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)

                    // CTA
                    VStack(spacing: 12) {
                        Button(action: {
                            // TODO: Deep link to full app
                        }) {
                            Text("Open in Wanderly")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "C75B39"))
                                .cornerRadius(16)
                        }

                        Button(action: {
                            // TODO: App Store link
                        }) {
                            Text("Get the Full App")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "C75B39"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(hex: "FFF8F0"))
            .navigationTitle("Trip Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            handleIncomingURL(activity.webpageURL)
        }
    }

    private func handleIncomingURL(_ url: URL?) {
        // TODO: Parse shared trip link and load trip data
        guard let url = url else { return }
        print("App Clip opened with URL: \(url)")
    }
}

// MARK: - Clip Trip Stop Model

struct ClipTripStop: Identifiable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension ClipTripStop {
    static let mockList: [ClipTripStop] = [
        ClipTripStop(id: UUID(), name: "Tartine Bakery", address: "600 Guerrero St, SF", latitude: 37.7614, longitude: -122.4241),
        ClipTripStop(id: UUID(), name: "Dolores Park", address: "Dolores St, SF", latitude: 37.7596, longitude: -122.4269),
        ClipTripStop(id: UUID(), name: "Bi-Rite Creamery", address: "3692 18th St, SF", latitude: 37.7618, longitude: -122.4256),
    ]
}

// MARK: - Hex Color (standalone for App Clip target)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ClipContentView()
}
