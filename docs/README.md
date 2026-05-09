# TadSigningDemo — Documentation

## Table of Contents

| # | Page | Description |
|---|------|-------------|
| 1 | [Overview](1-overview.md) | Project purpose and high-level architecture |
| 1.1 | [Getting Started](1.1-getting-started.md) | Setup, prerequisites, running the app |
| 1.2 | [Project Structure](1.2-project-structure.md) | Repository layout and XcodeGen config |
| 2 | [Application Architecture](2-application-architecture.md) | SwiftUI + UIKit bridge pattern |
| 2.1 | [App Entry Point](2.1-app-entry-point.md) | `App.swift` — `@main` lifecycle |
| 2.2 | [Main UI & SDK Invocation](2.2-content-view.md) | `ContentView.swift` — form, buttons, result |
| 2.3 | [SDK Configuration](2.3-sdk-configuration.md) | `SDKConfig.swift` — API URL, keys, security flags |
| 3 | [TadSigningSDK Integration](3-sdk-integration.md) | How the SDK is consumed |
| 3.1 | [Signing Modes: Register vs. Sign](3.1-signing-modes.md) | SMS once → then Passkey flow |
| 3.2 | [ONNX Runtime Dependency](3.2-onnx-runtime.md) | Face liveness ML inference |
| 4 | [Security & Permissions](4-security-permissions.md) | Security architecture overview |
| 4.1 | [Entitlements & Associated Domains](4.1-entitlements.md) | Passkey domain association setup |
| 4.2 | [Privacy Permissions](4.2-privacy-permissions.md) | Camera, Face ID, Info.plist |
| 7 | [Glossary](7-glossary.md) | Terms, types, and key references |

## Quick Start

```swift
// 1. Configure the SDK
let config = TadSigningConfig(
    apiBaseUrl: URL(string: "https://signing.tadi.uz")!,
    publicKeyPem: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    rpId: "signing.tadi.uz",
    serviceName: "my-bank-app",
    blockProxy: true
)

// 2. Register (SMS OTP sent once)
let vc = TadSigningViewController(
    config: config,
    bankId: "user-123",
    dto: ["otp": "54321"],
    mode: .register
) { result in
    // registration complete — no JWT yet
}
present(vc, animated: true)

// 3. Sign in (no SMS, just Face ID + Passkey → JWT)
let vc = TadSigningViewController(
    config: config,
    bankId: "user-123",
    dto: [:],
    mode: .sign
) { result in
    if case .success(let jwt, _) = result {
        // use jwt to authenticate with your backend
    }
}
present(vc, animated: true)
```
