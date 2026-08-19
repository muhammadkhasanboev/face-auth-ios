import SwiftUI

struct HomeView: View {
    let phone: String
    let onSignOut: () -> Void

    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var loc: LocalizationManager

    init(phone: String, onSignOut: @escaping () -> Void) {
        self.phone = phone
        self.onSignOut = onSignOut
        _viewModel = StateObject(wrappedValue: HomeViewModel(phone: phone, localization: .shared))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .bottom) {
                    Color.aab.ignoresSafeArea(edges: .top)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AnyOtherBank")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))

                            Text(loc.t("Welcome!"))
                                .font(.title2).bold()
                                .foregroundStyle(.white)
                            Text(phone)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 60)
                }
                .frame(height: 80)

                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 80)

                        // Passkey info card
                        HStack(spacing: 16) {
                            Image(systemName: "faceid")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.aab)
                                .frame(width: 56, height: 56)
                                .background(Color.aab.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loc.t("Biometric sign in"))
                                    .font(.subheadline).bold()
                                Text(loc.t("SMS is no longer needed. Sign in with Face ID in one tap."))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)

                        // Sign in button
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text(loc.t("Checking..."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8)
                        } else {
                            Button {
                                viewModel.signIn(onNeedsReregistration: onSignOut)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "faceid")
                                        .font(.title3)
                                    Text(loc.t("Sign in with Face ID"))
                                        .font(.body.bold())
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.aab, in: RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.aab.opacity(0.4), radius: 10, y: 4)
                            }
                        }

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !viewModel.jwtStatus.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text(loc.t("Signed in successfully"))
                                        .font(.subheadline).bold()
                                    Spacer()
                                }
                                Divider()
                                Button(viewModel.showJWT ? loc.t("Hide token") : loc.t("Show JWT")) {
                                    viewModel.showJWT.toggle()
                                }
                                .font(.caption.bold())
                                .foregroundStyle(Color.aab)
                                if viewModel.showJWT {
                                    Text(viewModel.jwtStatus)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(16)
                            .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.2)))
                        }

                        Spacer().frame(height: 24)

                        // TEST: the SDK's current deviceId — selectable so it can be
                        // copied and sent (e.g. to remove this exact registration on the
                        // server via /api/v1/registration/remove during a joint test).
                        VStack(spacing: 2) {
                            Text("deviceId (tap-hold to copy):")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(viewModel.deviceId)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.center)
                        }
                        .onAppear { print("deviceId:", viewModel.deviceId) }

                        // Sign out
                        Button(loc.t("Sign out"), action: onSignOut)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.aabBg.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $viewModel.showPayment) {
                PaymentView(phone: phone)
            }
        }
    }
}
