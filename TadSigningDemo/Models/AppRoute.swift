import Foundation

enum AppRoute: Equatable {
    case phone
    case otp(phone: String)
}
