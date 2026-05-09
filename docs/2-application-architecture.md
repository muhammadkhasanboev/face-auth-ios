# Application Architecture

The app is built using **SwiftUI** for its main interface and lifecycle management, but utilizes a **UIKit bridge pattern** to integrate and present the core `TadSigningViewController` from the SDK.

### Core Components

#### 1. App Entry Point (`App.swift`)
Standard SwiftUI `@main` entry point. Sets `ContentView` as the root view within a `WindowGroup`.

#### 2. Main UI & SDK Invocation (`ContentView.swift`)
Primary view managing user interface for inputting credentials (`bankId`, `otp`) and triggering the SDK.

Because the SDK provides a `UIViewController`, `ContentView` implements a `topViewController()` helper to find the active `UIWindowScene` and present the SDK's interface modally.

#### 3. SDK Configuration (`SDKConfig.swift`)
Static configuration provider encapsulating the `TadSigningConfig` object with security-critical parameters: backend URL, ES512 Public Key, and Relying Party Identifier (`rpId`).

### Data Flow

| Operation | Code Entity | File |
| :--- | :--- | :--- |
| **App Startup** | `TadSigningDemoApp` | `App.swift` |
| **Credential Input** | `TextField` ($bankId, $otp) | `ContentView.swift` |
| **SDK Initialization** | `TadSigningViewController` | `ContentView.swift` |
| **Security Policy** | `TadSigningConfig` | `SDKConfig.swift` |
| **Result Handling** | `signingResult` closure | `ContentView.swift` |
