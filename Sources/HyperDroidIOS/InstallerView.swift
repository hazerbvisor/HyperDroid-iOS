import SwiftUI

struct HDInstallerView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var appName = ""
    @State private var url = ""
    @State private var autoIcon = true
    @State private var shortcut = true
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("App name", text: $appName)
                            .font(.system(size: 28))
                            .foregroundColor(p.text)
                            .padding(.bottom, 10)
                            .padding(.trailing, 128)

                        TextField("Website URL", text: $url)
                            .font(.system(size: 15))
                            .foregroundColor(p.text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(p.dialogBody)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(.trailing, 128)

                        Toggle("Detect icon automatically", isOn: $autoIcon)
                            .toggleStyle(HDCheckboxToggleStyle())
                            .font(.system(size: 14))
                            .foregroundColor(p.text)
                            .padding(.top, 2)

                        Text("Capabilities")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(p.text)
                            .padding(.top, 10)

                        Text("This app can access web content, open links and use supported HyperDroid desktop integrations.")
                            .font(.system(size: 14))
                            .foregroundColor(p.mutedText)
                            .lineSpacing(4)
                    }

                    Button(action: {}) {
                        HDImage(name: "img_app_photos")
                            .frame(width: 64, height: 64)
                            .padding(18)
                            .frame(width: 100, height: 100)
                            .background(p.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 28)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }

            HStack {
                Toggle("Create desktop shortcut", isOn: $shortcut)
                    .toggleStyle(HDCheckboxToggleStyle())
                    .font(.system(size: 13))
                    .foregroundColor(p.text)
                Spacer()
                Button("Install", action: {})
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 18)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(p.footer)
        }
    }
}

struct HDCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.secondary, lineWidth: 1)
                        .frame(width: 18, height: 18)
                    if configuration.isOn {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.0, green: 0.47, blue: 0.84))
                            .frame(width: 18, height: 18)
                        Text("✓").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
