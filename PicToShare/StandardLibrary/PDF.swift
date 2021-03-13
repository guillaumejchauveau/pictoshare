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

    
    func export(document: AnyObject, with config: Configuration) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        
        // WIP : Document given, later we will use the document parameter
        //let arbitraryTempDocument = TextDocument(content: "UNE Ligne pour la victoire")
        
        // Temporary name file
        let file = "testPdf.pdf"
        
        // For now, we can't give the direct URL without going through the app container
        // Otherwise, we don't have the right to write a file in a directory
        let url = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let docURL = url!.appendingPathComponent(file)
        
        //createPDF(textToBePrinted: document.text) // To be changed
        createPDF(textToBePrinted: "String de test", to: docURL)
       
        
//        switch type(of: document) {
//            case is TextDocument:
//                print("Bingo")
//            default:
//                print("Should not happen")
//        }
        
    }

    
    func createPDF(textToBePrinted: String, to docURL: URL) {
        
        try? PDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).writePDF(to: docURL) { context in
            context.beginPage()
            var text = "C'est ça que tu veux ?"
            let frame = CGRect(x: 0, y: 0, width: 612, height: 792)
            addBodyText(pageRect: frame, body: textToBePrinted)
            //performDrawing(context: context)
            context.beginPage()
            text = "C'EST CA CE QUE TU VEUX ????"
            addBodyText(pageRect: frame, body: text)
            //performDrawing(context: context)
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
