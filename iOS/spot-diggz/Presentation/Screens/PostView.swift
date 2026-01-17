import SwiftUI
import MapKit
import UIKit

/// A screen for creating a new skate spot.
struct PostView: View {
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var tagsString: String = ""
    @State private var selectedLocation: SdzSpotLocation?
    @State private var images: [UIImage] = []
    @State private var showImagePicker: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("スポット名", text: $name)
                    TextField("説明", text: $description, axis: .vertical)
                }

                Section(header: Text("タグ（カンマ区切り）")) {
                    TextField("例: パーク, ストリート", text: $tagsString)
                }

                Section(header: Text("位置情報")) {
                    if let location = selectedLocation {
                        Text("選択された位置: \(location.lat), \(location.lng)")
                    } else {
                        Text("まだ位置が選択されていません")
                            .foregroundColor(.secondary)
                    }
                    Button("現在地を設定") {
                        // TODO: Use CoreLocation to set current location.
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

                Section {
                    Button("投稿する") {
                        submit()
                    }
                }
            }
            .navigationTitle("新しいスポットを投稿")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $images)
            }
        }
    }

    private func submit() {
        // TODO: Validate input and call API to create a new spot.
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
    }
}
#endif