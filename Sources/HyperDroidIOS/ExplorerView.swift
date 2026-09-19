import SwiftUI

struct HDExplorerView: View {
    @Environment(\.colorScheme) private var scheme
    private var p: HDPalette { HDPalette(scheme: scheme) }

    private let folders: [(String, String)] = [
        ("Desktop", "img_folder_sm"),
        ("Documents", "img_folder_documents"),
        ("Downloads", "img_folder_downloads"),
        ("Music", "img_folder_music"),
        ("Pictures", "img_folder_images"),
        ("Videos", "img_folder_videos")
    ]

    var body: some View {
        VStack(spacing: 0) {
            topNavigation
            HStack(spacing: 0) {
                sideNavigation
                    .frame(width: 160)
                Rectangle().fill(p.border.opacity(0.8)).frame(width: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Folders")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(p.text)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], spacing: 8) {
                            ForEach(folders, id: \.0) { folder in
                                HStack(spacing: 6) {
                                    HDImage(name: folder.1).frame(width: 46, height: 46)
                                    Text(folder.0)
                                        .font(.system(size: 12))
                                        .foregroundColor(p.text)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(minHeight: 54)
                            }
                        }

                        Text("Devices and drives")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(p.text)
                            .padding(.top, 4)

                        driveRow
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(p.explorer)
            }
        }
        .background(p.explorer)
    }

    private var topNavigation: some View {
        HStack(spacing: 6) {
            navButton("ic_nav_arrow_left_18_regular")
            navButton("ic_nav_arrow_right_18_regular")
            navButton("ic_nav_arrow_up_24_regular")
            navButton("ic_nav_arrow_reload_18")

            HStack(spacing: 8) {
                HDImage(name: "img_nav_desktop").frame(width: 18, height: 18)
                Text("›  Home")
                    .font(.system(size: 13))
                    .foregroundColor(p.text)
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(p.explorer.opacity(0.75))
            .overlay(Rectangle().stroke(p.border.opacity(0.7), lineWidth: 1))
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                HDImage(name: "ic_search_14_regular", template: true, tint: p.text).frame(width: 14, height: 14)
                Text("Search").font(.system(size: 13)).foregroundColor(p.mutedText)
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(p.explorer.opacity(0.75))
            .overlay(Rectangle().stroke(p.border.opacity(0.7), lineWidth: 1))
            .frame(width: 190)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(p.dialogBody)
    }

    private func navButton(_ asset: String) -> some View {
        Button(action: {}) {
            HDImage(name: asset, template: true, tint: p.text)
                .frame(width: 18, height: 18)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    private var sideNavigation: some View {
        VStack(alignment: .leading, spacing: 2) {
            sideRow("Home", "img_nav_desktop", selected: true)
            sideRow("Desktop", "img_folder_sm")
            sideRow("Documents", "img_folder_documents_sm")
            sideRow("Downloads", "img_folder_downloads_sm")
            sideRow("Pictures", "img_folder_images_sm")
            sideRow("Music", "img_folder_music_sm")
            sideRow("Videos", "img_folder_videos_sm")
            Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 2)
        .background(p.dialogBody)
    }

    private func sideRow(_ title: String, _ asset: String, selected: Bool = false) -> some View {
        HStack(spacing: 8) {
            HDImage(name: asset).frame(width: 20, height: 20)
            Text(title).font(.system(size: 12)).foregroundColor(p.text)
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 31)
        .background(selected ? Color.white.opacity(scheme == .dark ? 0.08 : 0.55) : Color.clear)
    }

    private var driveRow: some View {
        HStack(spacing: 6) {
            HDImage(name: "img_drive").frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("Local Disk (C:)").font(.system(size: 13)).foregroundColor(p.text)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.gray.opacity(0.25))
                        Rectangle().fill(p.primary).frame(width: g.size.width * 0.40)
                    }
                }.frame(height: 12)
                Text("50 GB free of 100 GB").font(.system(size: 11)).foregroundColor(p.mutedText)
            }
            .frame(width: 190)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: 280)
    }
}
