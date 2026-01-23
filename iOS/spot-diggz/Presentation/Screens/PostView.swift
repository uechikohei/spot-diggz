import SwiftUI
import MapKit
import UIKit

/// A screen for creating a new skate spot.
struct PostView: View {
    @EnvironmentObject var appState: SdzAppState
    @StateObject private var locationManager = SdzLocationManager()
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var tagsString: String = ""
    @State private var spotCategory: SdzSpotCategory = .street
    @State private var parkOfficialUrl: String = ""
    @State private var parkBusinessHours: String = ""
    @State private var parkBusinessDays: String = ""
    @State private var parkAccessInfo: String = ""
    @State private var parkPhoneNumber: String = ""
    @State private var streetSurface: String = ""
    @State private var streetObstacles: String = ""
    @State private var streetDifficulty: String = ""
    @State private var selectedLocation: SdzSpotLocation?
    @State private var images: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var showLocationPickerSheet: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var submitMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("スポット種別")) {
                    Picker("種類", selection: $spotCategory) {
                        ForEach(SdzSpotCategory.allCases) { category in
                            Text(category.label).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("基本情報")) {
                    TextField("スポット名", text: $name)
                    TextField("説明", text: $description, axis: .vertical)
                }

                Section(header: Text("タグ（カンマ区切り）")) {
                    TextField("例: パーク, ストリート", text: $tagsString)
                }

                Section(header: Text("位置情報")) {
                    SdzLocationPickerView(selectedLocation: $selectedLocation, height: 360)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    VStack(alignment: .leading, spacing: 6) {
                        Label("地図をタップしてピンを置く", systemImage: "hand.tap")
                        Label("現在地ボタンで自動入力", systemImage: "location.fill")
                        Label("細かく選ぶ場合は拡大を使う", systemImage: "plus.magnifyingglass")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    if selectedLocation == nil {
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

                Section(header: Text("画像")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(images.indices, id: \.self) { index in
                                Image(uiImage: images[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            Button(action: {
                                showImagePicker = true
                            }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title)
                                    Text("追加")
                                        .font(.caption)
                                }
                                .frame(width: 80, height: 80)
                                .foregroundColor(.accentColor)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                if spotCategory == .park {
                    Section(header: Text("スケートパーク情報")) {
                        TextField("公式サイトURL", text: $parkOfficialUrl)
                        TextField("営業時間", text: $parkBusinessHours)
                        TextField("営業日", text: $parkBusinessDays)
                        TextField("アクセス情報", text: $parkAccessInfo)
                        TextField("電話番号", text: $parkPhoneNumber)
                    }
                } else {
                    Section(header: Text("ストリート情報")) {
                        TextField("路面・素材", text: $streetSurface)
                        TextField("障害物・セクション", text: $streetObstacles)
                        TextField("難易度", text: $streetDifficulty)
                    }
                }

                Section {
                    if let submitMessage = submitMessage {
                        Text(submitMessage)
                            .foregroundColor(.secondary)
                    }
                    Button(isSubmitting ? "送信中..." : "投稿する") {
                        submit()
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("新しいスポットを投稿")
            .onAppear {
                applyDraftLocationIfNeeded()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $images)
            }
            .sheet(isPresented: $showLocationPickerSheet) {
                SdzLocationPickerSheetView(selectedLocation: $selectedLocation)
            }
            .onReceive(locationManager.$currentCoordinate) { coordinate in
                guard let coordinate = coordinate else {
                    return
                }
                selectedLocation = SdzSpotLocation(
                    lat: coordinate.latitude,
                    lng: coordinate.longitude
                )
            }
        }
    }

    private func submit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            submitMessage = "スポット名を入力してください。"
            return
        }
        guard appState.idToken != nil else {
            submitMessage = "ログインが必要です。"
            return
        }

        let tags = buildTags()
        let combinedDescription = buildDescription()

        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        isSubmitting = true
        submitMessage = nil

        Task {
            do {
                let uploadedUrls = try await uploadImagesIfNeeded(apiClient: apiClient)
                let input = SdzCreateSpotInput(
                    name: trimmedName,
                    description: combinedDescription,
                    location: selectedLocation,
                    tags: tags?.isEmpty == true ? nil : tags,
                    images: uploadedUrls.isEmpty ? nil : uploadedUrls
                )
                _ = try await apiClient.createSpot(input)
                await MainActor.run {
                    self.isSubmitting = false
                    self.submitMessage = "投稿が完了しました。"
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.isSubmitting = false
                    self.submitMessage = message
                }
            }
        }
    }

    private func buildTags() -> [String]? {
        var tags = tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let categoryTag = spotCategory.defaultTag
        if !tags.contains(categoryTag) {
            tags.append(categoryTag)
        }

        return tags.isEmpty ? nil : tags
    }

    private func buildDescription() -> String? {
        var lines: [String] = []
        let base = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.isEmpty {
            lines.append(base)
        }

        switch spotCategory {
        case .park:
            appendDetail("公式サイト", parkOfficialUrl, to: &lines)
            appendDetail("営業時間", parkBusinessHours, to: &lines)
            appendDetail("営業日", parkBusinessDays, to: &lines)
            appendDetail("アクセス", parkAccessInfo, to: &lines)
            appendDetail("電話番号", parkPhoneNumber, to: &lines)
        case .street:
            appendDetail("路面", streetSurface, to: &lines)
            appendDetail("障害物", streetObstacles, to: &lines)
            appendDetail("難易度", streetDifficulty, to: &lines)
        }

        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private func appendDetail(_ label: String, _ value: String, to lines: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        lines.append("\(label): \(trimmed)")
    }

    private func applyDraftLocationIfNeeded() {
        guard let draft = appState.draftPostLocation else {
            return
        }
        selectedLocation = draft
        appState.draftPostLocation = nil
    }

    private func uploadImagesIfNeeded(apiClient: SdzApiClient) async throws -> [String] {
        guard !images.isEmpty else {
            return []
        }

        var uploadedUrls: [String] = []
        for image in images {
            if let jpegData = image.jpegData(compressionQuality: 0.85) {
                let upload = try await apiClient.requestUploadUrl(contentType: "image/jpeg")
                try await apiClient.uploadImage(
                    data: jpegData,
                    contentType: "image/jpeg",
                    uploadUrl: upload.uploadUrl
                )
                uploadedUrls.append(upload.objectUrl)
            } else if let pngData = image.pngData() {
                let upload = try await apiClient.requestUploadUrl(contentType: "image/png")
                try await apiClient.uploadImage(
                    data: pngData,
                    contentType: "image/png",
                    uploadUrl: upload.uploadUrl
                )
                uploadedUrls.append(upload.objectUrl)
            } else {
                throw SdzPostError.imageEncodingFailed
            }
        }
        return uploadedUrls
    }
}

private enum SdzPostError: LocalizedError {
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "画像の変換に失敗しました。"
        }
    }
}

private enum SdzSpotCategory: String, CaseIterable, Identifiable {
    case street
    case park

    var id: String { rawValue }

    var label: String {
        switch self {
        case .street:
            return "ストリート"
        case .park:
            return "スケートパーク"
        }
    }

    var defaultTag: String {
        switch self {
        case .street:
            return "ストリート"
        case .park:
            return "パーク"
        }
    }
}

// A simple image picker for selecting photos from the photo library.
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var images: [UIImage]

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#if DEBUG
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
            .environmentObject(SdzAppState())
    }
}
#endif
