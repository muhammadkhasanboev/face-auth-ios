import SwiftUI

struct PhoneView: View {
    let onContinue: (String) -> Void

    @StateObject private var viewModel = PhoneViewModel()
    @FocusState private var focused: Bool
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.aab)
                    VStack(spacing: 6) {
                        Text("AnyOtherBank")
                            .font(.title2).bold()
                            .foregroundStyle(Color.aabDark)
                        Text(loc.t("Welcome"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer().frame(height: 24)
                }

                // Card
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc.t("Phone number"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Text("+998")
                                .font(.body).bold()
                                .foregroundStyle(Color.aab)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color.aabBg, in: RoundedRectangle(cornerRadius: 12))
                            ZStack(alignment: .leading) {
                                if viewModel.digits.isEmpty {
                                    Text("XX XXX XX XX")
                                        .foregroundStyle(Color(.placeholderText))
                                }
                                TextField("", text: Binding(
                                    get: { viewModel.formatted },
                                    set: { viewModel.update(from: $0) }
                                ))
                                .keyboardType(.numberPad)
                                .focused($focused)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Color.aabBg, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Text(loc.t("We'll send an SMS code for your first sign in. After that, you'll sign in with Face ID only."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    AABButton(title: loc.t("Get SMS code"), enabled: viewModel.isValid) {
                        onContinue(viewModel.fullPhoneNumber)
                    }
                }
                .padding(24)
                .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.aabBg.ignoresSafeArea())
        .onAppear { focused = true }
    }
}
