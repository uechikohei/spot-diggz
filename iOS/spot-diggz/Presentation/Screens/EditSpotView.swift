import SwiftUI
import CoreLocation

/// Editing screen for a spot posted by the current user.
struct EditSpotView: View {
    @EnvironmentObject var appState: SdzAppState
    let spot: SdzSpot

    @StateObject private var locationManager = SdzLocationManager()
    @State private var name: String
    @State private var descriptionText: String
    @State private var tagsString: String
    @State private var location: SdzSpotLocation?
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    @State private var showLocationPickerSheet: Bool = false

    init(spot: SdzSpot) {
        self.spot = spot
        _name = State(initialValue: spot.name)
        _descriptionText = State(initialValue: spot.description ?? "")
        _tagsString = State(initialValue: spot.tags.joined(separator: ", "))
        _location = State(initialValue: spot.location)
    }

    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("スポット名", text: $name)
                TextField("説明", text: $descriptionText, axis: .vertical)
            }

            Section(header: Text("タグ（カンマ区切り）")) {
                TextField("例: パーク, ストリート", text: $tagsString)
            }

            Section(header: Text("位置情報")) {
                SdzLocationPickerView(selectedLocation: $location, height: 360)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                if location == nil {
                    Text("地図をタップして位置を選択")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Button("現在地を設定") {
                        locationManager.requestCurrentLocation()
                    }
                    Spacer()
                    Button("地図を拡大して選択") {
                        showLocationPickerSheet = true
                    }
                }
                if locationManager.authorizationStatus == .denied {
                    Text("位置情報の許可が必要です。")
                        .foregroundColor(.red)
                }
                if let errorMessage = locationManager.lastErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section {
                if let saveMessage = saveMessage {
                    Text(saveMessage)
                        .foregroundColor(.secondary)
                }
                Button(isSaving ? "保存中..." : "保存する") {
                    save()
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("投稿を編集")
        .sheet(isPresented: $showLocationPickerSheet) {
            SdzLocationPickerSheetView(selectedLocation: $location)
        }
        .onReceive(locationManager.$currentCoordinate) { coordinate in
            guard let coordinate = coordinate else {
                return
            }
            location = SdzSpotLocation(
                lat: coordinate.latitude,
                lng: coordinate.longitude
            )
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            saveMessage = "スポット名を入力してください。"
            return
        }
        guard appState.idToken != nil else {
            saveMessage = "ログインが必要です。"
            return
        }

        let tags = tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        isSaving = true
        saveMessage = nil

        Task {
            do {
                let input = SdzUpdateSpotInput(
                    name: trimmedName,
                    description: descriptionText.isEmpty ? nil : descriptionText,
                    location: location,
                    tags: tags.isEmpty ? [] : tags,
                    images: spot.images,
                    approvalStatus: nil
                )
                _ = try await apiClient.updateSpot(id: spot.spotId, input: input)
                await MainActor.run {
                    self.isSaving = false
                    self.saveMessage = "更新しました。"
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.isSaving = false
                    self.saveMessage = message
                }
            }
        }
    }
}

#if DEBUG
struct EditSpotView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditSpotView(spot: SdzSpot.sample(id: "sample", name: "編集サンプル"))
                .environmentObject(SdzAppState())
        }
    }
}
#endif
