//
//  PDF.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation
import PDFKit
import WebKit

import Cocoa
import WebKit

import GraphicsRenderer

class PDFExporter: DocumentExporter {
    static var compatibleFormats: [AnyClass] = [TextDocument.self]

    required init(with configuration: Configuration) {
    }

    func export(document: AnyObject) throws {
        guard PDFExporter.isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }

        // WIP : Assuming for now that is a TextDocument. Need more flexibility later
        let castDocument = document as! TextDocument

        // For now, we can't give the direct URL without going through the app container
        // We don't have the rights to write a file in a directory outside of it
        let url = try FileManager.default
                .url(for: .documentDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true)
                .appendingPathComponent("PDFFolder", isDirectory: true)
        let docURL = url.appendingPathComponent("\(castDocument.documentName).pdf")

        try PDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
                .writePDF(to: docURL) { context in
                    context.beginPage()
                    let frame = CGRect(x: 0, y: 0, width: 612, height: 792)
                    addBodyText(pageRect: frame, body: castDocument.content)
                }
        print("PDF saved to :\(docURL)")
    }

    private func addBodyText(pageRect: CGRect, body: String) {

        //let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        // 1
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byWordWrapping
        // 2
        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle /*,
            NSAttributedString.Key.font: textFont*/
        ]
        let attributedText = NSAttributedString(
                string: body,
                attributes: textAttributes
        )
        // 3
        let textRect = CGRect(
                x: 10,
                y: 10,
                width: pageRect.width - 20,
                height: pageRect.height - 10 - pageRect.height / 5.0
        )
        attributedText.draw(in: textRect)
    }
}
