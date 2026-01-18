import SwiftUI

/// Editing screen for a spot posted by the current user.
struct EditSpotView: View {
    let spot: SdzSpot

    @State private var name: String
    @State private var descriptionText: String
    @State private var tagsString: String
    @State private var location: SdzSpotLocation?

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
                if let location = location {
                    Text("選択された位置: \(location.lat), \(location.lng)")
                } else {
                    Text("位置情報が未設定です")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Text("編集機能は現在未承認のため保存できません。")
                    .foregroundColor(.red)
                Button("保存する") {}
                    .disabled(true)
            }
        }
        .navigationTitle("投稿を編集")
    }
}

#if DEBUG
struct EditSpotView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditSpotView(spot: SdzSpot.sample(id: "sample", name: "編集サンプル"))
        }
    }
}
#endif
