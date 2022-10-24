import Foundation
import SwiftSoup
import UIKit

extension FDNetworks {
    func getQRCode() async throws -> Data? {
        // network API
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!
        var request = URLRequest(url: url)
        setUserAgent(&request)
        let responseData = try await authenticate(request: request)
        guard let htmlText = String(data: responseData, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        let doc = try SwiftSoup.parse(htmlText)
        guard let qrcodeElement = try doc.select("#myText").first() else {
            throw NetworkError.invalidResponse
        }
        let qrcodeStr = try qrcodeElement.attr("value")
        
        // generate QR code data
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = qrcodeStr.data(using: .ascii, allowLossyConversion: false)
        filter.setValue(data, forKey: "inputMessage")
        guard let ciimage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciimage.transformed(by: transform)
        let uiimage = UIImage(ciImage: scaledCIImage)
        return uiimage.pngData()!
    }
}
