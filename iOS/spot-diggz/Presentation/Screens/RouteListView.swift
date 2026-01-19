import SwiftUI

/// Displays saved routes and a draft route entry point.
struct RouteListView: View {
    @EnvironmentObject var appState: SdzAppState
    @State private var showBuilder: Bool = false

    var body: some View {
        NavigationView {
            List {
                if !appState.routeDraftSpots.isEmpty {
                    Section(header: Text("下書き")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("下書きスポット \(appState.routeDraftSpots.count)件")
                                .font(.subheadline)
                            Button("下書きからルートを作成") {
                                showBuilder = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        ForEach(appState.routeDraftSpots) { spot in
                            Text(spot.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("下書きをクリア") {
                            appState.clearRouteDraft()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }

                Section(header: Text("保存済みルート")) {
                    if appState.savedRoutes.isEmpty {
                        Text("ルートはまだありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.savedRoutes) { route in
                            NavigationLink(destination: RouteDetailView(route: route)) {
                                RouteRowView(route: route)
                            }
                        }
                        .onDelete { indexSet in
                            let routes = indexSet.map { appState.savedRoutes[$0] }
                            routes.forEach { route in
                                appState.deleteRoute(route)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ルート")
            .toolbar {
                Button("新規作成") {
                    showBuilder = true
                }
            }
            .sheet(isPresented: $showBuilder) {
                RouteBuilderView()
            }
        }
    }
}

private struct RouteRowView: View {
    let route: SdzRoute

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.headline)
                Text("\(route.mode.label)・\(route.spots.count)スポット")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        RouteListView()
            .environmentObject(SdzAppState())
    }
}
#endif
