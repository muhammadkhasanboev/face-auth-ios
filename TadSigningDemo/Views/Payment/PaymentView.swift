import SwiftUI

struct PaymentView: View {
    let phone: String

    @StateObject private var viewModel: PaymentViewModel
    @EnvironmentObject private var loc: LocalizationManager

    init(phone: String) {
        self.phone = phone
        _viewModel = StateObject(wrappedValue: PaymentViewModel(fromPhone: phone, localization: .shared))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)
                PaymentCardView(viewModel: viewModel)
                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.aabBg.ignoresSafeArea())
        .navigationTitle(loc.t("Transfer"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}
