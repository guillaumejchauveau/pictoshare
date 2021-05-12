# PicToShare

## Introduction

This educational project is an automated document digitizer and classifier for MacOS. 
As a group project, it aims to introduce the students to project management and establishing specifications with a client.

## Objectives

PicToShare allows the user to import Documents to their Mac either by taking pictures with an iPhone/iPad or by selecting files on the computer (any kind of file). They can then indicate how to process and classify the files by selecting a Document Type.
The Document Types, configured before importing a Document, allow the customisation of the importation process.
They can specify an optional processing script, an AppleScript that uses the path of the Document to import to modify it or create new ones. For example, the user can choose to process pictures with an OCR software to import a PDF with the text instead.
Another setting is a list of Annotations (aka. context annotations), string metadata that will be added to the Document as keywords, like the current location.
Finally, the user can indicate Integrations, that will attach the Document to another application. For example, the user can choose to add a link to the Document in currently active events in their calendar.
The Document can later be found via Spotlight, that indexes the content and keywords of the Document. Additionaly, a folder specific to each Document Types will contain a bookmark pointing to the Document.

## Implementation details

This version of PicToShare is a native MacOS application, using SwiftUI and some AppKit views for the user interface. In order to take pictures with external devices, it uses [Continuity Camera](https://support.apple.com/en-gb/guide/imac/apd1c059dc3b/mac).
It differs from previous versions of PicToShare, where a multiplatform application, or a Storyboard/Objective-C application, were working with an iOS app. Also, this version allows any kind of Documents, whereas the previous ones focused on pictures to PDFs on a mobile experience (hence the name).

## Structure

The main XCode projet (PicToShare/PicToShare) as multiple parts. The Core folder contains the standalone logic for running the application, the Views folder the SwiftUI views for the UI, and finally files for the entrypoint and Operating System integrations like Continuity Camera or the Status Bar Item.
