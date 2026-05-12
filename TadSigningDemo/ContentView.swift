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
        .animation(.easeInOut(duration: 0.3), value: isRegistered)
        .onAppear {
            // On launch: if a phone is stored, restore SDK config and check registration.
            // If already registered → skip phone/SMS and go straight to home.
            if !registeredPhone.isEmpty {
                SDKConfig.setup(bankId: registeredPhone)
                isRegistered = TadSigning.isRegistered()
            }
        }
    }
}

// MARK: - Phone Screen

private struct PhoneView: View {
    let onContinue: (String) -> Void
    @State private var phone = ""
    @FocusState private var focused: Bool

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
                        Text("Добро пожаловать")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer().frame(height: 24)
                }

                // Card
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Номер телефона")
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

                    Text("Для первого входа мы отправим SMS-код. В дальнейшем вход — только по Face ID.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    AABButton(title: "Получить SMS-код", enabled: isValid) {
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
//                Button("Готово") { focused = false }
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
                Text("Введите код")
                    .font(.title2).bold()
                Text("Код отправлен на \(phone)")
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
                    Text("Отправить повторно через \(secondsLeft) сек")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Отправить повторно") { restartTimer() }
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
                    AABButton(title: "Подтвердить и войти", enabled: isValid, action: verify)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.aabBg.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                Button("Готово") { focused = false }
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
        SDKConfig.setup(bankId: phone)
        Task {
            let status = await TadSigning.sign(dto: ["otp": code])
            await MainActor.run {
                isLoading = false
                switch status {
                case .statusOk:
                    onSuccess()
                case .statusError(let msg, let ec):
                    errorMsg = ec == "USER_CANCELLED" ? "Отменено" : "Ошибка: \(msg)"
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
    @State private var jwt = ""
    @State private var errorMsg = ""
    @State private var showJWT = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack(alignment: .bottom) {
                Color.aab.ignoresSafeArea(edges: .top)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AnyOtherBank")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Добро пожаловать!")
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
            .frame(height: 180)

            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 8)

                    // Passkey info card
                    HStack(spacing: 16) {
                        Image(systemName: "faceid")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.aab)
                            .frame(width: 56, height: 56)
                            .background(Color.aab.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Биометрический вход")
                                .font(.subheadline).bold()
                            Text("SMS больше не нужен. Входите по Face ID за одно касание.")
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
                            Text("Проверка...")
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
                                Text("Войти по Face ID")
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

                    // JWT result
                    if !jwt.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Вход выполнен успешно")
                                    .font(.subheadline).bold()
                                Spacer()
                            }
                            Divider()
                            Button(showJWT ? "Скрыть токен" : "Показать JWT") {
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

                    // Sign out
                    Button("Выйти из аккаунта", action: onSignOut)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.aabBg.ignoresSafeArea())
    }

    private func signIn() {
        isLoading = true
        jwt = ""
        errorMsg = ""
        SDKConfig.setup(bankId: phone)
        Task {
            let status = await TadSigning.sign(dto: [:])
            await MainActor.run {
                isLoading = false
                switch status {
                case .statusOk:
                    jwt = "✓ Authenticated"
                case .statusError(let msg, _):
                    errorMsg = "Ошибка входа: \(msg)"
                }
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
