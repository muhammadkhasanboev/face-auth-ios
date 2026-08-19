import Foundation
import TadSigningSDK

@MainActor
final class PaymentViewModel: ObservableObject {
    let fromPhone: String
    private let loc: LocalizationManager

    @Published private(set) var recipientDigits = ""
    @Published var amount = "" {
        didSet {
            let digitsOnly = amount.filter(\.isNumber)
            if digitsOnly != amount { amount = digitsOnly }
        }
    }
    @Published private(set) var isLoading = false
    @Published private(set) var successMessage = ""
    @Published private(set) var errorMessage = ""

    init(fromPhone: String, localization: LocalizationManager) {
        self.fromPhone = fromPhone
        self.loc = localization
    }

    var recipientFormatted: String {
        guard !recipientDigits.isEmpty else { return "" }
        var result = ""
        for (i, ch) in recipientDigits.enumerated() {
            if i == 2 || i == 5 || i == 7 { result += " " }
            result.append(ch)
        }
        return result
    }

    var isValid: Bool {
        recipientDigits.count == 9 && !amount.isEmpty
    }

    func updateRecipient(from input: String) {
        let digits = input.filter(\.isNumber)
        recipientDigits = String(digits.prefix(9))
    }

    func pay() {
        guard isValid else { return }
        isLoading = true
        successMessage = ""
        errorMessage = ""
        let toPhone = "+998\(recipientDigits)"
        let payingAmount = amount
        SDKConfig.setup(bankId: fromPhone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: [:])
            isLoading = false
            switch status {
            case .statusOk:
                successMessage = loc.f("Transfer %@ sum to %@ confirmed", payingAmount, toPhone)
            case .statusError(let msg, let ec):
                errorMessage = ec == "USER_CANCELLED" ? loc.t("Cancelled") : loc.f("Error: %@", msg)
            }
        }
    }
}
