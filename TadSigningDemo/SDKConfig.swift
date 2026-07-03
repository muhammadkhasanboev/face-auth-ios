import Foundation
import TadSigningSDK

enum SDKConfig {
    static func setup(bankId: String, token: String? = nil) {
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
            language: .ru
        )
    }
}
