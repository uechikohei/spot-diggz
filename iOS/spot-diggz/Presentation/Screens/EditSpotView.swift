import SwiftUI
import CoreLocation
import UIKit

/// Editing screen for a spot posted by the current user.
struct EditSpotView: View {
    @EnvironmentObject var appState: SdzAppState
    let spot: SdzSpot
    let onUpdated: ((SdzSpot) -> Void)?

    @StateObject private var locationManager = SdzLocationManager()
    @State private var name: String
    @State private var descriptionText: String
    @State private var tagsString: String
    @State private var spotCategory: SdzSpotCategory
    @State private var parkOfficialUrl: String
    @State private var parkAccessInfo: String
    @State private var parkPhoneNumber: String
    @State private var parkScheduleType: SdzSpotBusinessScheduleType
    @State private var parkScheduleNote: String
    @State private var parkIs24Hours: Bool
    @State private var parkSameAsWeekday: Bool
    @State private var parkWeekdayStart: Date
    @State private var parkWeekdayEnd: Date
    @State private var parkWeekendStart: Date
    @State private var parkWeekendEnd: Date
    @State private var streetSurfaceMaterial: String
    @State private var streetSurfaceRoughness: String
    @State private var streetSurfaceCrack: String
    @State private var streetDifficulty: String
    @State private var streetSections: [SdzStreetSectionInput]
    @State private var instagramTag: String
    @State private var location: SdzSpotLocation?
    @State private var imageItems: [SdzSpotImageItem]
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    @State private var showLocationPickerSheet: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showUrlPickerSheet: Bool = false
    private let maxImagesPerSpot: Int = 3

    init(spot: SdzSpot, onUpdated: ((SdzSpot) -> Void)? = nil) {
        self.spot = spot
        self.onUpdated = onUpdated
        let category: SdzSpotCategory =
            spot.tags.contains(SdzSpotCategory.park.defaultTag) || spot.parkAttributes != nil
                ? .park
                : .street
        let parkAttributes = spot.parkAttributes
        let businessHours = parkAttributes?.businessHours
        let streetAttributes = spot.streetAttributes
        let sectionInputs: [SdzStreetSectionInput] = (streetAttributes?.sections ?? []).map {
            SdzStreetSectionInput(
                type: $0.type,
                count: $0.count.map(String.init) ?? "",
                heightCm: $0.heightCm.map(String.init) ?? "",
                widthCm: $0.widthCm.map(String.init) ?? "",
                notes: $0.notes ?? ""
            )
        }

        _name = State(initialValue: spot.name)
        _descriptionText = State(initialValue: spot.description ?? "")
        _tagsString = State(initialValue: spot.tags.joined(separator: ", "))
        _spotCategory = State(initialValue: category)
        _parkOfficialUrl = State(initialValue: parkAttributes?.officialUrl ?? "")
        _parkAccessInfo = State(initialValue: parkAttributes?.accessInfo ?? "")
        _parkPhoneNumber = State(initialValue: parkAttributes?.phoneNumber ?? "")
        _parkScheduleType = State(initialValue: businessHours?.scheduleType ?? .regular)
        _parkScheduleNote = State(initialValue: businessHours?.note ?? "")
        _parkIs24Hours = State(initialValue: businessHours?.is24Hours ?? false)
        _parkSameAsWeekday = State(initialValue: businessHours?.sameAsWeekday ?? true)
        _parkWeekdayStart = State(
            initialValue: SdzTimeDefaults.time(
                from: businessHours?.weekday?.startMinutes,
                fallback: SdzTimeDefaults.weekdayStart
            )
        )
        _parkWeekdayEnd = State(
            initialValue: SdzTimeDefaults.time(
                from: businessHours?.weekday?.endMinutes,
                fallback: SdzTimeDefaults.weekdayEnd
            )
        )
        _parkWeekendStart = State(
            initialValue: SdzTimeDefaults.time(
                from: businessHours?.weekend?.startMinutes,
                fallback: SdzTimeDefaults.weekendStart
            )
        )
        _parkWeekendEnd = State(
            initialValue: SdzTimeDefaults.time(
                from: businessHours?.weekend?.endMinutes,
                fallback: SdzTimeDefaults.weekendEnd
            )
        )
        _streetSurfaceMaterial = State(initialValue: streetAttributes?.surfaceMaterial ?? "")
        _streetSurfaceRoughness = State(initialValue: streetAttributes?.surfaceCondition?.roughness ?? "")
        _streetSurfaceCrack = State(initialValue: streetAttributes?.surfaceCondition?.crack ?? "")
        _streetDifficulty = State(initialValue: streetAttributes?.difficulty ?? "")
        _streetSections = State(initialValue: sectionInputs)
        _instagramTag = State(initialValue: spot.instagramTag ?? "")
        _location = State(initialValue: spot.location)
        _imageItems = State(initialValue: spot.images.map { SdzSpotImageItem(remoteUrl: $0) })
    }

    var body: some View {
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

            Section(header: imageSectionHeader) {
                SdzSpotImageRow(items: $imageItems, maxImages: maxImagesPerSpot) {
                    showImagePicker = true
                }
                Text("左端がメイン画像です。ドラッグで並び替えできます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if spotCategory == .park {
                Section(header: Text("スケートパーク情報")) {
                    HStack {
                        TextField("公式サイトURL", text: $parkOfficialUrl)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        Button {
                            showUrlPickerSheet = true
                        } label: {
                            Image(systemName: "safari")
                        }
                        .buttonStyle(.bordered)
                    }
                    Picker("営業時間タイプ", selection: $parkScheduleType) {
                        ForEach(SdzSpotBusinessScheduleType.allCases) { scheduleType in
                            Text(scheduleType.label).tag(scheduleType)
                        }
                    }
                    .pickerStyle(.menu)

                    if parkScheduleType == .irregular || parkScheduleType == .schoolOnly {
                        TextField("営業時間の補足 (例: 不定休/スクール専用)", text: $parkScheduleNote)
                        Text("詳細は公式サイトや現地案内をご確認ください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Toggle("24時間営業", isOn: $parkIs24Hours)
                        if !parkIs24Hours {
                            switch parkScheduleType {
                            case .regular:
                                DatePicker(
                                    "平日 開始",
                                    selection: $parkWeekdayStart,
                                    displayedComponents: .hourAndMinute
                                )
                                DatePicker(
                                    "平日 終了",
                                    selection: $parkWeekdayEnd,
                                    displayedComponents: .hourAndMinute
                                )
                                Toggle("週末も同じ", isOn: $parkSameAsWeekday)
                                if !parkSameAsWeekday {
                                    DatePicker(
                                        "週末 開始",
                                        selection: $parkWeekendStart,
                                        displayedComponents: .hourAndMinute
                                    )
                                    DatePicker(
                                        "週末 終了",
                                        selection: $parkWeekendEnd,
                                        displayedComponents: .hourAndMinute
                                    )
                                }
                            case .weekdayOnly:
                                DatePicker(
                                    "平日 開始",
                                    selection: $parkWeekdayStart,
                                    displayedComponents: .hourAndMinute
                                )
                                DatePicker(
                                    "平日 終了",
                                    selection: $parkWeekdayEnd,
                                    displayedComponents: .hourAndMinute
                                )
                            case .weekendOnly:
                                DatePicker(
                                    "週末 開始",
                                    selection: $parkWeekendStart,
                                    displayedComponents: .hourAndMinute
                                )
                                DatePicker(
                                    "週末 終了",
                                    selection: $parkWeekendEnd,
                                    displayedComponents: .hourAndMinute
                                )
                            case .irregular, .schoolOnly:
                                EmptyView()
                            }
                        }
                    }
                    TextField("アクセス情報", text: $parkAccessInfo)
                    TextField("電話番号", text: $parkPhoneNumber)
                }
            }

            Section(header: Text(spotCategory == .park ? "路面・セクション（任意）" : "ストリート情報")) {
                TextField("路面の材質", text: $streetSurfaceMaterial)
                HStack {
                    TextField("粗さ", text: $streetSurfaceRoughness)
                    TextField("ひび割れ", text: $streetSurfaceCrack)
                }
                TextField("難易度", text: $streetDifficulty)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("セクション")
                            .font(.subheadline)
                        Spacer()
                        Button("追加") {
                            streetSections.append(SdzStreetSectionInput())
                        }
                    }
                    ForEach($streetSections) { $section in
                        SdzStreetSectionEditor(section: $section) {
                            streetSections.removeAll { $0.id == section.id }
                        }
                    }
                }
            }

            Section(header: Text("Instagram")) {
                TextField("ハッシュタグ (例: osaka-skate)", text: $instagramTag)
                    .textInputAutocapitalization(.never)
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
        .sheet(isPresented: $showImagePicker) {
            SdzImagePicker(maxSelection: remainingImageSlots) { newImages in
                let newItems = newImages.map { SdzSpotImageItem(localImage: $0) }
                imageItems.append(contentsOf: newItems)
            }
        }
        .sheet(isPresented: $showUrlPickerSheet) {
            SdzUrlPickerSheetView(initialUrl: parkOfficialUrl) { selectedUrl in
                parkOfficialUrl = selectedUrl
            }
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
        if imageItems.count > maxImagesPerSpot {
            saveMessage = "画像は最大\(maxImagesPerSpot)枚までです。"
            return
        }
        if spotCategory == .park, let hoursError = validateBusinessHours() {
            saveMessage = hoursError
            return
        }

        let tags = buildTags()
        let combinedDescription = buildDescription()
        let parkAttributes = spotCategory == .park ? buildParkAttributes() : nil
        let streetAttributes = buildStreetAttributes()
        let instagramTag = normalizedInstagramTag()

        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        isSaving = true
        saveMessage = nil

        Task {
            do {
                let uploadedUrls = try await uploadNewImagesIfNeeded(apiClient: apiClient)
                let combinedImages: [String] = imageItems.compactMap { item in
                    switch item.source {
                    case .remote(let url):
                        return url
                    case .local:
                        return uploadedUrls[item.id]
                    }
                }
                let input = SdzUpdateSpotInput(
                    name: trimmedName,
                    description: combinedDescription,
                    location: location,
                    tags: tags.isEmpty ? nil : tags,
                    images: combinedImages,
                    approvalStatus: nil,
                    parkAttributes: parkAttributes,
                    streetAttributes: streetAttributes,
                    instagramTag: instagramTag
                )
                let updated = try await apiClient.updateSpot(id: spot.spotId, input: input)
                await MainActor.run {
                    self.isSaving = false
                    self.saveMessage = "更新しました。"
                    self.onUpdated?(updated)
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

    private var imageSectionHeader: some View {
        HStack {
            Text("画像")
            Spacer()
            Text("\(imageItems.count)/\(maxImagesPerSpot)")
                .font(.caption)
                .foregroundColor(imageItems.count >= maxImagesPerSpot ? .red : .secondary)
        }
    }

    private var remainingImageSlots: Int {
        max(0, maxImagesPerSpot - imageItems.count)
    }

    private func buildTags() -> [String] {
        var tags = tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let categoryTag = spotCategory.defaultTag
        let otherCategoryTag = (spotCategory == .park)
            ? SdzSpotCategory.street.defaultTag
            : SdzSpotCategory.park.defaultTag

        tags.removeAll { $0 == otherCategoryTag }
        if !tags.contains(categoryTag) {
            tags.append(categoryTag)
        }

        if tags.count > 10 {
            tags = Array(tags.prefix(10))
        }
        return tags
    }

    private func buildDescription() -> String? {
        let base = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return base.isEmpty ? nil : base
    }

    private func normalizedInstagramTag() -> String? {
        let trimmed = instagramTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        if trimmed.hasPrefix("#") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }

    private func buildParkAttributes() -> SdzSpotParkAttributes? {
        let officialUrl = parkOfficialUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let accessInfo = parkAccessInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneNumber = parkPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let businessHours = buildBusinessHours()

        let cleanedUrl = officialUrl.isEmpty ? nil : officialUrl
        let cleanedAccess = accessInfo.isEmpty ? nil : accessInfo
        let cleanedPhone = phoneNumber.isEmpty ? nil : phoneNumber

        if cleanedUrl == nil && cleanedAccess == nil && cleanedPhone == nil && businessHours == nil {
            return nil
        }

        return SdzSpotParkAttributes(
            officialUrl: cleanedUrl,
            businessHours: businessHours,
            accessInfo: cleanedAccess,
            phoneNumber: cleanedPhone
        )
    }

    private func buildBusinessHours() -> SdzSpotBusinessHours? {
        let cleanedNote = parkScheduleNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = cleanedNote.isEmpty ? nil : cleanedNote

        switch parkScheduleType {
        case .irregular, .schoolOnly:
            return SdzSpotBusinessHours(
                scheduleType: parkScheduleType,
                is24Hours: false,
                sameAsWeekday: true,
                weekday: nil,
                weekend: nil,
                note: noteValue
            )
        case .weekdayOnly:
            let weekdayRange = parkIs24Hours
                ? nil
                : SdzSpotTimeRange(
                    startMinutes: minutes(from: parkWeekdayStart),
                    endMinutes: minutes(from: parkWeekdayEnd)
                )
            return SdzSpotBusinessHours(
                scheduleType: parkScheduleType,
                is24Hours: parkIs24Hours,
                sameAsWeekday: true,
                weekday: weekdayRange,
                weekend: nil,
                note: noteValue
            )
        case .weekendOnly:
            let weekendRange = parkIs24Hours
                ? nil
                : SdzSpotTimeRange(
                    startMinutes: minutes(from: parkWeekendStart),
                    endMinutes: minutes(from: parkWeekendEnd)
                )
            return SdzSpotBusinessHours(
                scheduleType: parkScheduleType,
                is24Hours: parkIs24Hours,
                sameAsWeekday: true,
                weekday: nil,
                weekend: weekendRange,
                note: noteValue
            )
        case .regular:
            if parkIs24Hours {
                return SdzSpotBusinessHours(
                    scheduleType: parkScheduleType,
                    is24Hours: true,
                    sameAsWeekday: true,
                    weekday: nil,
                    weekend: nil,
                    note: noteValue
                )
            }

            let weekdayRange = SdzSpotTimeRange(
                startMinutes: minutes(from: parkWeekdayStart),
                endMinutes: minutes(from: parkWeekdayEnd)
            )
            let weekendRange: SdzSpotTimeRange? = parkSameAsWeekday
                ? nil
                : SdzSpotTimeRange(
                    startMinutes: minutes(from: parkWeekendStart),
                    endMinutes: minutes(from: parkWeekendEnd)
                )

            return SdzSpotBusinessHours(
                scheduleType: parkScheduleType,
                is24Hours: false,
                sameAsWeekday: parkSameAsWeekday,
                weekday: weekdayRange,
                weekend: weekendRange,
                note: noteValue
            )
        }
    }

    private func buildStreetAttributes() -> SdzStreetAttributes? {
        let material = streetSurfaceMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
        let roughness = streetSurfaceRoughness.trimmingCharacters(in: .whitespacesAndNewlines)
        let crack = streetSurfaceCrack.trimmingCharacters(in: .whitespacesAndNewlines)
        let difficulty = streetDifficulty.trimmingCharacters(in: .whitespacesAndNewlines)

        let surfaceMaterial = material.isEmpty ? nil : material
        let surfaceCondition: SdzStreetSurfaceCondition? = (roughness.isEmpty && crack.isEmpty)
            ? nil
            : SdzStreetSurfaceCondition(
                roughness: roughness.isEmpty ? nil : roughness,
                crack: crack.isEmpty ? nil : crack
            )
        let sections = buildStreetSections()
        let cleanedDifficulty = difficulty.isEmpty ? nil : difficulty

        if surfaceMaterial == nil && surfaceCondition == nil && sections == nil && cleanedDifficulty == nil {
            return nil
        }

        return SdzStreetAttributes(
            surfaceMaterial: surfaceMaterial,
            surfaceCondition: surfaceCondition,
            sections: sections,
            difficulty: cleanedDifficulty
        )
    }

    private func buildStreetSections() -> [SdzStreetSection]? {
        let sections: [SdzStreetSection] = streetSections.compactMap { input in
            let type = input.type.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !type.isEmpty else {
                return nil
            }
            return SdzStreetSection(
                type: type,
                count: parseInt(input.count),
                heightCm: parseInt(input.heightCm),
                widthCm: parseInt(input.widthCm),
                notes: input.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : input.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return sections.isEmpty ? nil : sections
    }

    private func validateBusinessHours() -> String? {
        switch parkScheduleType {
        case .irregular, .schoolOnly:
            let cleanedNote = parkScheduleNote.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedNote.isEmpty {
                return "営業時間の補足を入力してください。"
            }
            return nil
        case .weekdayOnly:
            guard !parkIs24Hours else {
                return nil
            }
            let weekdayStart = minutes(from: parkWeekdayStart)
            let weekdayEnd = minutes(from: parkWeekdayEnd)
            if weekdayStart >= weekdayEnd {
                return "平日の営業時間が正しくありません。"
            }
            return nil
        case .weekendOnly:
            guard !parkIs24Hours else {
                return nil
            }
            let weekendStart = minutes(from: parkWeekendStart)
            let weekendEnd = minutes(from: parkWeekendEnd)
            if weekendStart >= weekendEnd {
                return "週末の営業時間が正しくありません。"
            }
            return nil
        case .regular:
            guard !parkIs24Hours else {
                return nil
            }
            let weekdayStart = minutes(from: parkWeekdayStart)
            let weekdayEnd = minutes(from: parkWeekdayEnd)
            if weekdayStart >= weekdayEnd {
                return "平日の営業時間が正しくありません。"
            }
            if !parkSameAsWeekday {
                let weekendStart = minutes(from: parkWeekendStart)
                let weekendEnd = minutes(from: parkWeekendEnd)
                if weekendStart >= weekendEnd {
                    return "週末の営業時間が正しくありません。"
                }
            }
            return nil
        }
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func parseInt(_ value: String) -> Int? {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func uploadNewImagesIfNeeded(apiClient: SdzApiClient) async throws -> [UUID: String] {
        var uploadedUrls: [UUID: String] = [:]
        for item in imageItems {
            guard let image = item.localImage else {
                continue
            }
            guard let payload = SdzImageOptimizer.optimize(image) else {
                throw SdzEditError.imageEncodingFailed
            }
            let upload = try await apiClient.requestUploadUrl(contentType: payload.contentType)
            try await apiClient.uploadImage(
                data: payload.data,
                contentType: payload.contentType,
                uploadUrl: upload.uploadUrl
            )
            uploadedUrls[item.id] = upload.objectUrl
        }
        return uploadedUrls
    }
}

private enum SdzEditError: LocalizedError {
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "画像の変換に失敗しました。"
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
