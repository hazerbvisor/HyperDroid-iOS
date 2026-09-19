import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HDSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var page = "Personalize"
    @State private var updateMessage = ""
    @State private var importingCursorPack = false
    @State private var cursorImportMessage = ""
    @ObservedObject private var cursorPack = HDCursorPackManager.shared
    @AppStorage("hd.settingsRequestedPage") private var requestedPage = "Personalize"

    @AppStorage("hd.theme") private var theme = "Dark"
    @AppStorage("hd.transparency") private var transparency = true
    @AppStorage("hd.backgroundStyle") private var backgroundStyle = "Black"
    @AppStorage("hd.accentColor") private var accentColor = "Blue"

    @AppStorage("hd.startShowSearch") private var startShowSearch = true
    @AppStorage("hd.startShowRecommended") private var startShowRecommended = true
    @AppStorage("hd.startCompact") private var startCompact = false
    @AppStorage("hd.startColumns") private var startColumns = "Default"
    @AppStorage("hd.startSearchFocus") private var startSearchFocus = false

    @AppStorage("hd.taskbarAlignment") private var taskbarAlignment = "Center"
    @AppStorage("hd.taskbarShowWidgets") private var taskbarShowWidgets = true
    @AppStorage("hd.taskbarSearchMode") private var taskbarSearchMode = "Search box"
    @AppStorage("hd.taskbarShowClock") private var taskbarShowClock = true
    @AppStorage("hd.taskbarShowSeconds") private var taskbarShowSeconds = false
    @AppStorage("hd.taskbarAutoHide") private var taskbarAutoHide = false

    @AppStorage("hd.displayScale") private var displayScale = 100.0
    @AppStorage("hd.nightLight") private var nightLight = false
    @AppStorage("hd.notifications") private var notifications = true
    @AppStorage("hd.multitasking") private var multitasking = true
    @AppStorage("hd.volume") private var volume = 0.50

    @AppStorage("hd.bluetooth") private var bluetooth = true
    @AppStorage("hd.discoverable") private var discoverable = false
    @AppStorage("hd.nearbySharing") private var nearbySharing = true
    @AppStorage("hd.pointerSpeed") private var pointerSpeed = 0.50
    @AppStorage("hd.naturalScrolling") private var naturalScrolling = true
    @AppStorage("hd.cursorStyle") private var cursorStyle = "iPadOS"

    @AppStorage("hd.defaultBrowser") private var defaultBrowser = "HyperDroid Browser"
    @AppStorage("hd.allowBackgroundApps") private var allowBackgroundApps = true
    @AppStorage("hd.allowWebApps") private var allowWebApps = true
    @AppStorage("hd.restoreApps") private var restoreApps = true

    @AppStorage("hd.accountName") private var accountName = "Name"
    @AppStorage("hd.syncSettings") private var syncSettings = true
    @AppStorage("hd.signInMode") private var signInMode = "Local account"

    @AppStorage("hd.language") private var language = "English"
    @AppStorage("hd.use24Hour") private var use24Hour = false
    @AppStorage("hd.firstDay") private var firstDay = "Sunday"
    @AppStorage("hd.region") private var region = "Malaysia"

    @AppStorage("hd.webAccess") private var webAccess = true
    @AppStorage("hd.fileAccess") private var fileAccess = true
    @AppStorage("hd.clipboardAccess") private var clipboardAccess = true
    @AppStorage("hd.diagnostics") private var diagnostics = false
    @AppStorage("hd.tracking") private var tracking = false

    @AppStorage("hd.autoUpdate") private var autoUpdate = true
    @AppStorage("hd.updateChannel") private var updateChannel = "Stable"
    @AppStorage("hd.lastUpdateCheck") private var lastUpdateCheck = 0.0

    private var p: HDPalette { HDPalette(scheme: scheme) }

    private let pages = [
        "System",
        "Bluetooth & devices",
        "Personalize",
        "Apps",
        "Accounts",
        "Time & language",
        "Privacy & security",
        "PC Updates"
    ]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                navigation
                    .frame(width: geo.size.width * 0.25)

                content
                    .frame(width: geo.size.width * 0.75)
            }
        }
        .onAppear {
            if pages.contains(requestedPage) {
                page = requestedPage
            }
        }
        .onChange(of: requestedPage) { value in
            if pages.contains(value) {
                page = value
            }
        }
        .fileImporter(
            isPresented: $importingCursorPack,
            allowedContentTypes: [UTType(filenameExtension: "cur") ?? .data],
            allowsMultipleSelection: true
        ) { result in
            handleCursorImport(result)
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
                        Text(accountName.isEmpty ? "Name" : accountName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(signInMode)
                            .font(.system(size: 11.5))
                    }

                    Spacer()
                }
                .foregroundColor(p.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .padding(.bottom, 10)

                VStack(spacing: 6) {
                    ForEach(pages, id: \.self) { item in
                        Button {
                            withAnimation(.easeOut(duration: 0.14)) {
                                page = item
                                requestedPage = item
                            }
                        } label: {
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
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 12)

            ScrollView {
                Group {
                    switch page {
                    case "System": systemPage
                    case "Bluetooth & devices": devicesPage
                    case "Personalize": personalizePage
                    case "Apps": appsPage
                    case "Accounts": accountsPage
                    case "Time & language": timeLanguagePage
                    case "Privacy & security": privacyPage
                    case "PC Updates": updatesPage
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.dialog)
    }

    private var systemPage: some View {
        settingsStack {
            settingsSection("Display") {
                sliderRow(
                    "Scale",
                    subtitle: "Change the size of HyperDroid windows and desktop UI",
                    value: $displayScale,
                    range: 80...125,
                    suffix: "%"
                )
                toggleRow("Night light", subtitle: "Use a warmer desktop appearance", value: $nightLight)
            }

            settingsSection("Sound") {
                systemVolumeRow
            }

            settingsSection("Notifications") {
                toggleRow("Notifications", subtitle: "Allow HyperDroid notifications and badges", value: $notifications)
                toggleRow("Multitasking", subtitle: "Allow multiple desktop windows at the same time", value: $multitasking)
            }
        }
    }

    private var devicesPage: some View {
        settingsStack {
            actionRow("Add device", subtitle: "Open the device setup options available to HyperDroid") {
                discoverable = true
                updateMessage = "HyperDroid is ready to discover supported devices"
            }

            settingsSection("Bluetooth & devices") {
                toggleRow("Bluetooth", subtitle: "HyperDroid Bluetooth integration state", value: $bluetooth)
                infoRow("Mouse", value: naturalScrolling ? "Natural scrolling" : "Standard scrolling")
                infoRow("Printer", value: "AirPrint / iPadOS")
            }

            settingsSection("Mouse") {
                pickerRow(
                    "Cursor style",
                    subtitle: "Use the native iPad pointer or an imported Windows 11 cursor pack",
                    selection: $cursorStyle,
                    values: ["iPadOS", "Windows 11"]
                )

                sliderRow(
                    "Pointer speed",
                    subtitle: "Pointer movement preference for HyperDroid",
                    value: $pointerSpeed,
                    range: 0...1,
                    suffix: ""
                )

                toggleRow(
                    "Natural scrolling",
                    subtitle: "Use natural scrolling preference",
                    value: $naturalScrolling
                )

                infoRow(
                    "Windows 11 cursor pack",
                    value: cursorPack.hasUsablePack
                        ? "\(cursorPack.installedCount)/\(HDCursorKind.allCases.count) cursors"
                        : "Not imported"
                )
            }

            actionRow(
                "Download Windows 11 cursor pack",
                subtitle: "Open the jepriCreations-compatible cursor repository"
            ) {
                if let url = URL(string: "https://github.com/SullensCR/Windows-11-Hdpi-Tail-Cursor-Concept-by-jepriCreations") {
                    UIApplication.shared.open(url)
                }
            }

            actionRow(
                "Import .cur files",
                subtitle: "Select arrow.cur, hand.cur, ibeam.cur and the resize cursors from the extracted pack"
            ) {
                importingCursorPack = true
            }

            if cursorPack.hasUsablePack {
                actionRow(
                    "Remove imported cursor pack",
                    subtitle: "Return HyperDroid to the native iPadOS pointer"
                ) {
                    do {
                        try cursorPack.clearImportedPack()
                        cursorStyle = "iPadOS"
                        cursorImportMessage = "Imported cursor pack removed"
                    } catch {
                        cursorImportMessage = error.localizedDescription
                    }
                }
            }

            if !cursorImportMessage.isEmpty {
                settingsSection("Cursor pack status") {
                    infoRow("Status", value: cursorImportMessage)
                }
            }

            settingsSection("Sharing") {
                toggleRow("Nearby sharing", subtitle: "Enable HyperDroid nearby-sharing actions", value: $nearbySharing)
            }
        }
    }

    private var personalizePage: some View {
        settingsStack {
            settingsSection("Background") {
                pickerRow(
                    "Desktop background",
                    subtitle: "Choose the HyperDroid desktop background",
                    selection: $backgroundStyle,
                    values: ["Black", "Windows Blue", "Gradient"]
                )
            }

            settingsSection("Colors") {
                pickerRow(
                    "Theme",
                    subtitle: "Choose light, dark, or follow iPad appearance",
                    selection: $theme,
                    values: ["Dark", "Light", "System"]
                )
                pickerRow(
                    "Accent color",
                    subtitle: "Accent used for selections and active indicators",
                    selection: $accentColor,
                    values: ["Blue", "Purple", "Green", "Orange"]
                )
                toggleRow("Transparency effects", subtitle: "Use translucent Start, taskbar and popups", value: $transparency)
            }

            settingsSection("Start") {
                pickerRow(
                    "Start layout",
                    subtitle: "Match the original 4-column, default, or 6-column Start layout",
                    selection: $startColumns,
                    values: ["4 columns", "Default", "6 columns"]
                )
                toggleRow("Show search", subtitle: "Show the search box in Start", value: $startShowSearch)
                toggleRow("Focus search on open", subtitle: "Put the cursor in Start search as soon as Start opens", value: $startSearchFocus)
                toggleRow("Show Recommended", subtitle: "Show the Recommended area in Start", value: $startShowRecommended)
                toggleRow("Compact Start", subtitle: "Use a shorter Start menu", value: $startCompact)
            }

            settingsSection("Taskbar") {
                pickerRow(
                    "Taskbar alignment",
                    subtitle: "Position Start and app icons",
                    selection: $taskbarAlignment,
                    values: ["Center", "Left"]
                )
                toggleRow("Widgets", subtitle: "Show the Widgets button", value: $taskbarShowWidgets)
                pickerRow(
                    "Search",
                    subtitle: "Choose the original Search box, Search icon, or hide Search",
                    selection: $taskbarSearchMode,
                    values: ["Search box", "Search icon", "Hidden"]
                )
                toggleRow("Clock", subtitle: "Show time and date in the system tray", value: $taskbarShowClock)
                toggleRow("Seconds", subtitle: "Show seconds in the taskbar clock", value: $taskbarShowSeconds)
                toggleRow("Automatically hide", subtitle: "Hide the taskbar while desktop apps are active", value: $taskbarAutoHide)
            }
        }
    }

    private var appsPage: some View {
        settingsStack {
            settingsSection("Default apps") {
                pickerRow(
                    "Web browser",
                    subtitle: "Choose how HyperDroid opens web links",
                    selection: $defaultBrowser,
                    values: ["HyperDroid Browser", "External browser"]
                )
            }

            settingsSection("App behavior") {
                toggleRow("Web apps", subtitle: "Allow installed HyperDroid web apps", value: $allowWebApps)
                toggleRow("Background apps", subtitle: "Allow HyperDroid apps to remain active behind other windows", value: $allowBackgroundApps)
                toggleRow("Restore apps", subtitle: "Remember open desktop apps for the next launch", value: $restoreApps)
            }

            actionRow("Reset app preferences", subtitle: "Restore HyperDroid app behavior defaults") {
                defaultBrowser = "HyperDroid Browser"
                allowBackgroundApps = true
                allowWebApps = true
                restoreApps = true
            }
        }
    }

    private var accountsPage: some View {
        settingsStack {
            settingsSection("Your info") {
                textFieldRow("Account name", subtitle: "Name shown in Start and Settings", text: $accountName)
                pickerRow(
                    "Sign-in type",
                    subtitle: "HyperDroid profile type",
                    selection: $signInMode,
                    values: ["Local account", "Guest"]
                )
            }

            settingsSection("Sync") {
                toggleRow("Remember settings", subtitle: "Persist HyperDroid preferences on this device", value: $syncSettings)
            }
        }
    }

    private var timeLanguagePage: some View {
        settingsStack {
            settingsSection("Time") {
                toggleRow("24-hour time", subtitle: "Use 24-hour taskbar clock", value: $use24Hour)
                pickerRow(
                    "First day of week",
                    subtitle: "Calendar preference",
                    selection: $firstDay,
                    values: ["Sunday", "Monday"]
                )
            }

            settingsSection("Language & region") {
                pickerRow(
                    "Language",
                    subtitle: "HyperDroid display-language preference",
                    selection: $language,
                    values: ["English", "Bahasa Melayu"]
                )
                pickerRow(
                    "Region",
                    subtitle: "Date and regional preference",
                    selection: $region,
                    values: ["Malaysia", "United States", "United Kingdom"]
                )
            }
        }
    }

    private var privacyPage: some View {
        settingsStack {
            actionRow("Storage Permission", subtitle: "Manage HyperDroid file access") {
                fileAccess = true
                updateMessage = "File access enabled for the HyperDroid workspace"
            }

            actionRow("App Info", subtitle: "Open this app’s iPadOS settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            actionRow("Privacy Policy", subtitle: "Open the HyperDroid privacy policy") {
                if let url = URL(string: "https://github.com/windows-ui/HyperDroid/tree/main/PrivacyPolicy") {
                    UIApplication.shared.open(url)
                }
            }

            settingsSection("App permissions") {
                toggleRow("Web access", subtitle: "Allow HyperDroid browser and web apps to access the network", value: $webAccess)
                toggleRow("Files", subtitle: "Allow HyperDroid apps to use the app file workspace", value: $fileAccess)
                toggleRow("Clipboard", subtitle: "Allow copy and paste inside HyperDroid", value: $clipboardAccess)
            }

            settingsSection("Diagnostics") {
                toggleRow("Usage diagnostics", subtitle: "Keep local diagnostic information for troubleshooting", value: $diagnostics)
                toggleRow("Personalized suggestions", subtitle: "Use local app activity for recommendations", value: $tracking)
            }
        }
    }

    private var updatesPage: some View {
        settingsStack {
            settingsSection("Update center") {
                HStack(spacing: 14) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(p.primary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Update center")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(p.text)
                        Text("HyperDroid iOS 0.1.0")
                            .font(.system(size: 11.5))
                            .foregroundColor(p.mutedText)
                    }

                    Spacer()
                }
                .padding(12)

                toggleRow(
                    "Get updates as soon as they’re available",
                    subtitle: "Prefer the newest HyperDroid build",
                    value: $autoUpdate
                )

                pickerRow(
                    "Update channel",
                    subtitle: "Choose the HyperDroid update channel",
                    selection: $updateChannel,
                    values: ["Stable", "Beta"]
                )

                if lastUpdateCheck > 0 {
                    let date = Date(timeIntervalSince1970: lastUpdateCheck)
                    infoRow("Last checked", value: date.formatted(date: .abbreviated, time: .shortened))
                }

                if !updateMessage.isEmpty {
                    infoRow("Status", value: updateMessage)
                }
            }

            actionRow("Check for updates", subtitle: "Check the installed HyperDroid build status") {
                lastUpdateCheck = Date().timeIntervalSince1970
                updateMessage = "You’re up to date"
            }

            actionRow("Rate Us", subtitle: "Open the HyperDroid project page") {
                if let url = URL(string: "https://github.com/windows-ui/HyperDroid") {
                    UIApplication.shared.open(url)
                }
            }

            actionRow("Share this app", subtitle: "Copy the HyperDroid project link") {
                UIPasteboard.general.string = "https://github.com/windows-ui/HyperDroid"
                updateMessage = "HyperDroid link copied"
            }
        }
    }

    private func handleCursorImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            do {
                let imported = try cursorPack.importCursorFiles(urls)
                if cursorPack.hasUsablePack {
                    cursorStyle = "Windows 11"
                }
                cursorImportMessage = imported > 0
                    ? "Imported \(imported) cursor files"
                    : "No supported .cur files were selected"
            } catch {
                cursorImportMessage = error.localizedDescription
            }
        case .failure(let error):
            cursorImportMessage = error.localizedDescription
        }
    }

    private func settingsStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 14) {
            content()
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(p.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

            VStack(spacing: 0) {
                content()
            }
            .background(p.dialogBody)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.border.opacity(0.55), lineWidth: 1))
        }
    }

    private func toggleRow(_ title: String, subtitle: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.text)
                Text(subtitle)
                    .font(.system(size: 10.8))
                    .foregroundColor(p.mutedText)
            }

            Spacer()

            Toggle("", isOn: value)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 56)
        .overlay(divider, alignment: .bottom)
    }

    private func pickerRow(
        _ title: String,
        subtitle: String,
        selection: Binding<String>,
        values: [String]
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.text)
                Text(subtitle)
                    .font(.system(size: 10.8))
                    .foregroundColor(p.mutedText)
            }

            Spacer()

            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 190, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 58)
        .overlay(divider, alignment: .bottom)
    }

    private func sliderRow(
        _ title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.text)
                Text(subtitle)
                    .font(.system(size: 10.8))
                    .foregroundColor(p.mutedText)
            }

            Spacer()

            Slider(value: value, in: range)
                .frame(width: 130)

            if !suffix.isEmpty {
                Text("\(Int(value.wrappedValue))\(suffix)")
                    .font(.system(size: 11))
                    .foregroundColor(p.mutedText)
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 64)
        .overlay(divider, alignment: .bottom)
    }

    private func textFieldRow(
        _ title: String,
        subtitle: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.text)
                Text(subtitle)
                    .font(.system(size: 10.8))
                    .foregroundColor(p.mutedText)
            }

            Spacer()

            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 190)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 60)
        .overlay(divider, alignment: .bottom)
    }

    private var systemVolumeRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Volume")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.text)
                Text("Control the iPad system output volume")
                    .font(.system(size: 10.8))
                    .foregroundColor(p.mutedText)
            }

            Spacer()

            HDSystemVolumeView()
                .frame(width: 150, height: 30)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 64)
        .overlay(divider, alignment: .bottom)
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(p.text)
            Spacer()
            Text(value)
                .font(.system(size: 11.5))
                .foregroundColor(p.mutedText)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .overlay(divider, alignment: .bottom)
    }

    private func actionRow(
        _ title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(p.text)
                    Text(subtitle)
                        .font(.system(size: 10.8))
                        .foregroundColor(p.mutedText)
                }

                Spacer()

                Text("Run")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 30)
                    .background(p.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 58)
            .background(p.dialogBody)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.border.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(p.border.opacity(0.30))
            .frame(height: 1)
            .padding(.leading, 12)
    }
}
