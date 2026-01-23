import SwiftUI

/// Full-screen location picker wrapper for better pin placement.
struct SdzLocationPickerSheetView: View {
    @Binding var selectedLocation: SdzSpotLocation?
    @Environment(\.dismiss) private var dismiss

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
    }

    private var content: some View {
        SdzLocationPickerView(selectedLocation: $selectedLocation, height: 440)
            .navigationTitle("位置を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
    }
}

#if DEBUG
struct SdzLocationPickerSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SdzLocationPickerSheetView(selectedLocation: .constant(nil))
    }
}
#endif
