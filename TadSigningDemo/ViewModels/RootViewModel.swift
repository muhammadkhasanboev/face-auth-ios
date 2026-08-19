import Foundation
import TadSigningSDK

/// Owns the top-level app flow: phone entry → OTP registration → home,
/// and the persisted "which phone is registered on this device" state.
@MainActor
final class RootViewModel: ObservableObject {
    private static let phoneStorageKey = "registeredPhone"

    /// Derived from TadSigning.isRegistered() — the single source of truth.
    @Published private(set) var isRegistered = false
    @Published private(set) var registeredPhone: String
    @Published var route: AppRoute = .phone

    init() {
        registeredPhone = UserDefaults.standard.string(forKey: Self.phoneStorageKey) ?? ""
    }

    /// On launch: if a phone is stored, restore SDK config and check registration.
    /// If already registered → skip phone/SMS and go straight to home.
    func onAppear(language: AppLanguage) {
        guard !registeredPhone.isEmpty else { return }
        SDKConfig.setup(bankId: registeredPhone, language: language)
        isRegistered = TadSigning.isRegistered()
    }

    func startOTP(phone: String) {
        route = .otp(phone: phone)
    }

    func backToPhone() {
        route = .phone
    }

    func completeRegistration(phone: String) {
        registeredPhone = phone
        UserDefaults.standard.set(phone, forKey: Self.phoneStorageKey)
        isRegistered = TadSigning.isRegistered()
    }

    /// Logout: wipe SDK storage and go back to phone screen.
    func logout() {
        TadSigning.logout()
        registeredPhone = ""
        UserDefaults.standard.removeObject(forKey: Self.phoneStorageKey)
        isRegistered = false
        route = .phone
    }
}
