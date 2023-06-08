//
//  ViewController.swift
//  TestFontCheckerUIKit
//
//  Created by Nazariy Vysokinskyi on 30.05.2023.
//

import UIKit
import PDFKit
import CoreGraphics
import CoreText

class ViewController: UIViewController, UIDocumentPickerDelegate {
    // MARK: - Properties

    static let shouldUseTextKit2 = false

    let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
    let pdfView = PDFView()
    let textView: UITextView = {
        if shouldUseTextKit2 {
            return UITextView()
        }

        let textContainer = NSTextContainer()
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        let view = UITextView(frame: CGRect.zero, textContainer: textContainer)
        return view
    }()

    // MARK: - Setting up & Constraints

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .green

        documentPicker.delegate = self

        let chooseButton = UIButton(type: .system)
        chooseButton.setTitle("Choose PDF", for: .normal)
        chooseButton.addTarget(self, action: #selector(choosePDF), for: .touchUpInside)
        chooseButton.translatesAutoresizingMaskIntoConstraints = false

        pdfView.translatesAutoresizingMaskIntoConstraints = false

        textView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(chooseButton)
        view.addSubview(pdfView)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            chooseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chooseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            chooseButton.widthAnchor.constraint(equalToConstant: 200),
            chooseButton.heightAnchor.constraint(equalToConstant: 50),

            pdfView.topAnchor.constraint(equalTo: textView.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: chooseButton.topAnchor),

            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.centerYAnchor),
            textView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
    }

    // MARK: - File picking

    @objc func choosePDF() {
        present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            let pdfDocument = PDFDocument(url: url)
            pdfView.document = pdfDocument
            renderPDFText(pdfDocument)
        }
    }

    // MARK: - Text rendering

    func createFont(withData data: Data) -> CTFont? {
        guard let ctFontDescriptor = CTFontManagerCreateFontDescriptorFromData(data as CFData) else {
            return nil
        }

        let ctFont = CTFontCreateWithFontDescriptor(ctFontDescriptor, 16, nil)
        return ctFont
    }

    func renderPDFText(_ pdfDocument: PDFDocument?) {
        guard let pdfDocument = pdfDocument else { return }

        var pdfText = NSMutableAttributedString(string: "", attributes: nil)
        var fontNames = Set<String>()

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let pdfPage = pdfDocument.page(at: pageIndex) else { continue }

            guard let attributedString = pdfPage.attributedString else { continue }
            pdfText.append(attributedString)

            attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length), options: []) { (value, range, _) in
                if let font = value as? UIFont {
                    fontNames.insert(font.fontName)
                }
            }
        }

        guard let path = Bundle.main.path(forResource: "font35", ofType: nil) else
        {
            return
        }
        guard let data = NSData(contentsOf: URL(filePath: path)) else {
            return
        }
        let font = createFont(withData: data as Data)
        let attributes = [NSAttributedString.Key.font: font]
        let str = NSMutableAttributedString(string: "leggi del Paese in cui ci si trova, che potrebbero avere contenuti diversi da quanto affermato in questo manuale", attributes: attributes)
        str.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.red, range: NSMakeRange(0, 10))

        textView.attributedText = str
    }
}
