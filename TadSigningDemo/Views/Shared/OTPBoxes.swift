import SwiftUI

struct OTPBoxes: View {
    let code: String
    let onChange: (String) -> Void
    var focused: FocusState<Bool>.Binding

    var body: some View {
        ZStack {
            // Hidden real text field
            TextField("", text: Binding(
                get: { code },
                set: { onChange($0) }
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
