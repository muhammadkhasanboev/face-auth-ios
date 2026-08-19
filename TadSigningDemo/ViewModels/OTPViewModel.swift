import Foundation
import TadSigningSDK

@MainActor
final class OTPViewModel: ObservableObject {
    let phone: String
    private let loc: LocalizationManager

    @Published private(set) var code = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage = ""
    @Published private(set) var secondsLeft = 60

    private var timer: Timer?

    var isValid: Bool { code.count == 6 }

    init(phone: String, localization: LocalizationManager) {
        self.phone = phone
        self.loc = localization
    }

    func onAppear() {
        restartTimer()
    }

    func onDisappear() {
        timer?.invalidate()
    }

    func updateCode(_ input: String) {
        let digits = input.filter(\.isNumber)
        code = String(digits.prefix(6))
    }

    func restartTimer() {
        secondsLeft = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self else { t.invalidate(); return }
                if self.secondsLeft > 0 {
                    self.secondsLeft -= 1
                } else {
                    t.invalidate()
                }
            }
        }
    }

    func verify(onSuccess: @escaping () -> Void) {
        isLoading = true
        errorMessage = ""
        SDKConfig.setup(bankId: phone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: ["otp": code])
            isLoading = false
            switch status {
            case .statusOk:
                onSuccess()
            case .statusError(let msg, let ec):
                errorMessage = ec == "USER_CANCELLED" ? loc.t("Cancelled") : loc.f("Error: %@", msg)
            }
        }
    }
}
