import Foundation
import TadSigningSDK

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, ru

    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: return "EN"
        case .ru: return "RU"
        }
    }

    var sdkLanguage: TadLanguage {
        switch self {
        case .en: return .en
        case .ru: return .ru
        }
    }
}
