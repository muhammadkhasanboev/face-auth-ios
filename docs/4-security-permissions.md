# Security & Permissions

The project uses a multi-layered security approach combining hardware-backed biometrics, cryptographic Passkeys (WebAuthn), and real-time face liveness detection.

## Security Architecture — Four Pillars

1. **Identity Verification**: Device camera for real-time face liveness checks (anti-spoofing).
2. **Cryptographic Trust**: ES512 public key for verifying server-side signatures.
3. **Hardware-Bound Credentials**: Apple's Passkeys store private keys in the Secure Enclave.
4. **Domain Association**: Cryptographically verified link between the app and `signing.tadi.uz`.

## Security Configuration

| Security Feature | Implementation | Purpose |
| :--- | :--- | :--- |
| **Proxy Blocking** | `blockProxy: true` | Prevents traffic interception via system proxies. |
| **Relying Party ID** | `rpId: "signing.tadi.uz"` | Scopes Passkeys to the specific domain. |
| **Encryption** | `ITSAppUsesNonExemptEncryption: false` | Declares standard encryption for App Store compliance. |

## Detailed Topics

- [Entitlements & Associated Domains](4.1-entitlements.md)
- [Privacy Permissions & App Capabilities](4.2-privacy-permissions.md)
