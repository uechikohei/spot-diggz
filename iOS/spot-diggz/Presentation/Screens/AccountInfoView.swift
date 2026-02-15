import SwiftUI

/// Displays account metadata and the current user's own posts.
struct AccountInfoView: View {
    @EnvironmentObject var appState: SdzAppState

    let userId: String
    let displayName: String
    let email: String?
    let providerLabel: String
    let emailChangeNote: String
    let mySpots: [SdzSpot]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    accountCard
                    postCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("アカウント情報")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                avatarView
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.72))
                    }
                }
                Spacer()
            }
            Divider().overlay(Color.white.opacity(0.12))
            accountInfoRow(title: "ユーザーID", value: userId)
            accountInfoRow(title: "ログイン方法", value: providerLabel)
            if let email, !email.isEmpty {
                accountInfoRow(title: "メール", value: email)
            }
            Text(emailChangeNote)
                .font(.caption)
                .foregroundColor(.white.opacity(0.62))
                .padding(.top, 6)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自分の投稿")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if mySpots.isEmpty {
                Text("投稿がありません")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.72))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mySpots.enumerated()), id: \.element.id) { index, spot in
                        NavigationLink(destination: SpotDetailView(spot: spot)) {
                            SpotCardView(spot: spot)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        if index < mySpots.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var avatarView: some View {
        Group {
            if let data = appState.profileImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.88))
                    )
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private func accountInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.14, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.11)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#if DEBUG
struct AccountInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountInfoView(
                userId: "user-123",
                displayName: "Kohei",
                email: "kohei@example.com",
                providerLabel: "Google",
                emailChangeNote: "Googleログインのメール変更はアカウント側で行います。",
                mySpots: [SdzSpot.sample(id: "1", name: "サンプルスポット")]
            )
            .environmentObject(SdzAppState())
        }
        .preferredColorScheme(.dark)
    }
}
#endif
