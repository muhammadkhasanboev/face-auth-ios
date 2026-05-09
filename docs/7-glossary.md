# Glossary

## Core Domain Concepts

| Term | Definition |
| :--- | :--- |
| **Passkey** | A passwordless authentication method based on WebAuthn/FIDO2. The SDK uses Passkeys to provide secure, biometric-backed identity verification. |
| **Liveness Check** | A process that uses the camera to ensure the user is a real human and not a photo or video. Powered by ONNX Runtime within the SDK. |
| **RP ID** | Relying Party Identifier. A domain string (e.g., `signing.tadi.uz`) that anchors the Passkey to a specific web/app origin. |
| **JWT** | JSON Web Token. The final artifact returned by the SDK upon successful signing, used by the backend to verify the transaction. |
| **DTO** | Data Transfer Object. A dictionary of additional parameters (like `otp`) sent to the SDK to be included in the signing payload. |
| **AASA** | Apple App Site Association. A JSON file hosted at `/.well-known/apple-app-site-association` that establishes trust between the app and domain. |

## SDK Integration Types

### TadSigningMode
- `.register`: Creates a new Passkey, links it to a `bankId`. OTP sent once here.
- `.sign`: Authenticates via face liveness + Passkey. No OTP needed.

### TadSigningConfig
- `apiBaseUrl`: Backend endpoint.
- `publicKeyPem`: ES512 public key for verifying server responses.
- `blockProxy`: When `true`, blocks MITM proxy tools.

### TadSigningResult
- `.success(jwt: String, requestId: String)`: Successful completion.
- `.failure(code: TadSigningError, message: String)`: Error occurred.

## Technical Abbreviations

| Term | Meaning |
| :--- | :--- |
| **ONNX** | Open Neural Network Exchange — ML model format used for liveness detection. |
| **WebAuthn** | Web Authentication API — standard behind Passkeys. |
| **FIDO2** | Fast Identity Online 2 — the authentication standard WebAuthn implements. |
| **Secure Enclave** | Apple's dedicated security chip storing Passkey private keys. |
| **MITM** | Man-in-the-Middle — attack intercepting communication between app and server. |

## Key Class & Function Reference

| Entity | Role |
| :--- | :--- |
| `TadSigningDemoApp` | SwiftUI `@main` entry point. |
| `ContentView` | Main UI managing state for `bankId`, `otp`, `isLoading`. |
| `SDKConfig.shared` | Static singleton providing `TadSigningConfig`. |
| `topViewController()` | Helper to find the active `UIViewController` for modal presentation. |
| `present(mode:)` | Primary bridge function configuring and displaying `TadSigningViewController`. |
