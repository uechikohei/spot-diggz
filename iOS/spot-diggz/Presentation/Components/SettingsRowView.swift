import SwiftUI

/// A reusable settings row with icon, title, optional value and optional chevron.
struct SettingsRowView: View {
    let iconName: String
    let title: String
    let value: String?
    let showsChevron: Bool
    let isDestructive: Bool

    init(
        iconName: String,
        title: String,
        value: String? = nil,
        showsChevron: Bool = true,
        isDestructive: Bool = false
    ) {
        self.iconName = iconName
        self.title = title
        self.value = value
        self.showsChevron = showsChevron
        self.isDestructive = isDestructive
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 21, weight: .medium))
                .foregroundColor(isDestructive ? .red : .white.opacity(0.95))
                .frame(width: 30)

            Text(title)
                .font(.system(size: 29 / 2, weight: .semibold))
                .foregroundColor(isDestructive ? .red : .white)

            Spacer(minLength: 10)

            if let value {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#if DEBUG
struct SettingsRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            SettingsRowView(iconName: "person.circle", title: "アカウント情報")
            Divider().overlay(Color.white.opacity(0.12))
            SettingsRowView(iconName: "bell", title: "通知", value: "オン")
            Divider().overlay(Color.white.opacity(0.12))
            SettingsRowView(iconName: "rectangle.portrait.and.arrow.right", title: "ログアウト", showsChevron: false, isDestructive: true)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
#endif
