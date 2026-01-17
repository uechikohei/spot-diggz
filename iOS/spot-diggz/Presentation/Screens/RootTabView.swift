import SwiftUI

/// A tab bar hosting the four primary sections of the app.
struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "list.bullet")
                }
            MapScreen()
                .tabItem {
                    Label("マップ", systemImage: "map")
                }
            PostView()
                .tabItem {
                    Label("投稿", systemImage: "plus.rectangle.on.rectangle")
                }
            ProfileView()
                .tabItem {
                    Label("プロフィール", systemImage: "person.crop.circle")
                }
        }
    }
}

#if DEBUG
struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
#endif