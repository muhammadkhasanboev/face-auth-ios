import SwiftUI

struct PaymentCardView: View {
    @ObservedObject var viewModel: PaymentViewModel

    @FocusState private var focusedField: Field?
    @EnvironmentObject private var loc: LocalizationManager

    private enum Field { case phone, amount }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.aab)
                Text(loc.t("Transfer by number"))
                    .font(.subheadline).bold()
                Spacer()
            }

            // Recipient phone
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.t("Recipient number"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Text("+998")
                        .font(.body).bold()
                        .foregroundStyle(Color.aab)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.aabBg, in: RoundedRectangle(cornerRadius: 10))
                    ZStack(alignment: .leading) {
                        if viewModel.recipientDigits.isEmpty {
                            Text("XX XXX XX XX")
                                .foregroundStyle(Color(.placeholderText))
                        }
                        TextField("", text: Binding(
                            get: { viewModel.recipientFormatted },
                            set: { viewModel.updateRecipient(from: $0) }
                        ))
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .phone)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.aabBg, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            // Amount
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.t("Amount"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("0", text: $viewModel.amount)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .amount)
                    Text(loc.t("sum"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.aabBg, in: RoundedRectangle(cornerRadius: 10))
            }

            // Pay button / loading
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text(loc.t("Confirming..."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            } else {
                AABButton(title: loc.t("Pay"), enabled: viewModel.isValid) {
                    focusedField = nil
                    viewModel.pay()
                }
            }

            if !viewModel.successMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(viewModel.successMessage).font(.caption).foregroundStyle(.green)
                }
            }
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(loc.t("Done")) { focusedField = nil }
            }
        }
    }
}
