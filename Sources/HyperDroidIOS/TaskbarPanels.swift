import SwiftUI

struct HDActionCenterView: View {
    let onOpenSettings: () -> Void
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hd.volume") private var volume = 0.50
    @AppStorage("hd.bluetooth") private var bluetooth = true
    @AppStorage("hd.nearbySharing") private var nearbySharing = true
    @AppStorage("hd.webAccess") private var webAccess = true
    @AppStorage("hd.theme") private var theme = "Dark"
    @State private var accessibility = false
    private var p: HDPalette { HDPalette(scheme: scheme) }

    private let items: [(String, String)] = [
        ("Wi-Fi", "menu_ic_wifi_4_20_regular"),
        ("Internet", "menu_ic_internet_20_regular"),
        ("Bluetooth", "menu_ic_bluetooth_20_regular"),
        ("Nearby sharing", "menu_ic_share_20_regular"),
        ("Theme", "menu_ic_theme_current_20_regular"),
        ("Accessibility", "menu_ic_accessibility_20_regular")
    ]

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(items, id: \.0) { item in
                    VStack(spacing: 6) {
                        Button {
                            toggle(item.0)
                        } label: {
                            HDImage(name: item.1, template: true, tint: isEnabled(item.0) ? .white : p.text)
                                .frame(width: 20, height: 20)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(isEnabled(item.0) ? p.primary : p.dialogBody)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.border.opacity(0.45), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Text(item.0)
                            .font(.system(size: 11))
                            .foregroundColor(p.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .padding(20)

            HStack(spacing: 14) {
                HDImage(name: "ui_tb_speaker_2_24_regular", template: true, tint: p.text)
                    .frame(width: 20, height: 20)
                Slider(value: $volume, in: 0...1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            HStack {
                HStack(spacing: 6) {
                    HDImage(name: "ui_tb_battery_10_24", template: true, tint: p.text)
                        .frame(width: 20, height: 20)
                    Text("97%").font(.system(size: 11.5))
                }
                Spacer()
                Button(action: onOpenSettings) {
                    HDImage(name: "ic_settings_24_regular", template: true, tint: p.text)
                        .frame(width: 20, height: 20)
                        .frame(width: 38, height: 36)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(p.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(p.footer)
        }
        .frame(width: 330)
        .background(p.startMenu)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(p.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
    }

    private func isEnabled(_ item: String) -> Bool {
        switch item {
        case "Wi-Fi", "Internet": return webAccess
        case "Bluetooth": return bluetooth
        case "Nearby sharing": return nearbySharing
        case "Theme": return theme == "Dark"
        case "Accessibility": return accessibility
        default: return false
        }
    }

    private func toggle(_ item: String) {
        switch item {
        case "Wi-Fi", "Internet": webAccess.toggle()
        case "Bluetooth": bluetooth.toggle()
        case "Nearby sharing": nearbySharing.toggle()
        case "Theme": theme = theme == "Dark" ? "Light" : "Dark"
        case "Accessibility": accessibility.toggle()
        default: break
        }
    }
}

struct HDCalendarPanelView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var date = Date()
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 14))
                    .foregroundColor(p.text)
                Spacer()
                HDImage(name: "ic_arrow_down_14_light", template: true, tint: p.text)
                    .frame(width: 14, height: 14)
                    .frame(width: 26, height: 26)
                    .background(p.dialogBody)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(p.footer)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(width: 340)
        .background(p.startMenu)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(p.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
    }
}

struct HDMoreIconsPanelView: View {
    let onOpenInstaller: () -> Void
    @Environment(\.colorScheme) private var scheme
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        HStack(spacing: 0) {
            popupButton("img_defender", action: {})
            popupButton("img_mouse", action: {})
            popupButton("img_file_apk", action: onOpenInstaller)
        }
        .padding(4)
        .background(p.startMenu)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(p.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    private func popupButton(_ asset: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HDImage(name: asset)
                .frame(width: 22, height: 22)
                .frame(width: 42, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
