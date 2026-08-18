import SwiftUI
import TadSigningSDK

// MARK: - Brand

private extension Color {
    static let aab = Color(red: 0.0, green: 0.38, blue: 0.70)          // Asia Alliance Blue
    static let aabDark = Color(red: 0.0, green: 0.25, blue: 0.50)
    static let aabBg = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let aabCard = Color.white
}

// MARK: - App Flow

private enum Step { case phone, otp(phone: String), home }

// MARK: - Root

struct ContentView: View {
    /// Phone stored from last registration — used to restore SDK config on relaunch.
    @AppStorage("registeredPhone") private var registeredPhone = ""
    /// Derived from TadSigning.isRegistered() — the single source of truth.
    @State private var isRegistered = false
    @State private var step: Step = .phone
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ZStack {
            Color.aabBg.ignoresSafeArea()
            if isRegistered {
                HomeView(phone: registeredPhone) {
                    // Logout: wipe SDK storage and go back to phone screen
                    TadSigning.logout()
                    registeredPhone = ""
                    isRegistered = false
                    step = .phone
                }
                .transition(.opacity)
            } else {
                switch step {
                case .phone:
                    PhoneView { phone in
                        step = .otp(phone: phone)
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                case .otp(let phone):
                    OTPView(phone: phone) {
                        registeredPhone = phone
                        isRegistered = TadSigning.isRegistered()
                    } onBack: {
                        step = .phone
                    }
                    .transition(.move(edge: .trailing))
                case .home:
                    EmptyView()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            LanguageToggle()
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .animation(.easeInOut(duration: 0.3), value: isRegistered)
        .onAppear {
            // On launch: if a phone is stored, restore SDK config and check registration.
            // If already registered → skip phone/SMS and go straight to home.
            if !registeredPhone.isEmpty {
                SDKConfig.setup(bankId: registeredPhone, language: loc.language)
                isRegistered = TadSigning.isRegistered()
            }
        }
    }
}

// MARK: - Language Toggle

private struct LanguageToggle: View {
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        Picker("", selection: $loc.language) {
            ForEach(AppLanguage.allCases) { lang in
                Text(lang.label).tag(lang)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 100)
        .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

// MARK: - Phone Screen

private struct PhoneView: View {
    let onContinue: (String) -> Void
    @State private var phone = ""
    @FocusState private var focused: Bool
    @EnvironmentObject private var loc: LocalizationManager

    private var formatted: String {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        var result = ""
        for (i, ch) in digits.prefix(9).enumerated() {
            if i == 2 || i == 5 || i == 7 { result += " " }
            result.append(ch)
        }
        return result
    }
    private var isValid: Bool { phone.filter(\.isNumber).count == 9 }

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
                                if phone.isEmpty {
                                    Text("XX XXX XX XX")
                                        .foregroundStyle(Color(.placeholderText))
                                }
                                TextField("", text: Binding(
                                    get: { formatted },
                                    set: { new in
                                        let digits = new.filter(\.isNumber)
                                        if digits.count <= 9 { phone = digits }
                                    }
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

                    AABButton(title: loc.t("Get SMS code"), enabled: isValid) {
                        onContinue("+998 \(formatted)")
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                Button(loc.t("Done")) { focused = false }
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - OTP Screen

private struct OTPView: View {
    let phone: String
    let onSuccess: () -> Void
    let onBack: () -> Void

    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var secondsLeft = 60
    @State private var timer: Timer?
    @FocusState private var focused: Bool
    @EnvironmentObject private var loc: LocalizationManager

    private var isValid: Bool { code.count == 6 }

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
            OTPBoxes(code: $code, focused: $focused)

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer().frame(height: 12)

            // Resend
            Group {
                if secondsLeft > 0 {
                    Text(loc.f("Resend in %d sec", secondsLeft))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button(loc.t("Resend")) { restartTimer() }
                        .font(.caption.bold())
                        .foregroundStyle(Color.aab)
                }
            }
            .padding(.bottom, 32)

            // Button
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .tint(Color.aab)
                        .frame(height: 50)
                } else {
                    AABButton(title: loc.t("Confirm and sign in"), enabled: isValid, action: verify)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.aabBg.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                Button(loc.t("Done")) { focused = false }
            }
        }
        .onAppear {
            focused = true
            restartTimer()
        }
        .onDisappear { timer?.invalidate() }
    }

    private func restartTimer() {
        secondsLeft = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if secondsLeft > 0 { secondsLeft -= 1 } else { t.invalidate() }
        }
    }

    private func verify() {
        isLoading = true
        errorMsg = ""
        SDKConfig.setup(bankId: phone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: ["otp": code])
            await MainActor.run {
                isLoading = false
                switch status {
                case .statusOk:
                    onSuccess()
                case .statusError(let msg, let ec):
                    errorMsg = ec == "USER_CANCELLED" ? loc.t("Cancelled") : loc.f("Error: %@", msg)
                }
            }
        }
    }
}

// MARK: - Home Screen

private struct HomeView: View {
    let phone: String
    let onSignOut: () -> Void

    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var jwt = ""
    @State private var showJWT = false
    @State private var showPayment = false
    @State private var isDeleting = false
    @State private var deleteMsg = ""
    @EnvironmentObject private var loc: LocalizationManager
    

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
                        if isLoading {
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
                            Button(action: signIn) {
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

                        if !errorMsg.isEmpty {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !jwt.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text(loc.t("Signed in successfully"))
                                        .font(.subheadline).bold()
                                    Spacer()
                                }
                                Divider()
                                Button(showJWT ? loc.t("Hide token") : loc.t("Show JWT")) {
                                    showJWT.toggle()
                                }
                                .font(.caption.bold())
                                .foregroundStyle(Color.aab)
                                if showJWT {
                                    Text(jwt)
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
                            Text(TadSigning.deviceId() ?? "none")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.center)
                        }
                        .onAppear { print("deviceId:", TadSigning.deviceId() ?? "none") }

                        // Sign out
                        Button(loc.t("Sign out"), action: onSignOut)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // TEST: delete the current registration from the server.
                        // On success the local session is wiped and we return to the
                        // register screen (next sign() will start a fresh registration).
                        if isDeleting {
                            ProgressView().tint(.red).padding(.top, 4)
                        } else {
                            Button("Delete registration from server", action: deleteFromServer)
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }
                        if !deleteMsg.isEmpty {
                            Text(deleteMsg)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.aabBg.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showPayment) {
                PaymentView(phone: phone)
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMsg = ""
        SDKConfig.setup(bankId: phone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: [:])
            await MainActor.run {
                isLoading = false
                switch status {
                case .statusOk:
                    jwt = "✓ Authenticated"
                    showPayment = true
                case .statusError(let msg, let code):
                    if code.hasPrefix("WEBAUTHN_") {
                        // Registration no longer valid on the server — the SDK already
                        // wiped the local session → send the user to re-register.
                        onSignOut()
                    } else {
                        errorMsg = loc.f("Sign in error: %@", msg)
                    }
                }
            }
        }
    }

    private func deleteFromServer() {
        isDeleting = true
        deleteMsg = ""
        Task {
            // bankId == the phone the app registered with (see SDKConfig.setup).
            let result = await RegistrationRemover.removeFromServer(bankId: phone)
            await MainActor.run {
                isDeleting = false
                if result.ok {
                    // Deleted on the server, but KEEP the local session so you can test:
                    // the next Sign in will hit the server, fail (WEBAUTHN_USER_NOT_FOUND),
                    // and route to registration.
                    deleteMsg = "Removed from server ✓ — now tap Sign in (it should fail → register)."
                } else {
                    deleteMsg = result.message
                }
            }
        }
    }
}

// MARK: - Payment Screen

private struct PaymentView: View {
    let phone: String

    @State private var payLoading = false
    @State private var paySuccess = ""
    @State private var payError = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)
                PaymentCardView(
                    isLoading: payLoading,
                    successMessage: paySuccess,
                    errorMessage: payError
                ) { toPhone, amount in
                    pay(toPhone: toPhone, amount: amount)
                }
                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.aabBg.ignoresSafeArea())
        .navigationTitle(loc.t("Transfer"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }

    private func pay(toPhone: String, amount: String) {
        payLoading = true
        paySuccess = ""
        payError = ""
        SDKConfig.setup(bankId: phone, language: loc.language)
        Task {
            let status = await TadSigning.sign(dto: [:])
            await MainActor.run {
                payLoading = false
                switch status {
                case .statusOk:
                    paySuccess = loc.f("Transfer %@ sum to %@ confirmed", amount, toPhone)
                case .statusError(let msg, let ec):
                    payError = ec == "USER_CANCELLED" ? loc.t("Cancelled") : loc.f("Error: %@", msg)
                }
            }
        }
    }
}

// MARK: - Payment Card

private struct PaymentCardView: View {
    let isLoading: Bool
    let successMessage: String
    let errorMessage: String
    let onPay: (String, String) -> Void

    @State private var phone = ""
    @State private var amount = ""
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var loc: LocalizationManager

    private enum Field { case phone, amount }

    private var formatted: String {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        var result = ""
        for (i, ch) in digits.prefix(9).enumerated() {
            if i == 2 || i == 5 || i == 7 { result += " " }
            result.append(ch)
        }
        return result
    }

    private var isValid: Bool {
        phone.filter(\.isNumber).count == 9 && !amount.isEmpty
    }

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
                        if phone.isEmpty {
                            Text("XX XXX XX XX")
                                .foregroundStyle(Color(.placeholderText))
                        }
                        TextField("", text: Binding(
                            get: { formatted },
                            set: { new in
                                let digits = new.filter(\.isNumber)
                                if digits.count <= 9 { phone = digits }
                            }
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
                    TextField("0", text: Binding(
                        get: { amount },
                        set: { new in amount = new.filter(\.isNumber) }
                    ))
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
            if isLoading {
                HStack {
                    ProgressView()
                    Text(loc.t("Confirming..."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            } else {
                AABButton(title: loc.t("Pay"), enabled: isValid) {
                    focusedField = nil
                    onPay("+998\(phone)", amount)
                }
            }

            if !successMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(successMessage).font(.caption).foregroundStyle(.green)
                }
            }
            if !errorMessage.isEmpty {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
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

// MARK: - OTP Boxes

private struct OTPBoxes: View {
    @Binding var code: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        ZStack {
            // Hidden real text field
            TextField("", text: Binding(
                get: { code },
                set: { new in
                    let d = new.filter(\.isNumber)
                    if d.count <= 6 { code = d }
                }
            ))
            .keyboardType(.numberPad)
            .focused(focused)
            .opacity(0)
            .frame(width: 1, height: 1)

            // Visual boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    let char: String = i < code.count
                        ? String(code[code.index(code.startIndex, offsetBy: i)])
                        : ""
                    let isActive = i == code.count

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isActive ? Color.aab : Color(.separator),
                                          lineWidth: isActive ? 2 : 1)
                            .background(Color.aabCard, in: RoundedRectangle(cornerRadius: 12))
                            .frame(width: 46, height: 56)
                        Text(char)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .onTapGesture { focused.wrappedValue = true }
    }
}

// MARK: - Shared Button

private struct AABButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    enabled ? Color.aab : Color.aab.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: enabled ? Color.aab.opacity(0.35) : .clear,
                        radius: 10, y: 4)
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

#Preview {
    ContentView()
}
