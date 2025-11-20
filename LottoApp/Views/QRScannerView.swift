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
    
    // MARK: - Coordinator (중개인)
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerView
        var lastScannedCode: String?
        var lastScanTime: Date = Date()
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let scannedValue = metadataObject.stringValue {
                
                let now = Date()
                if scannedValue == lastScannedCode && now.timeIntervalSince(lastScanTime) < 2.0 {
                    return
                }
                
                lastScannedCode = scannedValue
                lastScanTime = now
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                parent.onScan(scannedValue)
            }
        }
    }
}
