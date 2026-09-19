import SwiftUI

struct HDSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var page = "Personalize"
    private var p: HDPalette { HDPalette(scheme: scheme) }

    private let pages = ["System", "Bluetooth & devices", "Personalize", "Apps", "Accounts", "Time & language", "Privacy & security", "PC Updates"]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                navigation
                    .frame(width: geo.size.width * 0.25)

                content
                    .frame(width: geo.size.width * 0.75)
            }
        }
    }

    private var navigation: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    HDImage(name: "img_user_default")
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Name").font(.system(size: 14, weight: .semibold))
                        Text("Local Account").font(.system(size: 11.5))
                    }
                    Spacer()
                }
                .foregroundColor(p.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .padding(.bottom, 10)

                VStack(spacing: 6) {
                    ForEach(pages, id: \.self) { item in
                        Button { page = item } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(item == page ? p.primary : p.mutedText.opacity(0.55))
                                    .frame(width: 6, height: 6)
                                Text(item)
                                    .font(.system(size: 14.6))
                                    .foregroundColor(p.text)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(item == page ? Color.white.opacity(scheme == .dark ? 0.08 : 0.50) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 40)
            }
        }
        .background(p.dialogBody)
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack {
                Text(page)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(p.text)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)

            ScrollView {
                if page == "Personalize" {
                    personalize
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        settingsCard(
                            title: page,
                            subtitle: "This Android settings page is queued for direct UI translation.",
                            asset: "ic_image_24_regular"
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.dialog)
    }

    private var personalize: some View {
        VStack(spacing: 3.2) {
            settingsCard(title: "Background", subtitle: "Background image, color, slideshow", asset: "ic_image_24_regular")
            settingsCard(title: "Colors", subtitle: "Accent color, transparency effects, color theme", asset: "ic_color_26_regular")
            settingsCard(title: "Start", subtitle: "Config StartMenu pattern and layout", asset: "ic_start_menu_24_regular")
            settingsCard(title: "Taskbar", subtitle: "Taskbar behaviours, system pins", asset: "ic_taskbar_24_regular")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 26)
    }

    private func settingsCard(title: String, subtitle: String, asset: String) -> some View {
        HStack(spacing: 12) {
            HDImage(name: asset, template: true, tint: p.text)
                .frame(width: 24, height: 24)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(p.text)
                Text(subtitle).font(.system(size: 11)).foregroundColor(p.mutedText)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 56)
        .background(p.dialogBody)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(p.border.opacity(0.55), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
