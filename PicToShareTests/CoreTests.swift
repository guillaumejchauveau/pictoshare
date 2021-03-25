//
//  CoreTests.swift
//  PicToShareTests
//
//  Created by Guillaume Chauveau on 28/01/2021.
//
//

import XCTest
@testable import PicToShare

class PicToShareTests: XCTestCase {
    /*class DocumentTypeStub: DocumentType {
        var format: AnyClass

        var annotators: [DocumentAnnotator]

        var exporter: DocumentExporter

        init(_ format: AnyClass,
             _ annotators: [DocumentAnnotator],
             _ exporter: DocumentExporter) {
            self.format = format
            self.annotators = annotators
            self.exporter = exporter
        }
    }

    func testImportationManager() throws {
        let manager = ImportationManager()

        let annotator = TestAnnotatorA(with: Configuration())
        let exporter = TestExporterA(with: Configuration())
        let type = DocumentTypeStub(
                TestFormatA.self,
                [annotator],
                exporter)

        try XCTAssertNoThrow(manager.importDocument(TestFormatA(), withType: type))
        XCTAssertNotNil(annotator.lastDocumentAnnotated)
        XCTAssertNotNil(exporter.lastDocumentExported)
    }*/
}
