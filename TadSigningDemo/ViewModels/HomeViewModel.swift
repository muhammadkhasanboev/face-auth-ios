import Foundation
import TadSigningSDK

@MainActor
final class HomeViewModel: ObservableObject {
    let phone: String
    private let loc: LocalizationManager

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage = ""
    @Published private(set) var jwtStatus = ""
    @Published var showJWT = false
    @Published var showPayment = false

    var deviceId: String { TadSigning.deviceId() ?? "none" }

    init(phone: String, localization: LocalizationManager) {
        self.phone = phone
        self.loc = localization
    }

    func signIn(onNeedsReregistration: @escaping () -> Void) {
        isLoading = true
        errorMessage = ""
        SDKConfig.setup(bankId: phone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: [:])
            isLoading = false
            switch status {
            case .statusOk:
                jwtStatus = "✓ Authenticated"
                showPayment = true
            case .statusError(let msg, let code):
                if code.hasPrefix("WEBAUTHN_") {
                    // Registration no longer valid on the server — the SDK already
                    // wiped the local session → send the user to re-register.
                    onNeedsReregistration()
                } else {
                    errorMessage = loc.f("Sign in error: %@", msg)
                }
            }
        }
    }
}
