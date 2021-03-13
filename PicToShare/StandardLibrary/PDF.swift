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
    let description = "PDF Exporter"
    let uuid: UUID
    var compatibleFormats: [AnyClass] = [TextDocument.self]


    required init(with config: Configuration, uuid: UUID) {
        self.uuid = uuid
    }

    /// Creates a PDF file from a Document
    ///
    /// - Parameters:
    ///   - document: AnyObject that will be converted to the right Document after.
    ///   - with config: The Configuration.
    func export(document: AnyObject, with config: Configuration) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        
        // WIP : Assuming for now that is a TextDocument. Need more flexibility later
        let castDocument = document as! TextDocument
        
        // For now, we can't give the direct URL without going through the app container
        // We don't have the rights to write a file in a directory outside of it
        let url = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true).appendingPathComponent("PDFFolder", isDirectory: true)
        let docURL = url!.appendingPathComponent("\(castDocument.documentName).pdf")
        
        createPDF(textToBePrinted: castDocument.content, to: docURL)
       
        
//        switch type(of: document) {
//            case is TextDocument:
//                print("Bingo")
//            default:
//                print("Should not happen")
//        }
        
    }

    
    // Must be more flexible to automaticaly handle several pages
    func createPDF(textToBePrinted: String, to docURL: URL) {
        
        try? PDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).writePDF(to: docURL) { context in
            context.beginPage()
            let frame = CGRect(x: 0, y: 0, width: 612, height: 792)
            addBodyText(pageRect: frame, body: textToBePrinted)

            context.beginPage()
            let text = "C'EST CA CE QUE TU VEUX ????"
            addBodyText(pageRect: frame, body: text)

        }
        
        print("PDF saved to :\(docURL)")
        
    }
    
    func addBodyText(pageRect: CGRect, body: String) {
        
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
    
    // OSEF un peu atm
    private func performDrawing<Context>(context: Context) where Context: RendererContext, Context.ContextType == CGContext {
        let rect = context.format.bounds
        
        NSColor.white.setFill()
        context.fill(rect)
        
        NSColor.blue.setStroke()
        let frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        context.stroke(frame)
        
        NSColor.red.setStroke()
        context.stroke(rect.insetBy(dx: 5, dy: 5))
    }
}
