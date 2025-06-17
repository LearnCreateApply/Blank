import SwiftUI
import UIKit

struct RecordView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RecordViewController {
        return RecordViewController()
    }

    func updateUIViewController(_ uiViewController: RecordViewController, context: Context) {}
}
