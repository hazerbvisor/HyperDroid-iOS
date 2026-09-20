import SwiftUI

struct HDExplorerView: View {
    @Environment(\.colorScheme) private var scheme
    @StateObject private var model = HDExplorerModel()

    @State private var showingNewFolder = false
    @State private var newFolderName = ""
    @State private var renameTarget: HDVFSItem?
    @State private var renameText = ""

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            topNavigation

            HStack(spacing: 0) {
                sideNavigation
                    .frame(width: 170)

                Rectangle()
                    .fill(p.border.opacity(0.8))
                    .frame(width: 1)

                contentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(p.explorer)
        .alert("New folder", isPresented: $showingNewFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                model.createFolder(named: newFolderName)
                newFolderName = ""
            }
        } message: {
            Text("Create a folder in \(model.addressText)")
        }
        .alert("Rename", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renameTarget = nil
            }
            Button("Rename") {
                if let target = renameTarget {
                    model.rename(target, to: renameText)
                }
                renameTarget = nil
            }
        }
        .onAppear {
            model.reload(forceProviderRefresh: true)
        }
    }

    private var topNavigation: some View {
        HStack(spacing: 6) {
            navButton(
                "ic_nav_arrow_left_18_regular",
                enabled: model.canGoBack,
                action: model.goBack
            )
            navButton(
                "ic_nav_arrow_right_18_regular",
                enabled: model.canGoForward,
                action: model.goForward
            )
            navButton(
                "ic_nav_arrow_up_24_regular",
                enabled: model.canGoUp,
                action: model.goUp
            )
            navButton(
                "ic_nav_arrow_reload_18",
                enabled: true,
                action: { model.reload(forceProviderRefresh: true) }
            )

            HStack(spacing: 8) {
                HDImage(name: addressIcon)
                    .frame(width: 18, height: 18)

                Text(model.addressText)
                    .font(.system(size: 13))
                    .foregroundColor(p.text)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(p.explorer.opacity(0.75))
            .overlay(Rectangle().stroke(p.border.opacity(0.7), lineWidth: 1))
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                HDImage(
                    name: "ic_search_14_regular",
                    template: true,
                    tint: p.text
                )
                .frame(width: 14, height: 14)

                TextField("Search", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(p.text)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(p.explorer.opacity(0.75))
            .overlay(Rectangle().stroke(p.border.opacity(0.7), lineWidth: 1))
            .frame(width: 210)

            if case .folder(_) = model.location {
                Button {
                    newFolderName = "New folder"
                    showingNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 15))
                        .foregroundColor(p.text)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .hdCursor(.hand)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(p.dialogBody)
    }

    private var addressIcon: String {
        switch model.location {
        case .home: return "img_nav_desktop"
        case .folder: return "img_folder_sm"
        }
    }

    private func navButton(
        _ asset: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HDImage(name: asset, template: true, tint: p.text)
                .frame(width: 18, height: 18)
                .frame(width: 32, height: 32)
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .hdCursor(enabled ? .hand : .arrow)
    }

    private var sideNavigation: some View {
        VStack(alignment: .leading, spacing: 2) {
            sideRow(
                "Home",
                "img_nav_desktop",
                selected: model.location == .home
            ) {
                model.openHome()
            }

            ForEach(model.homeFolders, id: \.0) { folder in
                sideRow(
                    folder.0,
                    sideAsset(for: folder.0),
                    selected: isCurrentPath(folder.2)
                ) {
                    model.openPath(folder.2)
                }
            }

            Divider()
                .overlay(p.border)
                .padding(.vertical, 4)

            sideRow(
                "Local Disk (C:)",
                "img_drive",
                selected: isCurrentPath("C:\\")
            ) {
                model.openPath("C:\\")
            }

            Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 2)
        .background(p.dialogBody)
    }

    private func sideAsset(for title: String) -> String {
        switch title {
        case "Desktop": return "img_folder_sm"
        case "Documents": return "img_folder_documents_sm"
        case "Downloads": return "img_folder_downloads_sm"
        case "Pictures": return "img_folder_images_sm"
        case "Music": return "img_folder_music_sm"
        case "Videos": return "img_folder_videos_sm"
        default: return "img_folder_sm"
        }
    }

    private func sideRow(
        _ title: String,
        _ asset: String,
        selected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                HDImage(name: asset)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(p.text)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 31)
            .background(
                selected
                    ? Color.white.opacity(scheme == .dark ? 0.08 : 0.55)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hdCursor(.hand)
    }

    @ViewBuilder
    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let error = model.errorMessage {
                    errorBanner(error)
                }

                switch model.location {
                case .home:
                    homeContent
                case .folder:
                    folderContent
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(p.explorer)
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Folders")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 165), spacing: 8)],
                spacing: 8
            ) {
                ForEach(model.homeFolders, id: \.0) { folder in
                    Button {
                        model.openPath(folder.2)
                    } label: {
                        HStack(spacing: 7) {
                            HDImage(name: folder.1)
                                .frame(width: 46, height: 46)

                            Text(folder.0)
                                .font(.system(size: 12))
                                .foregroundColor(p.text)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(minHeight: 54)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hdCursor(.hand)
                }
            }

            sectionTitle("Devices and drives")
                .padding(.top, 4)

            driveRow
        }
    }

    private var folderContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle(model.addressText)
                Spacer()
                Text("\(model.visibleItems.count) item\(model.visibleItems.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(p.mutedText)
            }

            if model.visibleItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: model.searchText.isEmpty ? "folder" : "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(p.mutedText)

                    Text(model.searchText.isEmpty ? "This folder is empty" : "No matching items")
                        .font(.system(size: 13))
                        .foregroundColor(p.mutedText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 70)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(model.visibleItems) { item in
                        itemTile(item)
                    }
                }
            }
        }
    }

    private func itemTile(_ item: HDVFSItem) -> some View {
        Button {
            model.open(item)
        } label: {
            HStack(spacing: 8) {
                itemIcon(item)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12))
                        .foregroundColor(p.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !item.isDirectory {
                        Text(ByteCountFormatter.string(
                            fromByteCount: Int64(item.size),
                            countStyle: .file
                        ))
                        .font(.system(size: 10))
                        .foregroundColor(p.mutedText)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
            .background(Color.white.opacity(0.001))
        }
        .buttonStyle(.plain)
        .hdCursor(item.isDirectory ? .hand : .arrow)
        .contextMenu {
            if item.isDirectory {
                Button("Open") {
                    model.open(item)
                }
            }

            Button("Rename") {
                renameTarget = item
                renameText = item.name
            }

            if let url = model.hostURL(for: item) {
                ShareLink(item: url) {
                    Text("Share")
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                model.delete(item)
            }
        }
    }

    @ViewBuilder
    private func itemIcon(_ item: HDVFSItem) -> some View {
        if item.isDirectory {
            HDImage(name: "img_folder_sm")
        } else {
            Image(systemName: systemIcon(for: item.name))
                .resizable()
                .scaledToFit()
                .padding(5)
                .foregroundColor(p.primary)
        }
    }

    private func systemIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "exe", "msi": return "shippingbox"
        case "dll": return "puzzlepiece.extension"
        case "txt", "log", "ini", "cfg": return "doc.text"
        case "png", "jpg", "jpeg", "webp", "bmp": return "photo"
        case "mp3", "wav", "ogg": return "music.note"
        case "mp4", "mov", "avi", "mkv": return "film"
        case "zip", "7z", "rar": return "archivebox"
        default: return "doc"
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(p.text)
    }

    private var driveRow: some View {
        Button {
            model.openPath("C:\\")
        } label: {
            HStack(spacing: 8) {
                HDImage(name: "img_drive")
                    .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(model.driveInfo?.name ?? "Local Disk") (C:)")
                        .font(.system(size: 13))
                        .foregroundColor(p.text)

                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))

                            Rectangle()
                                .fill(p.primary)
                                .frame(
                                    width: g.size.width * CGFloat(model.driveInfo?.usedFraction ?? 0)
                                )
                        }
                    }
                    .frame(height: 12)

                    Text(driveCapacityText)
                        .font(.system(size: 11))
                        .foregroundColor(p.mutedText)
                }
                .frame(width: 220)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: 300)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hdCursor(.hand)
    }

    private var driveCapacityText: String {
        guard let info = model.driveInfo,
              info.totalBytes > 0 else {
            return "Virtual Windows drive"
        }

        let free = ByteCountFormatter.string(
            fromByteCount: Int64(info.freeBytes),
            countStyle: .file
        )
        let total = ByteCountFormatter.string(
            fromByteCount: Int64(info.totalBytes),
            countStyle: .file
        )
        return "\(free) free of \(total)"
    }

    private func errorBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
            Text(text)
                .font(.system(size: 11))
                .lineLimit(3)
            Spacer()
            Button {
                model.reload(forceProviderRefresh: true)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(.orange)
        .padding(8)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func isCurrentPath(_ path: String) -> Bool {
        guard case .folder(let current) = model.location else { return false }
        return HDHostMappedFileSystemProvider
            .normalizeVirtualPath(current)
            .caseInsensitiveCompare(
                HDHostMappedFileSystemProvider.normalizeVirtualPath(path)
            ) == .orderedSame
    }
}
