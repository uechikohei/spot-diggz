import SwiftUI

/// Displays a summary of the user's favorite spots.
struct MyListView: View {
    @EnvironmentObject var appState: SdzAppState

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("お気に入り数")
                        Spacer()
                        Text("\(appState.favoriteSpots.count)")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: MyListDetailView()) {
                        Text("詳細一覧を見る")
                    }
                }

                Section(header: Text("最近のお気に入り")) {
                    if recentFavorites.isEmpty {
                        Text("お気に入りはありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(recentFavorites) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                SpotCardView(spot: spot)
                            }
                        }
                    }
                }
            }
            .navigationTitle("マイリスト")
        }
    }

    private var recentFavorites: [SdzSpot] {
        Array(appState.favoriteSpots.prefix(3))
    }
}

#if DEBUG
struct MyListView_Previews: PreviewProvider {
    static var previews: some View {
        MyListView()
            .environmentObject(SdzAppState())
    }
}
#endif
