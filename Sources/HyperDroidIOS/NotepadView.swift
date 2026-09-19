import SwiftUI

struct HDNotepadView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var text = ""
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                menuButton("File")
                menuButton("Edit")
                Spacer()
            }
            .background(p.footer)

            TextEditor(text: $text)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(p.text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .background(p.dialogBody)

            HStack {
                Text("Ln 1, Col 1")
                Spacer()
                Text("100%")
                Text("Windows (CRLF)")
                Text("UTF-8")
            }
            .font(.system(size: 10.5))
            .foregroundColor(p.mutedText)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(p.footer)
        }
    }

    private func menuButton(_ title: String) -> some View {
        Button(action: {}) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(p.text)
                .padding(.leading, 9)
                .padding(.trailing, 18)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }
}
