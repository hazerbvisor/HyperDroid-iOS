import SwiftUI

struct HDPhotosView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var zoom: Double = 1
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                p.dialogBody
                HStack {
                    Button("‹", action: {}).buttonStyle(.plain).font(.system(size: 24))
                    Spacer()
                    VStack(spacing: 12) {
                        HDImage(name: "img_app_photos").frame(width: 72, height: 72)
                        Text("No image selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(p.text)
                        Text("Open an image from File Explorer")
                            .font(.system(size: 12))
                            .foregroundColor(p.mutedText)
                    }
                    Spacer()
                    Button("›", action: {}).buttonStyle(.plain).font(.system(size: 24))
                }
                .foregroundColor(p.text)
                .padding(.horizontal, 20)
            }

            HStack(spacing: 10) {
                Button("ⓘ", action: {}).buttonStyle(.plain)
                Divider().frame(height: 30)
                Text("1024 × 1024").font(.system(size: 10.5)).foregroundColor(p.mutedText)
                Spacer()
                Text("−").font(.system(size: 18))
                Slider(value: $zoom, in: 0.1...3).frame(width: 120)
                Text("+").font(.system(size: 18))
                Divider().frame(height: 30)
                Button("Fit", action: { zoom = 1 }).buttonStyle(.plain)
            }
            .foregroundColor(p.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(p.footer)
        }
    }
}

struct HDMusicView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var progress = 0.0
    @State private var playing = false
    @State private var selection = "Music"
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    musicNav("Home")
                    musicNav("Music")
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.top, 38)
                .frame(width: 165)
                .background(p.dialogBody)

                ZStack(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(selection)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(p.text)
                            .padding(.top, 38)
                            .padding(.leading, 24)
                        Spacer()
                        Text("No music found")
                            .font(.system(size: 13))
                            .foregroundColor(p.mutedText)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                    HDImage(name: "img_app_music")
                        .frame(width: 120, height: 120)
                        .padding(24)
                        .background(p.startMenu)
                        .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(p.dialog.opacity(0.95))
            }

            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    Text("00:00 / 00:00").font(.system(size: 12)).foregroundColor(p.mutedText)
                    Slider(value: $progress).frame(maxWidth: .infinity)
                }
                HStack {
                    Text("No track selected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(p.mutedText)
                        .frame(maxWidth: 200, alignment: .leading)
                    Spacer()
                    Button("◀︎", action: {}).buttonStyle(.plain)
                    Button(playing ? "❚❚" : "▶︎", action: { playing.toggle() })
                        .buttonStyle(.borderedProminent)
                        .frame(width: 46, height: 46)
                    Button("▶︎", action: {}).buttonStyle(.plain)
                    Spacer()
                    Button("↻", action: {}).buttonStyle(.plain)
                }
                .foregroundColor(p.text)
            }
            .padding(12)
            .background(p.footer)
        }
    }

    private func musicNav(_ title: String) -> some View {
        Button { selection = title } label: {
            HStack(spacing: 10) {
                Text(title == "Home" ? "⌂" : "♫")
                Text(title)
                Spacer()
            }
            .font(.system(size: 13))
            .foregroundColor(p.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(selection == title ? Color.orange.opacity(0.14) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
