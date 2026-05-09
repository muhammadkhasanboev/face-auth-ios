# Overview

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [TadSigningDemo.xcodeproj/project.pbxproj](TadSigningDemo.xcodeproj/project.pbxproj)
- [TadSigningDemo/App.swift](TadSigningDemo/App.swift)
- [project.yml](project.yml)

</details>



The **TadSigningDemo** project is a reference implementation and demonstration of the `TadSigningSDK`. It showcases a secure biometric authentication and document signing workflow on iOS, leveraging face liveness detection and Apple's Passkeys (WebAuthn). The application serves as a blueprint for integrating high-security identity verification into mobile banking or governmental services.

### Core Capabilities
*   **Biometric Registration**: Capturing face liveness data and provisioning a Passkey.
*   **Secure Signing**: Using biometrics to authorize and sign transactions via the SDK.
*   **SDK Integration**: Demonstrates the configuration and invocation of the `TadSigningSDK` local package.

For a guide on setting up the environment and running the app, see [Getting Started](1.1-getting-started.md).

---

### High-Level Architecture

The application is built using **SwiftUI** for the user interface and follows a modern declarative approach. It bridges to the `TadSigningSDK` (which is a UIKit-based framework) by managing a presentation layer that hosts the SDK's view controllers.

### Major Components & Relationships

| Component | File | Responsibility |
| :--- | :--- | :--- |
| **App Entry** | `App.swift` | Defines the `@main` entry point and root `WindowGroup`. |
| **UI & Logic** | `ContentView.swift` | Manages user input (Credentials/OTP) and SDK presentation logic. |
| **Configuration** | `SDKConfig.swift` | Stores static parameters like `apiBaseUrl` and `publicKeyPem`. |

### Project Structure & Dependencies

The project is managed via **XcodeGen**, using a `project.yml` file to define targets, entitlements, and dependencies.

*   **Local SDK**: Referenced as a local Swift Package via a filesystem path.
*   **Entitlements**: Includes `com.apple.developer.associated-domains` for Passkey support (`signing.tadi.uz`).
*   **Privacy**: Requires `NSCameraUsageDescription` for liveness checks and `NSFaceIDUsageDescription` for Passkey security.
