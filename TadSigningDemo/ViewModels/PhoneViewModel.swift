import Foundation

@MainActor
final class PhoneViewModel: ObservableObject {
    @Published private(set) var digits = ""

    var formatted: String {
        guard !digits.isEmpty else { return "" }
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i == 2 || i == 5 || i == 7 { result += " " }
            result.append(ch)
        }
        return result
    }

    var isValid: Bool { digits.count == 9 }

    var fullPhoneNumber: String { "+998 \(formatted)" }

    func update(from input: String) {
        let filtered = input.filter(\.isNumber)
        digits = String(filtered.prefix(9))
    }
}
