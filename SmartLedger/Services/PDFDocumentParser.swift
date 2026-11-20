import Foundation
import PDFKit

public struct PDFDocumentParser {
    public static let shared = PDFDocumentParser()
    
    private init() {}
    
    public func extractText(from pdfData: Data) -> String {
        guard let document = PDFDocument(data: pdfData) else {
            return ""
        }
        
        var fullText = ""
        let pageCount = document.pageCount
        for i in 0..<pageCount {
            if let page = document.page(at: i), let pageContent = page.string {
                fullText.append(pageContent)
                fullText.append("\n")
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
