import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HDCursorDocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let cursorType = UTType(filenameExtension: "cur") ?? .data
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [cursorType, .data],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        let onCancel: () -> Void

        init(
            onPick: @escaping ([URL]) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            DispatchQueue.main.async {
                self.onPick(urls)
            }
        }

        func documentPickerWasCancelled(
            _ controller: UIDocumentPickerViewController
        ) {
            DispatchQueue.main.async {
                self.onCancel()
            }
        }
    }
}
