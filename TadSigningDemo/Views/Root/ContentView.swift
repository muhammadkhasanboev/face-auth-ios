import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RootViewModel()
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ZStack {
            Color.aabBg.ignoresSafeArea()
            if viewModel.isRegistered {
                HomeView(phone: viewModel.registeredPhone, onSignOut: viewModel.logout)
                    .transition(.opacity)
            } else {
                switch viewModel.route {
                case .phone:
                    PhoneView { phone in
                        viewModel.startOTP(phone: phone)
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                case .otp(let phone):
                    OTPView(phone: phone) {
                        viewModel.completeRegistration(phone: phone)
                    } onBack: {
                        viewModel.backToPhone()
                    }
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            LanguageToggle()
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRegistered)
        .onAppear {
            viewModel.onAppear(language: loc.language)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
}
