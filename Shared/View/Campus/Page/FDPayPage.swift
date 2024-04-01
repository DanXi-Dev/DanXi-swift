import SwiftUI
import UIKit
import FudanKit

struct FDPayPage: View {
    @Environment(\.openURL) var openURL
    
    @State private var qrCodeData: Data? = nil
    @State private var loading = false
    @State private var showTermsAlert = false
    
    func loadCodeData() {
        Task {
            loading = true
            defer { loading = false }
            do {
                let qrcodeStr = try await WalletAPI.getQRCode()
                
                // generate QR code data
                guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                    throw ParseError.invalidResponse
                }
                let data = qrcodeStr.data(using: .ascii, allowLossyConversion: false)
                filter.setValue(data, forKey: "inputMessage")
                guard let ciimage = filter.outputImage else {
                    throw ParseError.invalidResponse
                }
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledCIImage = ciimage.transformed(by: transform)
                let uiImage = UIImage(ciImage: scaledCIImage)
                qrCodeData = uiImage.pngData()!
            } catch CampusError.termsNotAgreed {
                showTermsAlert = true
            } catch {
                
            }
        }
    }
    
    var body: some View {
        VStack {
            Group {
                if loading {
                    ProgressView()
                } else if let data = qrCodeData {
                    Image(uiImage: UIImage(data: data)!)
                        .resizable()
                } else {
                    Text("Error")
                }
            }
            .frame(width: 300, height: 300)
                
            
            Button {
                loadCodeData()
            } label: {
                Label("Refresh QR Code", systemImage: "arrow.clockwise")
            }
        }
        .alert("Terms not Agreed", isPresented: $showTermsAlert) {
            Button {
                openURL(URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!)
            } label: {
                Text("Go to Browser")
            }
            
            Button {
                
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("To use QRCode, you must accept terms and conditions in webpage")
        }
        .navigationTitle("Fudan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadCodeData()
        }
    }
}

struct FDPayPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FDPayPage()
        }
    }
}
