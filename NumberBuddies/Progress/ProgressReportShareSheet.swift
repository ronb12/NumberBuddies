import SwiftUI
import UIKit

struct ProgressReportShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ProgressReportPrintPresenter: UIViewControllerRepresentable {
    let pdfData: Data
    let jobName: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard isPresented, !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = jobName

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = pdfData
        printController.present(animated: true) { _, _, _ in
            isPresented = false
            context.coordinator.didPresent = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var didPresent = false
    }
}
