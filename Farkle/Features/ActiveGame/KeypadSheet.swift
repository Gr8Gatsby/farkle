import SwiftUI

struct KeypadSheet: View {
    var initial: Int
    var onAdd: (Int) -> Void
    var onCancel: () -> Void

    @State private var entry: String = ""

    private var value: Int { Int(entry) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.walnut.opacity(0.25)).frame(width: 40, height: 4)
                .padding(.top, 8)
            HStack {
                (
                    Text("Custom ").font(.display(28)).foregroundStyle(Color.ink) +
                    Text("amount").font(.display(28, italic: true)).foregroundStyle(Color.walnut)
                )
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("+")
                    .font(.display(40))
                    .foregroundStyle(Color.ink3)
                Text(value == 0 ? "0" : value.formatted())
                    .font(.display(64))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            let keys = ["1","2","3","4","5","6","7","8","9","0","00","⌫"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(keys, id: \.self) { key in
                    keyButton(key)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            HStack(spacing: 10) {
                Button("Cancel") { onCancel() }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                    )
                    .font(.ui(14, weight: .semibold))
                Button {
                    onAdd(value)
                } label: { Text("Add to turn") }
                .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                .disabled(value <= 0)
                .opacity(value <= 0 ? 0.5 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .onAppear { if initial > 0 { entry = String(initial) } }
    }

    private func keyButton(_ key: String) -> some View {
        Button {
            switch key {
            case "⌫": if !entry.isEmpty { entry.removeLast() }
            default:
                let candidate = entry + key
                if let n = Int(candidate), n <= 99_999 {
                    entry = candidate.hasPrefix("0") && candidate.count > 1
                        ? String(Int(candidate) ?? 0)
                        : candidate
                }
            }
        } label: {
            Text(key)
                .font(.mono(24, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.paperSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
