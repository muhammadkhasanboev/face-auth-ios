import SwiftUI

struct OTPView: View {
    let phone: String
    let onSuccess: () -> Void
    let onBack: () -> Void

    @StateObject private var viewModel: OTPViewModel
    @FocusState private var focused: Bool
    @EnvironmentObject private var loc: LocalizationManager

    init(phone: String, onSuccess: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.phone = phone
        self.onSuccess = onSuccess
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: OTPViewModel(phone: phone, localization: .shared))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundStyle(Color.aab)
                        .padding(10)
                        .background(Color.aabCard, in: Circle())
                        .shadow(color: .black.opacity(0.08), radius: 6)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            Spacer().frame(height: 32)

            // Icon
            Image(systemName: "message.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.aab)
                .padding(20)
                .background(Color.aab.opacity(0.1), in: Circle())

            Spacer().frame(height: 24)

            VStack(spacing: 6) {
                Text(loc.t("Enter code"))
                    .font(.title2).bold()
                Text(loc.f("Code sent to %@", phone))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 36)

            // OTP boxes
            OTPBoxes(code: viewModel.code, onChange: viewModel.updateCode, focused: $focused)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer().frame(height: 12)

            // Resend
            Group {
                if viewModel.secondsLeft > 0 {
                    Text(loc.f("Resend in %d sec", viewModel.secondsLeft))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button(loc.t("Resend")) { viewModel.restartTimer() }
                        .font(.caption.bold())
                        .foregroundStyle(Color.aab)
                }
            }
            .padding(.bottom, 32)

            // Button
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.aab)
                        .frame(height: 50)
                } else {
                    AABButton(title: loc.t("Confirm and sign in"), enabled: viewModel.isValid) {
                        viewModel.verify(onSuccess: onSuccess)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.aabBg.ignoresSafeArea())
        .onAppear {
            focused = true
            viewModel.onAppear()
        }
        .onDisappear { viewModel.onDisappear() }
    }
}
