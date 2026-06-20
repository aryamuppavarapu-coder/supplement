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
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                BrandHeader(subtitle: "Understand your lab results — in plain language.")

                GlassCard(padding: 20) {
                    VStack(spacing: 18) {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(Theme.sage)
                                TextField("Email", text: $vm.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .font(Theme.rounded(.body))
                                    .foregroundStyle(Theme.ink)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.sage.opacity(0.35), lineWidth: 1))

                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Theme.sage)
                                SecureField("Password", text: $vm.password)
                                    .textContentType(vm.isSignUp ? .newPassword : .password)
                                    .font(Theme.rounded(.body))
                                    .foregroundStyle(Theme.ink)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.sage.opacity(0.35), lineWidth: 1))
                        }

                        Button {
                            Task { await vm.submitEmail() }
                        } label: {
                            if vm.busy {
                                ProgressView().tint(.white)
                            } else {
                                Text(vm.isSignUp ? "Create account" : "Sign in")
                            }
                        }
                        .buttonStyle(.aero)
                        .disabled(vm.busy)

                        Button(vm.isSignUp ? "Have an account? Sign in" : "New here? Create an account") {
                            vm.isSignUp.toggle()
                        }
                        .font(Theme.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.sageDeep)

                        HStack(spacing: 12) {
                            Rectangle().fill(Theme.sage.opacity(0.3)).frame(height: 1)
                            Text("or")
                                .font(Theme.rounded(.footnote))
                                .foregroundStyle(Theme.inkSoft)
                            Rectangle().fill(Theme.sage.opacity(0.3)).frame(height: 1)
                        }

                        SignInWithAppleButton(.signIn) { request in
                            vm.configure(request)
                        } onCompletion: { result in
                            Task { await vm.handle(result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // NOTE: Google sign-in (SPEC §3.1) needs the GoogleSignIn SPM package + a URL
                        // scheme; add it as a follow-up. Email + Apple are wired up here.

                        if let error = vm.error {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Theme.color(for: .criticalHigh))
                                Text(error)
                                    .font(Theme.rounded(.footnote))
                                    .foregroundStyle(Theme.color(for: .criticalHigh))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "leaf.circle.fill").foregroundStyle(Theme.sage)
                    Text("By continuing you agree this app provides educational information, not medical advice.")
                        .font(Theme.rounded(.footnote))
                }
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 24)
            }
            .padding(20)
        }
        .aeroScreen()
    }
}
