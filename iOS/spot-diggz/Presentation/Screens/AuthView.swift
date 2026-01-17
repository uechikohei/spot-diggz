import SwiftUI

/// A simple authentication screen that lets the user sign in or create an account.
struct AuthView: View {
    @EnvironmentObject var appState: SdzAppState

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Spacer()
            Text("SpotDiggz")
                .font(.largeTitle)
                .bold()

            TextField("メールアドレス", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("パスワード", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            Button(action: {
                // TODO: Integrate Firebase Auth sign-in.
                appState.isAuthenticated = true
            }) {
                Text("ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 16)

            Button(action: {
                // TODO: Navigate to sign up flow.
            }) {
                Text("新規登録")
                    .foregroundColor(.accentColor)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }
}

#if DEBUG
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(SdzAppState())
    }
}
#endif