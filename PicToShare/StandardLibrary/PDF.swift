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
    var compatibleFormats: [AnyClass] = [TextDocument.self]

    required init(with configuration: Configuration) {
    }

    func export(document: AnyObject) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        
        // WIP : Document given, later we will use the document parameter
        //let arbitraryTempDocument = TextDocument(content: "UNE Ligne pour la victoire")
        
        //let wantedUrl = "/Users/steven/Documents/INSA/Projet PTS/PTSFolder/"
        let file = "testPdf.pdf"
        
        // For now, we can't give the direct URL without going through the app container
        // Otherwise, we don't have the right to write a file in a directory
        if var fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileUrl = fileUrl.appendingPathComponent(file)
            
            //print("Voici l'url get : ")
            //print(fileUrl.absoluteString)
            let myDataAsString = "UNE Ligne pour la victoire"
            //let myDataAsBytes : [UInt8] = Array(myDataAsString.utf8)
            //let mydata = Data(myDataAsBytes)
            let mydata = myDataAsString.data(using: .utf8)
            var defaultData = PDFDocument().dataRepresentation()
            
            defaultData!.append(mydata!)
            
            let mydoc = PDFDocument()
            let mypage = PDFPage()
            
            let myannot = PDFAnnotation(bounds: CGRect(x: 135, y: 200, width: 24, height: 24), forType: .widget, withProperties: nil)
            myannot.widgetFieldType = .text
            myannot.widgetControlType = .unknownControl
            myannot.widgetStringValue = myDataAsString
            
            mypage.addAnnotation(myannot)
            
            print(mydoc.pageCount)
            
            mydoc.insert(mypage, at: 0)
            //guard let data = Data(base64Encoded: "UNE Ligne pour la victoire") else {
            //    throw DocumentFormatError.incompatibleDocumentFormat /*Can't happen */}
            
            //guard let pdfDoc = PDFDocument(data: defaultData!) else {
            //    throw DocumentFormatError.incompatibleDocumentFormat /*Can't happen */}
            
           
            mydoc.write(to: fileUrl)
        }
        else {
            print("Well, nope bro")
        }


//        switch type(of: document) {
//            case is TextDocument:
//                print("Bingo")
//            default:
//                print("Should not happen")
//        }
        
    }

    
    func makePDF(stringToBePrinted: String) throws {
        
        guard var directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Create a proper error
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        print("Before append : \(directoryURL)")
        directoryURL.appendPathComponent("testpdf5.pdf")
        
        let wantedUrl = "/Users/steven/Documents/INSA/Projet PTS/PTSFolder/"
        //let wantedUrl = "/Users/steven/Images/PDFStockage/"
        var anotherDirectoryURL = URL(fileURLWithPath: wantedUrl)
        anotherDirectoryURL.appendPathComponent("testpdf5.pdf")
        
        print("URL qui marche : \(directoryURL) \n Url qui marche pas : \(anotherDirectoryURL)")
        
        let htmlFriendlyString = parseToHtmlString(toBeParsed: stringToBePrinted)
        
        let printOpts: [NSPrintInfo.AttributeKey: Any] =
            [NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save,
             NSPrintInfo.AttributeKey.jobSavingURL: directoryURL]
        
        
        let printInfo = NSPrintInfo(dictionary: printOpts)
        printInfo.horizontalPagination = NSPrintInfo.PaginationMode.automatic
        printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
        printInfo.topMargin = 20.0
        printInfo.leftMargin = 20.0
        printInfo.rightMargin = 20.0
        printInfo.bottomMargin = 20.0

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 570, height: 740))
        
        // Convert the string to Data (may be useless with the document already have Data)
        if let htmlData = htmlFriendlyString.data(using: .utf8) {
            // Convert the data to a string that can be handled by html
            if let attrStr = NSAttributedString(html: htmlData,
                                                options: [.documentType: NSAttributedString.DocumentType.html],
                                                documentAttributes: nil) {
                
                let frameRect = NSRect(x: 0, y: 0, width: 550, height: 740)
                let textField = NSTextField(frame: frameRect)
                textField.attributedStringValue = attrStr
                view.addSubview(textField)

                let printOperation = NSPrintOperation(view: view, printInfo: printInfo)
                // By setting to false those attributes, we can skip the save window
                printOperation.showsPrintPanel = false
                printOperation.showsProgressPanel = false
                printOperation.run()
            }
        }
    }
    
    // Function that will replace /n and others String special characters
    // by their html version
    // Note : Does only a single <p> with </br> instead of /n for now
    func parseToHtmlString(toBeParsed: String) -> String{
        var parsedString = "<p>"
        
        // May be a switch in the future
        for char in toBeParsed {
            if (char == "\n") {
                parsedString.append("</br>")
            }
            else {
                parsedString.append(char)
            }
        }
        parsedString.append("</p>")
        return parsedString
    }
    
    func maybeTheGraal(textToBePrinted: String) {
        let url = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let docURL = url!.appendingPathComponent("THEdoc.pdf")
        
        
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
}
