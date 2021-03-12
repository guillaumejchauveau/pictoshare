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

    class FormatA {

    }

    class FormatB {

    }

    class Annotator: DocumentAnnotator {
        var compatibleFormats: [AnyClass] = []
        var lastDocumentAnnotated: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func annotate(document: AnyObject) throws {
            lastDocumentAnnotated = document
        }
    }

    class Exporter: DocumentExporter {
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

        XCTAssertFalse(stub.isCompatibleWith(format: FormatA.self))
        stub.compatibleFormats.append(FormatB.self)
        stub.compatibleFormats.append(FormatA.self)
        XCTAssertTrue(stub.isCompatibleWith(format: FormatA.self))
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

    class LibraryA: Library {
        let id = "a"
        let description = ""

        var formats: Formats = [:]
        var sources: Sources = [:]
        var annotators: Annotators = [:]
        var exporters: Exporters = [:]
    }

    func testLibraryManager() throws {
        let manager = LibraryManager()

        XCTAssertNil(manager.get(format: "a.formats.formatA"))
        XCTAssertNil(manager.make(annotator: "a.annotators.AnnotatorA", with: Configuration()))
        try XCTAssertNoThrow(manager.load(library: LibraryA()))
        try XCTAssertNoThrow(manager.load(library: LibraryA()))

        let library1 = LibraryA()
        library1.formats["formatA"] = ("", FormatA.self)
        try XCTAssertNoThrow(manager.load(library: library1))
        try XCTAssertThrowsError(manager.load(library: library1))
        XCTAssertNotNil(manager.get(format: "a.formats.formatA"))

        let library2 = LibraryA()
        library2.annotators["AnnotatorA"] = ("", Annotator.self, nil)
        try XCTAssertNoThrow(manager.load(library: library2))
        try XCTAssertThrowsError(manager.load(library: library2))
        XCTAssertNotNil(manager.make(annotator: "a.annotators.AnnotatorA", with: Configuration()))
    }

    class Source: DocumentSource {
        var importCallback: ((AnyObject) -> Void)?

        required init(with configuration: Configuration) {
        }

        func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
            importCallback = callback
        }

        func promptDocument() {
            importCallback?(FormatA())
        }
    }

    /*func testImportationManager() throws {
        let manager = ImportationManager()

        try XCTAssertThrowsError(manager.promptDocument(from: UUID()))
        try XCTAssertThrowsError(manager.importDocument(FormatA(), withType: UUID()))

        let source_uuid = UUID()
        try XCTAssertNoThrow(manager.register(source: Source(with: [:], uuid: source_uuid)))
        try XCTAssertThrowsError(manager.register(source: Source(with: [:], uuid: source_uuid)))
        XCTAssertTrue(manager.sources.keys.contains(source_uuid))
        var failed = true
        manager.sources[source_uuid]!.setImportCallback({
            (document: AnyObject) in
            failed = false
        })
        try XCTAssertNoThrow(manager.promptDocument(from: source_uuid))
        XCTAssertFalse(failed)

        let type = DocumentType(description: "", uuid: UUID(), format: FormatA.self)
        let exporter = Exporter(with: [:], uuid: UUID())
        exporter.compatibleFormats = [FormatA.self]
        try type.set(exporter: exporter)
        let annotator = Annotator(with: [:], uuid: UUID())
        annotator.compatibleFormats = [FormatA.self]
        try type.append(annotator: annotator)
        try XCTAssertNoThrow(manager.register(type: type))
        try XCTAssertThrowsError(manager.register(type: type))
        try XCTAssertNoThrow(manager.importDocument(FormatA(), withType: type.uuid))
        XCTAssertNotNil(annotator.lastDocumentAnnotated)
        XCTAssertNotNil(exporter.lastDocumentExported)
    }*/

    func testConfiguration() throws {

    }
}
