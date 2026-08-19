import SwiftUI

struct LanguageToggle: View {
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
