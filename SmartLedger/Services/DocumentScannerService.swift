import SwiftUI
import VisionKit

#if canImport(VisionKit)
public struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding public var isPresented: Bool
    public var onScanCompleted: (UIImage) -> Void
    public var onScanFailed: ((Error) -> Void)?
    
    public init(
        isPresented: Binding<Bool>,
        onScanCompleted: @escaping (UIImage) -> Void,
        onScanFailed: ((Error) -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.onScanCompleted = onScanCompleted
        self.onScanFailed = onScanFailed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.isPresented = false
                return
            }
            let firstPage = scan.imageOfPage(at: 0)
            parent.onScanCompleted(firstPage)
            parent.isPresented = false
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onScanFailed?(error)
            parent.isPresented = false
        }
    }
}
#endif
