import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)

            PlaceListView()
                .tabItem {
                    Label("Places", systemImage: "list.bullet")
                }
                .tag(1)

            TripPlannerView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.wanderlyTerracotta)
    }
}

#Preview {
    ContentView()
}
