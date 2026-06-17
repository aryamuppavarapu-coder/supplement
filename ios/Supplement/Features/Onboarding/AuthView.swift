import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var isSignUp = false
    var busy = false
    var error: String?
    private var currentNonce: String?

    func submitEmail() async {
        guard !email.isEmpty, !password.isEmpty else { error = "Enter your email and password."; return }
        busy = true; error = nil
        defer { busy = false }
        do {
            if isSignUp {
                try await Auth.auth().createUser(withEmail: email, password: password)
            } else {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: Sign in with Apple (SPEC §3.1)

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handle(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let err):
            error = err.localizedDescription
        case .success(let auth):
            guard
                let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = cred.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else { error = "Apple sign-in failed."; return }
            let firebaseCred = OAuthProvider.appleCredential(
                withIDToken: idToken, rawNonce: nonce, fullName: cred.fullName
            )
            do { try await Auth.auth().signIn(with: firebaseCred) }
            catch { self.error = error.localizedDescription }
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if Int(random) < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

struct AuthView: View {
    @State private var vm = AuthViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(Theme.appName)
                .font(.largeTitle.bold())
            Text("Understand your lab results — in plain language.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                TextField("Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $vm.password)
                    .textContentType(vm.isSignUp ? .newPassword : .password)
            }
            .textFieldStyle(.roundedBorder)

            Button {
                Task { await vm.submitEmail() }
            } label: {
                if vm.busy { ProgressView() } else { Text(vm.isSignUp ? "Create account" : "Sign in").bold() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.busy)

            Button(vm.isSignUp ? "Have an account? Sign in" : "New here? Create an account") {
                vm.isSignUp.toggle()
            }
            .font(.footnote)

            SignInWithAppleButton(.signIn) { request in
                vm.configure(request)
            } onCompletion: { result in
                Task { await vm.handle(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)

            // NOTE: Google sign-in (SPEC §3.1) needs the GoogleSignIn SPM package + a URL
            // scheme; add it as a follow-up. Email + Apple are wired up here.

            if let error = vm.error {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
            Spacer()
            Text("By continuing you agree this app provides educational information, not medical advice.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
