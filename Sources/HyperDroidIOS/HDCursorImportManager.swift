import UIKit
import UniformTypeIdentifiers

@MainActor
final class HDCursorImportManager: NSObject, UIDocumentPickerDelegate {
    static let shared = HDCursorImportManager()

    private var completion: ((Result<Int, Error>) -> Void)?
    private weak var activePicker: UIDocumentPickerViewController?

    private override init() {
        super.init()
    }

    func present(
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let presenter = Self.topViewController() else {
            completion(.failure(NSError(
                domain: "HyperDroid.CursorImport",
                code: 10,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "HyperDroid could not find a view controller to present the Files picker."
                ]
            )))
            return
        }

        self.completion = completion

        var types = UTType.types(
            tag: "cur",
            tagClass: .filenameExtension,
            conformingTo: .data
        )
        if types.isEmpty {
            types = [.data]
        }

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: types
        )
        picker.delegate = self
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true

        activePicker = picker
        presenter.present(picker, animated: true)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        let result: Result<Int, Error>

        do {
            let imported = try HDCursorPackManager.shared.importCursorFiles(urls)
            result = .success(imported)
        } catch {
            result = .failure(error)
        }

        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let completion = self.completion
            self.completion = nil
            self.activePicker = nil
            completion?(result)
        }
    }

    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion = nil
            self?.activePicker = nil
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let root = scenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController
            ?? scenes.flatMap(\.windows).first?.rootViewController

        return descend(root)
    }

    private static func descend(
        _ controller: UIViewController?
    ) -> UIViewController? {
        guard let controller else { return nil }

        if let presented = controller.presentedViewController {
            return descend(presented)
        }

        if let navigation = controller as? UINavigationController {
            return descend(navigation.visibleViewController)
        }

        if let tab = controller as? UITabBarController {
            return descend(tab.selectedViewController)
        }

        for child in controller.children.reversed() {
            if child.viewIfLoaded?.window != nil {
                return descend(child)
            }
        }

        return controller
    }
}
