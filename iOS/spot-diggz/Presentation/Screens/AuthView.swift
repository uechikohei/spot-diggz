import SwiftUI

/// A simple authentication screen that lets the user sign in or create an account.
struct AuthView: View {
    @EnvironmentObject var appState: SdzAppState

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSignUp: Bool = false
    @State private var isBusy: Bool = false
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
                .textInputAutocapitalization(.never)
                .disabled(isBusy)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("パスワード", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .disabled(isBusy)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if isSignUp {
                SecureField("パスワード（確認）", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .disabled(isBusy)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            Button(action: {
                handlePrimaryAction()
            }) {
                Text(isBusy ? "処理中..." : (isSignUp ? "新規登録" : "ログイン"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 16)
            .disabled(isBusy)

            Button(action: {
                handleGoogleSignIn()
            }) {
                Label("Googleで続ける", systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
            .disabled(isBusy)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSignUp.toggle()
                    errorMessage = nil
                }
            }) {
                Text(isSignUp ? "ログインに戻る" : "新規登録")
                    .foregroundColor(.accentColor)
                    .padding(.top, 8)
            }
            .disabled(isBusy)
            Spacer()
        }
        .padding()
    }

    private func handlePrimaryAction() {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "メールアドレスを入力してください。"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "パスワードを入力してください。"
            return
        }
        if isSignUp && password != confirmPassword {
            errorMessage = "パスワードが一致しません。"
            return
        }

        isBusy = true
        Task {
            do {
                if isSignUp {
                    try await appState.signUpWithEmail(email: trimmedEmail, password: password)
                } else {
                    try await appState.signInWithEmail(email: trimmedEmail, password: password)
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                errorMessage = message
            }
            isBusy = false
        }
    }

    private func handleGoogleSignIn() {
        errorMessage = nil
        isBusy = true
        Task {
            do {
                try await appState.signInWithGoogle()
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                errorMessage = message
            }
            isBusy = false
        }
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
