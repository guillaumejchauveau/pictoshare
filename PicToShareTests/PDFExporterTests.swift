//
//  PDFExporterTests.swift
//  PicToShareTests
//
//  Created by Steven on 03/03/2021.
//
//

import XCTest
@testable import PicToShare

class PDFTests: XCTestCase {
    func testCreatePDF() throws {
        let pdfExporter = PDFExporter(with: Configuration())
        let textDoc = TextDocument(content: "lololol", documentName: "test")
        
        //try pdfExporter.export(document: textDoc)
    }
}
