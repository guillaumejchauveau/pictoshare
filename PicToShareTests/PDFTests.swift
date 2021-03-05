//
//  PDFTests.swift
//  PicToShareTests
//
//  Created by Steven on 03/03/2021.
//
//

import XCTest
@testable import PicToShare

class PDFTests: XCTestCase {
    
    func testCreatePDF() throws {
        //let uselessTextDocument = TextDocument()
        let pdfExporter = PDFExporter(with: [:], uuid: UUID())
        
        //try pdfExporter.CreatePDF(htmlString: "Un autre test sisi")
        //try pdfExporter.export(document: uselessTextDocument, with: [:])
        //let myString = "<font face=\"Futura\" color=\"SlateGray\"><h2>Hello World</h2></font>"
        
        let anotherSring = "<p> Une ligne </br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br></br> Une autre ligne </p>"
        
        let nonHtmlString = "Une ligne \n Une autre ligne"
        try pdfExporter.makePDF(stringToBePrinted: nonHtmlString)
        
        
    }
}
