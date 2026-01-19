import SwiftUI

/// A tab bar hosting the four primary sections of the app.
struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("スポット", systemImage: "map")
                }
            MyListView()
                .tabItem {
                    Label("お気に入り", systemImage: "heart")
                }
            RouteListView()
                .tabItem {
                    Label("ルート", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
            PostView()
                .tabItem {
                    Label("投稿", systemImage: "plus.circle")
                }
            ProfileView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
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
