import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, ru
    var id: String { rawValue }
    var label: String {
        switch self {
        case .en: return "EN"
        case .ru: return "RU"
        }
    }
}

/// English UI text is the canonical key; Russian strings are looked up from `russian` when selected.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let storageKey = "appLanguage"

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey) }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = AppLanguage(rawValue: raw) {
            language = saved
        } else {
            language = .en
        }
    }

    func t(_ key: String) -> String {
        guard language == .ru else { return key }
        return Self.russian[key] ?? key
    }

    func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    private static let russian: [String: String] = [
        "Welcome": "Добро пожаловать",
        "Phone number": "Номер телефона",
        "We'll send an SMS code for your first sign in. After that, you'll sign in with Face ID only.":
            "Для первого входа мы отправим SMS-код. В дальнейшем вход — только по Face ID.",
        "Get SMS code": "Получить SMS-код",
        "Done": "Готово",
        "Enter code": "Введите код",
        "Code sent to %@": "Код отправлен на %@",
        "Resend in %d sec": "Отправить повторно через %d сек",
        "Resend": "Отправить повторно",
        "Confirm and sign in": "Подтвердить и войти",
        "Cancelled": "Отменено",
        "Error: %@": "Ошибка: %@",
        "Welcome!": "Добро пожаловать!",
        "Biometric sign in": "Биометрический вход",
        "SMS is no longer needed. Sign in with Face ID in one tap.":
            "SMS больше не нужен. Входите по Face ID за одно касание.",
        "Checking...": "Проверка...",
        "Sign in with Face ID": "Войти по Face ID",
        "Signed in successfully": "Вход выполнен успешно",
        "Hide token": "Скрыть токен",
        "Show JWT": "Показать JWT",
        "Sign out": "Выйти из аккаунта",
        "Sign in error: %@": "Ошибка входа: %@",
        "Transfer": "Перевод",
        "Transfer %@ sum to %@ confirmed": "Перевод %@ сум на %@ подтверждён",
        "Transfer by number": "Перевод по номеру",
        "Recipient number": "Номер получателя",
        "Amount": "Сумма",
        "sum": "сум",
        "Confirming...": "Подтверждение...",
        "Pay": "Оплатить",
    ]
}
