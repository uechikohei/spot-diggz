import SwiftUI
import MapKit
import UIKit

/// A screen displaying detailed information about a specific spot.
struct SpotDetailView: View {
    @EnvironmentObject var appState: SdzAppState
    @State private var spot: SdzSpot

    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var approvalMessage: String?
    @State private var routeMessage: String?
    @State private var isRequestingApproval: Bool = false
    @State private var showRouteBuilder: Bool = false
    @State private var showNavigationDialog: Bool = false
    @State private var showImageViewer: Bool = false
    @State private var selectedImageIndex: Int = 0

    init(spot: SdzSpot) {
        _spot = State(initialValue: spot)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if spot.images.isEmpty {
                    placeholderImage
                } else {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(spot.images.indices, id: \.self) { index in
                            let urlString = spot.images[index]
                            Group {
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            placeholderImage
                                        @unknown default:
                                            placeholderImage
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedImageIndex = index
                                        showImageViewer = true
                                    }
                                } else {
                                    placeholderImage
                                }
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 220)
                    .tabViewStyle(.page)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(spot.name)
                        .font(.title)
                        .bold()
                    HStack {
                        Text("公開ステータス: \(approvalStatusText)")
                            .font(.subheadline)
                            .foregroundColor(approvalStatusColor)
                        Spacer()
                    }
                    if !spot.tags.isEmpty {
                        Text(spot.tags.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let description = spot.description {
                        Text(description)
                            .padding(.top, 8)
                    }
                    if let parkAttributes = spot.parkAttributes {
                        parkDetailSection(parkAttributes)
                    }
                    if let streetAttributes = spot.streetAttributes {
                        let title = spot.parkAttributes == nil ? "ストリート情報" : "路面・セクション"
                        streetDetailSection(streetAttributes, title: title)
                    }
                    if let instagramTag = normalizedInstagramTag {
                        instagramSection(instagramTag)
                    }
                    // Map preview
                    if let location = spot.location {
                        let coord = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                        if #available(iOS 17.0, *) {
                            Map(initialPosition: .region(MKCoordinateRegion(center: coord,
                                                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                                Marker(spot.name, coordinate: coord)
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                        } else {
                            Map(coordinateRegion: $region, annotationItems: [location]) { loc in
                                MapMarker(coordinate: CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.lng))
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                            .onAppear {
                                region = MKCoordinateRegion(
                                    center: coord,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }
                    }
                    // Actions
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                Task {
                                    await appState.toggleFavorite(spot)
                                }
                            }) {
                                Label(
                                    isFavorite ? "お気に入り解除" : "お気に入りに追加",
                                    systemImage: isFavorite ? "heart.fill" : "heart"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            Button(action: {
                                toggleRouteDraft()
                            }) {
                                Label(
                                    isInRouteDraft ? "ルートから外す" : "ルートに追加",
                                    systemImage: isInRouteDraft ? "bookmark.fill" : "bookmark"
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        HStack {
                            Button(action: {
                                showNavigationDialog = true
                            }) {
                                Label("ナビ", systemImage: "car")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(spot.location == nil)
                        }
                        if isInRouteDraft {
                            Button("ルート作成へ") {
                                showRouteBuilder = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                    if let routeMessage = routeMessage {
                        Text(routeMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isOwnedByCurrentUser {
                        if let approvalMessage = approvalMessage {
                            Text(approvalMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if canRequestApproval {
                            Button(isRequestingApproval ? "申請中..." : "承認を申請") {
                                requestApproval()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRequestingApproval)
                        }
                        NavigationLink("投稿を編集") {
                            EditSpotView(spot: spot) { updated in
                                self.spot = updated
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("スポット詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteBuilder) {
            RouteBuilderView()
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            SdzImageGalleryView(
                imageUrls: spot.images,
                initialIndex: selectedImageIndex
            )
        }
        .confirmationDialog("ナビを開く", isPresented: $showNavigationDialog, titleVisibility: .visible) {
            Button("Google Mapsで開く") {
                openGoogleMaps()
            }
            Button("Apple Mapsで開く") {
                openAppleMaps()
            }
        }
        .onAppear {
            refreshSpotDetail()
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 200)
            .overlay(
                Text("画像")
                    .foregroundColor(.white)
            )
    }

    private var isFavorite: Bool {
        appState.isFavorite(spot)
    }

    private var isInRouteDraft: Bool {
        appState.routeDraftSpots.contains(where: { $0.spotId == spot.spotId })
    }

    private var isOwnedByCurrentUser: Bool {
        guard let currentUserId = appState.authUserId else {
            return false
        }
        return spot.userId == currentUserId
    }

    private var approvalStatusText: String {
        switch spot.approvalStatus {
        case .approved:
            return "承認済"
        case .pending:
            return "審査中"
        case .rejected:
            return "差戻し"
        case .none:
            return "未申請"
        }
    }

    private var approvalStatusColor: Color {
        switch spot.approvalStatus {
        case .approved:
            return .green
        case .pending:
            return .orange
        case .rejected:
            return .red
        case .none:
            return .secondary
        }
    }

    private var canRequestApproval: Bool {
        guard isOwnedByCurrentUser else {
            return false
        }
        switch spot.approvalStatus {
        case .none, .rejected:
            return true
        default:
            return false
        }
    }

    private var normalizedInstagramTag: String? {
        guard let tag = spot.instagramTag?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tag.isEmpty else {
            return nil
        }
        return tag.hasPrefix("#") ? String(tag.dropFirst()) : tag
    }

    @ViewBuilder
    private func parkDetailSection(_ attributes: SdzSpotParkAttributes) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("スケートパーク情報")
                .font(.headline)
            if let hours = attributes.businessHours {
                VStack(alignment: .leading, spacing: 4) {
                    Text("営業時間")
                        .font(.subheadline)
                    ForEach(businessHoursLines(hours), id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            if let accessInfo = attributes.accessInfo, !accessInfo.isEmpty {
                Text("アクセス: \(accessInfo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let phone = attributes.phoneNumber, !phone.isEmpty {
                if let url = URL(string: "tel://\(phone)") {
                    Link("電話: \(phone)", destination: url)
                        .font(.caption)
                } else {
                    Text("電話: \(phone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let officialUrl = attributes.officialUrl,
               let url = URL(string: officialUrl) {
                Link("公式サイトを開く", destination: url)
                    .font(.caption)
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func streetDetailSection(_ attributes: SdzStreetAttributes, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            if let material = attributes.surfaceMaterial, !material.isEmpty {
                Text("路面: \(material)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let condition = attributes.surfaceCondition {
                if let roughness = condition.roughness, !roughness.isEmpty {
                    Text("粗さ: \(roughness)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let crack = condition.crack, !crack.isEmpty {
                    Text("ひび割れ: \(crack)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let difficulty = attributes.difficulty, !difficulty.isEmpty {
                Text("難易度: \(difficulty)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let sections = attributes.sections, !sections.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("セクション")
                        .font(.subheadline)
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.type)
                                .font(.caption)
                                .bold()
                            Text(sectionSummary(section))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
    }

    private func instagramSection(_ tag: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instagram")
                .font(.headline)
            Button(action: {
                openInstagramTag(tag)
            }) {
                Label("#\(tag) の投稿を見る", systemImage: "camera")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 12)
    }

    private func businessHoursLines(_ hours: SdzSpotBusinessHours) -> [String] {
        let scheduleType = hours.scheduleType ?? .regular
        var lines: [String] = []

        switch scheduleType {
        case .regular:
            if hours.is24Hours {
                lines.append("24時間営業")
            } else {
                if let weekday = hours.weekday {
                    lines.append("平日 \(formatTimeRange(weekday))")
                }
                if hours.sameAsWeekday {
                    lines.append("週末: 平日と同じ")
                } else if let weekend = hours.weekend {
                    lines.append("週末 \(formatTimeRange(weekend))")
                }
            }
        case .weekdayOnly:
            if hours.is24Hours {
                lines.append("平日のみ 24時間営業")
            } else if let weekday = hours.weekday {
                lines.append("平日のみ \(formatTimeRange(weekday))")
            }
        case .weekendOnly:
            if hours.is24Hours {
                lines.append("週末のみ 24時間営業")
            } else if let weekend = hours.weekend {
                lines.append("週末のみ \(formatTimeRange(weekend))")
            }
        case .irregular:
            lines.append("不定休")
        case .schoolOnly:
            lines.append("スクールのみ")
        }

        if let note = hours.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("備考: \(note)")
        }

        return lines
    }

    private func formatTimeRange(_ range: SdzSpotTimeRange) -> String {
        "\(formatMinutes(range.startMinutes)) - \(formatMinutes(range.endMinutes))"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func sectionSummary(_ section: SdzStreetSection) -> String {
        var parts: [String] = []
        if let count = section.count {
            parts.append("\(count)基")
        }
        if let height = section.heightCm {
            parts.append("高さ\(height)cm")
        }
        if let width = section.widthCm {
            parts.append("幅\(width)cm")
        }
        if let notes = section.notes, !notes.isEmpty {
            parts.append(notes)
        }
        return parts.isEmpty ? "詳細なし" : parts.joined(separator: " / ")
    }

    private func requestApproval() {
        guard appState.idToken != nil else {
            approvalMessage = "ログインが必要です。"
            return
        }
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        isRequestingApproval = true
        approvalMessage = nil
        Task {
            do {
                let input = SdzUpdateSpotInput(
                    name: spot.name,
                    description: nil,
                    location: nil,
                    tags: nil,
                    images: nil,
                    approvalStatus: .pending,
                    parkAttributes: nil,
                    streetAttributes: nil,
                    instagramTag: nil
                )
                let updated = try await apiClient.updateSpot(id: spot.spotId, input: input)
                await MainActor.run {
                    self.spot = updated
                    self.isRequestingApproval = false
                    self.approvalMessage = "承認申請を送信しました。"
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.isRequestingApproval = false
                    self.approvalMessage = message
                }
            }
        }
    }

    private func toggleRouteDraft() {
        if isInRouteDraft {
            appState.removeSpotFromRouteDraft(spot)
            routeMessage = "ルート下書きから外しました。"
        } else {
            appState.addSpotToRouteDraft(spot)
            routeMessage = "ルート下書きに追加しました。"
        }
    }

    private var spotCoordinate: CLLocationCoordinate2D? {
        guard let location = spot.location else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
    }

    private func openGoogleMaps() {
        guard let coordinate = spotCoordinate else {
            return
        }
        SdzMapNavigator.openGoogleMaps(destination: coordinate, mode: .drive)
    }

    private func openAppleMaps() {
        guard let coordinate = spotCoordinate else {
            return
        }
        SdzMapNavigator.openAppleMaps(destination: coordinate, mode: .drive)
    }

    private func openInstagramTag(_ tag: String) {
        let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        if let url = URL(string: "https://www.instagram.com/explore/tags/\(encodedTag)/") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func refreshSpotDetail() {
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        Task {
            do {
                let updated = try await apiClient.fetchSpotDetail(
                    id: spot.spotId,
                    includeAuth: true
                )
                await MainActor.run {
                    spot = updated
                    if spot.images.isEmpty {
                        selectedImageIndex = 0
                    } else {
                        selectedImageIndex = min(selectedImageIndex, spot.images.count - 1)
                    }
                }
            } catch {
                // Keep showing existing details on refresh failure.
            }
        }
    }
}

private struct SdzImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    let imageUrls: [String]
    @State private var selection: Int

    init(imageUrls: [String], initialIndex: Int) {
        self.imageUrls = imageUrls
        _selection = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $selection) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, urlString in
                    ZStack {
                        if let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Color.gray.opacity(0.2)
                                @unknown default:
                                    Color.gray.opacity(0.2)
                                }
                            }
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

#if DEBUG
struct SpotDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpotDetailView(spot: SdzSpot.sample(id: "preview", name: "プレビュー"))
                .environmentObject(SdzAppState())
        }
    }
}
#endif
