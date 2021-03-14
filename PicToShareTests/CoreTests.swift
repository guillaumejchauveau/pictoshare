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
    class DocumentFormatCompatibleStub: DocumentFormatCompatible {
        var compatibleFormats: [AnyClass] = []
    }

    class TestFormatA {

    }

    class TestFormatB {

    }

    class TestAnnotator: DocumentAnnotator {
        var compatibleFormats: [AnyClass] = []
        var lastDocumentAnnotated: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func annotate(document: AnyObject) throws {
            lastDocumentAnnotated = document
        }
    }

    class TestExporter: DocumentExporter {
        var compatibleFormats: [AnyClass] = []
        var lastDocumentExported: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func export(document: AnyObject) throws {
            lastDocumentExported = document
        }
    }

    func testDocumentFormatCompatible() throws {
        let stub = DocumentFormatCompatibleStub()

        XCTAssertFalse(stub.isCompatibleWith(format: TestFormatA.self))
        stub.compatibleFormats.append(TestFormatB.self)
        stub.compatibleFormats.append(TestFormatA.self)
        XCTAssertTrue(stub.isCompatibleWith(format: TestFormatA.self))
    }

    class TestLibrary: Library {
        let id: String
        let description = ""

        var formats: Formats = [:]
        var sourceTypes: SourceTypes = [:]
        var annotatorTypes: AnnotatorTypes = [:]
        var exporterTypes: ExporterTypes = [:]

        init(_ id: String) {
            self.id = id
        }
    }

    func testClassID() throws {

    }

    func testLibraryManager() throws {
        let manager = LibraryManager()

        XCTAssertNil(manager.get(format: "a.format.formatA"))
        try XCTAssertNoThrow(XCTAssertNil(
                manager.make(
                        annotator: "a.annotator.AnnotatorA",
                        with: Configuration())))
        try XCTAssertNoThrow(manager.load(library: TestLibrary("a")))
        try XCTAssertThrowsError(manager.load(library: TestLibrary("a")))

        let library1 = TestLibrary("b")
        library1.formats["formatA"] = ("test", TestFormatA.self)
        try XCTAssertNoThrow(manager.load(library: library1))
        try XCTAssertThrowsError(manager.load(library: library1))
        XCTAssertNotNil(manager.get(format: "b.format.formatA"))
        XCTAssertEqual(manager.get(description: "b.format.formatA"), "test")

        let library2 = TestLibrary("c")
        library2.annotatorTypes["AnnotatorA"] = ("", TestAnnotator.self, nil)
        try XCTAssertNoThrow(manager.load(library: library2))
        try XCTAssertThrowsError(manager.load(library: library2))
        try XCTAssertNoThrow(XCTAssertNotNil(
                manager.make(annotator: "c.annotator.AnnotatorA",
                        with: Configuration())))
    }

    class DocumentTypeStub: DocumentType {
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

        let annotator = TestAnnotator(with: Configuration())
        let exporter = TestExporter(with: Configuration())
        exporter.compatibleFormats = [TestFormatA.self]
        let type = DocumentTypeStub(
                TestFormatA.self,
                [annotator],
                exporter)

        try XCTAssertNoThrow(manager.importDocument(TestFormatA(), withType: type))
        XCTAssertNotNil(annotator.lastDocumentAnnotated)
        XCTAssertNotNil(exporter.lastDocumentExported)
    }

    class TestSource: DocumentSource {
        var importCallback: ((AnyObject) -> Void)?

        required init(with: Configuration) {
        }

        func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
            importCallback = callback
        }

        func promptDocument() {
            importCallback?(TestFormatA())
        }
    }

    func testConfiguration() throws {
        let libraryManager = LibraryManager()
        let library = TestLibrary("a")
        library.formats["formatA"] = ("", TestFormatA.self)
        library.sourceTypes["sourceA"] = ("", TestSource.self, [
            "a": 5
        ])
        CFPreferencesSetAppValue(
                "a.format.sourceA" as CFString,
                nil,
                kCFPreferencesCurrentApplication)
        try libraryManager.load(library: library)
    }

    /*func testDocumentType() throws {
        var type = DocumentType(format: FormatA.self)

        XCTAssertEqual(type.annotators.count, 0)
        try XCTAssertThrowsError(type.add(annotator: Annotator(with: Configuration())))

        let annotator1 = Annotator(with: Configuration())
        annotator1.compatibleFormats = [FormatA.self]
        try XCTAssertNoThrow(type.add(annotator: annotator1))
        XCTAssertEqual(type.annotators.count, 1)

        type.remove(annotator: 0)
        XCTAssertEqual(type.annotators.count, 0)

        XCTAssertNil(type.exporter)
        try XCTAssertThrowsError(type.set(exporter: Exporter(with: Configuration())))

        let exporter = Exporter(with: Configuration())
        exporter.compatibleFormats = [FormatA.self]
        try XCTAssertNoThrow(type.set(exporter: exporter))
        XCTAssertNotNil(type.exporter)
    }*/
}
