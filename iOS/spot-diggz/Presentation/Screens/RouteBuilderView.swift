import SwiftUI

/// Builds a new route by selecting multiple spots.
struct RouteBuilderView: View {
    @EnvironmentObject var appState: SdzAppState
    @Environment(\.dismiss) private var dismiss

    @State private var routeName: String = ""
    @State private var selectedMode: SdzRouteMode = .walk
    @State private var spots: [SdzSpot] = []
    @State private var selectedSpotIds: Set<String> = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
        }
        .onAppear {
            seedDraftSelection()
            fetchSpots()
        }
    }

    private var content: some View {
        List {
            Section(header: Text("基本情報")) {
                TextField("ルート名（任意）", text: $routeName)
                Picker("移動手段", selection: $selectedMode) {
                    ForEach(SdzRouteMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("スポットを選択")) {
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("再読み込み") {
                            fetchSpots()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if spots.isEmpty {
                    Text("スポットがありません")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(spots) { spot in
                        Button(action: {
                            toggleSelection(for: spot)
                        }) {
                            SpotSelectionRow(
                                spot: spot,
                                isSelected: selectedSpotIds.contains(spot.spotId)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        }
        .navigationTitle("ルート作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveRoute()
                }
            }
        }
    }

    private func seedDraftSelection() {
        if !appState.routeDraftSpots.isEmpty {
            selectedSpotIds = Set(appState.routeDraftSpots.map(\.spotId))
        }
    }

    private func toggleSelection(for spot: SdzSpot) {
        errorMessage = nil
        if selectedSpotIds.contains(spot.spotId) {
            selectedSpotIds.remove(spot.spotId)
        } else {
            selectedSpotIds.insert(spot.spotId)
        }
    }

    private func saveRoute() {
        let selectedSpots = spots.filter { selectedSpotIds.contains($0.spotId) }
        if selectedSpots.isEmpty {
            errorMessage = "スポットを1件以上選択してください。"
            return
        }
        let trimmedName = routeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.isEmpty ? defaultRouteName : trimmedName
        appState.saveRoute(name: name, mode: selectedMode, spots: selectedSpots)
        appState.clearRouteDraft()
        dismiss()
    }

    private var defaultRouteName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "ルート \(formatter.string(from: Date()))"
    }

    private func fetchSpots() {
        isLoading = true
        errorMessage = nil
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        Task {
            do {
                let result = try await apiClient.fetchSpots(includeAuth: true)
                await MainActor.run {
                    self.spots = result
                    self.isLoading = false
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.errorMessage = message
                    self.isLoading = false
                }
            }
        }
    }
}

private struct SpotSelectionRow: View {
    let spot: SdzSpot
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.subheadline)
                if let description = spot.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !spot.tags.isEmpty {
                    Text(spot.tags.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct RouteBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        RouteBuilderView()
            .environmentObject(SdzAppState())
    }
}
#endif
