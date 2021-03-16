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
    class TestFormatA {

    }

    class TestFormatB {

    }

    class TestAnnotatorA: DocumentAnnotator {
        static var compatibleFormats: [AnyClass] = [TestFormatA.self]
        var lastDocumentAnnotated: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func annotate(document: AnyObject) throws {
            lastDocumentAnnotated = document
        }
    }

    class TestAnnotatorB: DocumentAnnotator {
        static var compatibleFormats: [AnyClass] = [TestFormatB.self]
        var lastDocumentAnnotated: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func annotate(document: AnyObject) throws {
            lastDocumentAnnotated = document
        }
    }

    class TestExporterA: DocumentExporter {
        static var compatibleFormats: [AnyClass] = [TestFormatA.self]
        var lastDocumentExported: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func export(document: AnyObject) throws {
            lastDocumentExported = document
        }
    }

    class TestExporterB: DocumentExporter {
        static var compatibleFormats: [AnyClass] = [TestFormatB.self]
        var lastDocumentExported: AnyObject? = nil

        required init(with configuration: Configuration) {
        }

        func export(document: AnyObject) throws {
            lastDocumentExported = document
        }
    }

    class TestSource: DocumentSource {
        var importCallback: ((AnyObject) -> Void)?
        let configuration: Configuration

        required init(with: Configuration) {
            configuration = with
        }

        func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
            importCallback = callback
        }

        func promptDocument() {
            importCallback?(TestFormatA())
        }
    }

    func testDocumentFormatCompatible() throws {
        XCTAssertFalse(TestExporterA.isCompatibleWith(format: TestFormatB.self))
        XCTAssertTrue(TestExporterA.isCompatibleWith(format: TestFormatA.self))
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

    func testLibraryManager() throws {
        let manager = LibraryManager()

        XCTAssertNil(manager.validate(""))
        XCTAssertNil(manager.validate("a.format.formatA"))

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

        let classID = manager.validate("b.format.formatA")
        XCTAssertNotNil(classID)
        XCTAssertEqual(classID!.libraryID, "b")
        XCTAssertEqual(classID!.typeProtocol,
                LibraryManager.CoreTypeProtocol.format)
        XCTAssertEqual(classID!.typeID, "formatA")
        XCTAssertNil(manager.validate("b.test.formatA"))
        XCTAssertNil(manager.validate("b.format.formatA",
                withTypeProtocol: .exporter))

        XCTAssertNotNil(manager.get(format: "b.format.formatA"))
        XCTAssertEqual(manager.get(description: "b.format.formatA"), "test")

        let library2 = TestLibrary("c")
        library2.annotatorTypes["AnnotatorA"] = ("", TestAnnotatorA.self, nil)
        try XCTAssertNoThrow(manager.load(library: library2))
        try XCTAssertThrowsError(manager.load(library: library2))
        try XCTAssertNoThrow(XCTAssertNotNil(
                manager.make(annotator: "c.annotator.AnnotatorA",
                        with: Configuration())))

        let library3 = TestLibrary("d")
        library3.formats["formatB"] = ("", TestFormatB.self)
        try manager.load(library: library3)
        let formats = manager.getFormats()
        XCTAssertEqual(formats.count, 2)
        XCTAssertEqual(manager.getAnnotatorTypes(
                compatibleWithFormat: "d.format.formatB").count,
                0)
        let annotators = manager.getAnnotatorTypes(
                compatibleWithFormat: "b.format.formatA")
        XCTAssertEqual(annotators.count, 1)
        XCTAssertEqual(annotators[0].classID, "c.annotator.AnnotatorA")
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

        let annotator = TestAnnotatorA(with: Configuration())
        let exporter = TestExporterA(with: Configuration())
        let type = DocumentTypeStub(
                TestFormatA.self,
                [annotator],
                exporter)

        try XCTAssertNoThrow(manager.importDocument(TestFormatA(), withType: type))
        XCTAssertNotNil(annotator.lastDocumentAnnotated)
        XCTAssertNotNil(exporter.lastDocumentExported)
    }

    func testConfiguration() throws {
        let firstLayer = makeSafe(Configuration.Layer())
        let secondLayer = makeSafe(Configuration.Layer())
        let thirdLayer = makeSafe(Configuration.Layer())

        firstLayer.pointee["a"] = 1
        let config1 = Configuration([firstLayer])
        XCTAssertNil(config1["b"])
        XCTAssertNotNil(config1["a"] as? Int)
        XCTAssertEqual(config1["a"] as! Int, 1)

        firstLayer.pointee["b"] = 0
        XCTAssertNotNil(config1["b"])

        secondLayer.pointee["a"] = 2
        thirdLayer.pointee["a"] = 3
        let config2 = Configuration([firstLayer, secondLayer, thirdLayer])
        XCTAssertNil(config2["c"])
        XCTAssertNotNil(config2["b"] as? Int)
        XCTAssertEqual(config2["b"] as! Int, 0)
        XCTAssertNotNil(config2["a"] as? Int)
        XCTAssertEqual(config2["a"] as! Int, 3)

        secondLayer.pointee["c"] = 4
        XCTAssertNotNil(config2["c"] as? Int)
        XCTAssertEqual(config2["c"] as! Int, 4)
        thirdLayer.pointee.removeValue(forKey: "a")
        XCTAssertNotNil(config2["a"] as? Int)
        XCTAssertEqual(config2["a"] as! Int, 2)
    }

    func testConfigurationManager() throws {
        let importationManager = ImportationManager()
        let libraryManager = LibraryManager()
        let library = TestLibrary("a")
        library.formats["formatA"] = ("", TestFormatA.self)
        library.sourceTypes["sourceA"] = ("", TestSource.self, [
            "a": 5
        ])
        library.exporterTypes["exporterA"] = ("", TestExporterA.self, [
            "a": 1
        ])
        library.annotatorTypes["annotatorA"] = ("", TestAnnotatorA.self, [
            "a": 2
        ])
        library.exporterTypes["exporterB"] = ("", TestExporterB.self, nil)
        library.annotatorTypes["annotatorB"] = ("", TestAnnotatorB.self, nil)
        try libraryManager.load(library: library)

        let configurationManager = ConfigurationManager(
                libraryManager,
                importationManager)

        try XCTAssertThrowsError(configurationManager.add(
                source: ConfigurationManager.CoreObjectMetadata("")))
        try XCTAssertThrowsError(configurationManager.add(
                source: ConfigurationManager.CoreObjectMetadata(
                        "a.format.formatA")))

        try XCTAssertNoThrow(configurationManager.add(
                source: ConfigurationManager.CoreObjectMetadata(
                        "a.source.sourceA",
                        objectLayer: [
                            "b": 4
                        ])))
        XCTAssertEqual(configurationManager.sources.count, 1)
        XCTAssertNotNil(configurationManager.sources[0].source as? TestSource)
        XCTAssertEqual((configurationManager.sources[0].source as! TestSource)
                .configuration["a"] as? Int, 5)
        XCTAssertEqual((configurationManager.sources[0].source as! TestSource)
                .configuration["b"] as? Int, 4)
        configurationManager.sources[0].metadata.objectLayer.pointee["b"] = 1
        XCTAssertEqual((configurationManager.sources[0].source as! TestSource)
                .configuration["b"] as? Int, 1)


        try XCTAssertThrowsError(configurationManager.addType(
                "a.format.formatA",
                "",
                ConfigurationManager.CoreObjectMetadata("a.exporter.exporterB"),
                [
                    ConfigurationManager.CoreObjectMetadata(
                            "a.annotator.annotatorB"
                    )
                ]))
        try XCTAssertNoThrow(configurationManager.addType(
                "a.format.formatA",
                "",
                ConfigurationManager.CoreObjectMetadata("a.exporter.exporterA"),
                [
                    ConfigurationManager.CoreObjectMetadata(
                            "a.annotator.annotatorA"
                    )
                ]))
        XCTAssertEqual(configurationManager.types.count, 1)
    }
}
