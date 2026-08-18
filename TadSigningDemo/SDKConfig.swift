import Foundation
import Security
import TadSigningSDK

/// TEST-ONLY helper: deletes the current registration from the server via
/// POST /api/v1/registration/remove. It needs the current `deviceId`, which the
/// SDK does not expose — but since the SDK is linked into this app, the deviceId
/// it stored in the Keychain is readable here with the same service/account.
/// (Relies on an SDK-internal detail; fine for a demo, not for production.)
enum RegistrationRemover {

    private static let removeURL = "https://signing.tadi.uz/api/v1/registration/remove"

    /// The SDK's current deviceId (public accessor added in 1.0.2, for support/testing).
    static func currentDeviceId() -> String? {
        TadSigning.deviceId()
    }

    /// Removes the current (bankId, deviceId) registration on the server.
    /// Returns (ok, message).
    static func removeFromServer(bankId: String) async -> (ok: Bool, message: String) {
        guard let deviceId = currentDeviceId() else {
            return (false, "No deviceId found (is the device registered?)")
        }
        guard let url = URL(string: removeURL) else { return (false, "Bad URL") }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.httpBody = try? JSONSerialization.data(
            withJSONObject: ["bankId": bankId, "deviceId": deviceId]
        )

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(data: data, encoding: .utf8) ?? ""
            return (200...299).contains(code)
                ? (true, "removed (deviceId \(deviceId.prefix(8))…)")
                : (false, "HTTP \(code): \(text)")
        } catch {
            return (false, error.localizedDescription)
        }
    }
}

enum SDKConfig {
    static func setup(bankId: String, token: String? = nil, language: AppLanguage = .en) {
        TadSigning.configure(
            apiBaseUrl:   URL(string: "https://signing.tadi.uz")!,
            publicKeyPem: """
            -----BEGIN PUBLIC KEY-----
            MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQANTC0w0ACO79+hPYfK5fEF9nAAztI
            zpD8M0UTyR4ON5DeT3nKY12noi9PVVCIK1uwImeqsWx56cc7kMmWC99RKV0Az3JC
            Zq5gRExuUzk+aWcoG3DppFy2hCwEVeuDTENz0P5Rhx/BBJ8Q4jWVOM2AM2W3SQ/q
            1nG5s8ixxX2BnPBTQ7w=
            -----END PUBLIC KEY-----
            """,
            rpId:        "signing.tadi.uz",
            serviceName: "tad-signing-demo",
            bankId:      bankId,
            token: token,
            blockProxy:  true,
            language: language.sdkLanguage
        )
    }
}

extension AppLanguage {
    var sdkLanguage: TadLanguage {
        switch self {
        case .en: return .en
        case .ru: return .ru
        }
    }
}
