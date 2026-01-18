import SwiftUI

/// Displays a detailed list of favorite spots.
struct MyListDetailView: View {
    @EnvironmentObject var appState: SdzAppState

    var body: some View {
        List {
            if appState.favoriteSpots.isEmpty {
                Text("お気に入りはありません")
                    .foregroundColor(.secondary)
            } else {
                ForEach(appState.favoriteSpots) { spot in
                    NavigationLink(destination: SpotDetailView(spot: spot)) {
                        SpotCardView(spot: spot)
                    }
                }
            }
        }
        .navigationTitle("お気に入り一覧")
    }
}

#if DEBUG
struct MyListDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyListDetailView()
                .environmentObject(SdzAppState())
        }
    }
}
#endif
