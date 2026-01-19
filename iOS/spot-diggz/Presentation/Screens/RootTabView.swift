import SwiftUI

/// A tab bar hosting the four primary sections of the app.
struct RootTabView: View {
    @EnvironmentObject var appState: SdzAppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("スポット", systemImage: "map")
                }
                .tag(SdzTab.spots)
            MyListView()
                .tabItem {
                    Label("お気に入り", systemImage: "heart")
                }
                .tag(SdzTab.favorites)
            RouteListView()
                .tabItem {
                    Label("ルート", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
                .tag(SdzTab.routes)
            PostView()
                .tabItem {
                    Label("投稿", systemImage: "plus.circle")
                }
                .tag(SdzTab.post)
            ProfileView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(SdzTab.settings)
        }
    }
}

#if DEBUG
struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(SdzAppState())
    }
}
#endif
