import Foundation
import SwiftSoup
import UIKit


struct EcardRequests {
    static func getQRCode() async throws -> Data {
        // network API
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!
        let responseData = try await FudanAuthRequests.auth(url: url)
        
        let qrcodeElement = try processHTMLData(responseData, selector: "#myText")
        let qrcodeStr = try qrcodeElement.attr("value")
        
        
        // generate QR code data
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw NetworkError.invalidResponse
        }
        let data = qrcodeStr.data(using: .ascii, allowLossyConversion: false)
        filter.setValue(data, forKey: "inputMessage")
        guard let ciimage = filter.outputImage else {
            throw NetworkError.invalidResponse
        }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciimage.transformed(by: transform)
        let uiimage = UIImage(ciImage: scaledCIImage)
        return uiimage.pngData()!
    }
}
