import SwiftUI

struct AABButton: View {
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
