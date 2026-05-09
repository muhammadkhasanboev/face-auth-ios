# TadSigningSDK Integration

The `TadSigningDemo` app consumes `TadSigningSDK` as a local package providing face-based authentication and document signing. Integration is centered around `TadSigningViewController`, which encapsulates the entire biometric and cryptographic workflow.

## SDK Consumption Overview

| Component | Responsibility |
| :--- | :--- |
| **`SDKConfig`** | Holds the static `TadSigningConfig` singleton with backend URLs and public keys. |
| **`ContentView`** | Captures user input (`bankId`, `otp`) and initiates the SDK presentation. |
| **`TadSigningViewController`** | Orchestrates liveness detection, Passkey interactions, and API calls. |
| **`TadSigningMode`** | Determines whether the SDK performs registration or signing. |

## Operational Modes

The SDK operates in two primary modes:
- **`.register`**: First-time setup — captures face liveness, creates Passkey, links device to `bankId` via OTP.
- **`.sign`**: Subsequent logins — face liveness + Passkey assertion → returns JWT.

## Error Handling

The SDK returns a structured result via completion handler:
- **`.success(jwt, requestId)`**: Operation completed successfully.
- **`.failure(code, message)`**: Specific error (network, biometric rejection, server validation).

## ML and Runtime Dependencies

| Dependency | Version | Purpose |
| :--- | :--- | :--- |
| `onnxruntime-swift-package-manager` | `1.24.2` | ML Inference engine for face liveness detection. |

See [Signing Modes](3.1-signing-modes.md) and [ONNX Runtime](3.2-onnx-runtime.md) for details.
