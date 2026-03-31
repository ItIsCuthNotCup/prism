//
//  ShareSheet.swift
//  Chromatose
//
//  UIActivityViewController wrapper for SwiftUI.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    var text: String = "I scored on Chromatose! Can you beat me?"

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items: [Any] = [image, text]
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
