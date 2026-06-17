import SwiftUI
import VisionKit
import PDFKit

/// VisionKit document scanner for paper printouts (SPEC §3.2). Returns scanned pages as
/// a single PDF's Data so multi-page reports upload as one file.
struct DocumentScanner: UIViewControllerRepresentable {
    var onComplete: (Data?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (Data?) -> Void
        init(onComplete: @escaping (Data?) -> Void) { self.onComplete = onComplete }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let pdf = PDFDocument()
            for i in 0..<scan.pageCount {
                if let page = PDFPage(image: scan.imageOfPage(at: i)) {
                    pdf.insert(page, at: pdf.pageCount)
                }
            }
            onComplete(pdf.dataRepresentation())
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onComplete(nil)
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onComplete(nil)
            controller.dismiss(animated: true)
        }
    }
}
