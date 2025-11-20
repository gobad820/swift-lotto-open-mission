import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // 뷰 업데이트 로직 (여기선 불필요)
    }
}
