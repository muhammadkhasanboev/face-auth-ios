import SwiftUI
import TadSigningSDK

struct ContentView: View {

    @State private var bankId    = "demo-user-001"
    @State private var otp       = "12345"
    @State private var result    = ""
    @State private var isLoading = false
    @State private var resultColor: Color = .secondary

    var body: some View {
        NavigationStack {
            Form {
                Section("Credentials") {
                    LabeledContent("Bank ID") {
                        TextField("bank-user-id", text: $bankId)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("OTP") {
                        TextField("one-time-password", text: $otp)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section {
                    Button(action: { present(mode: .register) }) {
                        Label("Register", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || bankId.isEmpty)

                    Button(action: { present(mode: .sign) }) {
                        Label("Sign In", systemImage: "person.badge.key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || bankId.isEmpty)
                }

                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Processing…")
                            Spacer()
                        }
                    }
                }

                if !result.isEmpty {
                    Section("Result") {
                        Text(result)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(resultColor)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("TAD Signing Demo")
        }
    }

    // MARK: - Present TadSigningViewController

    private func present(mode: TadSigningMode) {
        guard let vc = topViewController() else { return }
        isLoading = true
        result    = ""

        let dto = otp.isEmpty ? [:] : ["otp": otp]

        let signingVC = TadSigningViewController(
            config:     SDKConfig.shared,
            bankId:     bankId,
            dto:        dto,
            mode:       mode
        ) { signingResult in
            isLoading = false
            switch signingResult {
            case .success(let jwt, let requestId):
                resultColor = .green
                result = mode == .register
                    ? "✅ Registered\nrequestId: \(requestId)"
                    : "✅ Signed\nrequestId: \(requestId)\n\nJWT:\n\(jwt)"
            case .failure(let code, let message):
                resultColor = .red
                result = "❌ \(code.rawValue)\n\(message)"
            }
        }

        vc.present(signingVC, animated: true)
    }

    // MARK: - Helpers

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

#Preview {
    ContentView()
}
