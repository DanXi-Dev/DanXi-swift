import SwiftUI
#if os(watchOS)
import EFQRCode
#else
import UIKit
#endif
import FudanKit
import Utils

struct PayPage: View {
    @Environment(\.openURL) var openURL
    
    @State private var imageData: Data? = nil
    @State private var loading = false
    @State private var showTermsAlert = false
    
    func loadCodeData() {
        Task {
            loading = true
            defer { loading = false }
            do {
                let qrcodeStr = try await WalletAPI.getQRCode()
                
                #if os(watchOS)
                // generate QR code data
                
                if let image = EFQRCode.generate(for: qrcodeStr) {
                    let uiImage = UIImage(cgImage: image)
                    imageData = uiImage.pngData()
                } else {
                    throw LocatableError()
                }
                #else
                // generate QR code data
                guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                    throw LocatableError()
                }
                let data = qrcodeStr.data(using: .ascii, allowLossyConversion: false)
                filter.setValue(data, forKey: "inputMessage")
                guard let ciimage = filter.outputImage else {
                    throw LocatableError()
                }
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledCIImage = ciimage.transformed(by: transform)
                let uiImage = UIImage(ciImage: scaledCIImage)
                imageData = uiImage.pngData()
                #endif
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
                } else if let imageData {
                    Image(uiImage: UIImage(data: imageData)!)
                        .resizable()
                } else {
                    Text("Error", bundle: .module)
                }
            }
            
            #if os(watchOS)
            .frame(width: 145, height: 145)
            .onTapGesture {
                loadCodeData()
            }
            #else
            .frame(width: 300, height: 300)
            #endif
                
            #if !os(watchOS)
            Button {
                loadCodeData()
            } label: {
                Label(String(localized: "Refresh QR Code", bundle: .module), systemImage: "arrow.clockwise")
            }
            #endif
        }
        .alert(String(localized: "Terms not Agreed", bundle: .module), isPresented: $showTermsAlert) {
            Button {
                openURL(URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!)
            } label: {
                Text("Go to Browser", bundle: .module)
            }
            
            Button {
                
            } label: {
                Text("Cancel", bundle: .module)
            }
        } message: {
            Text("To use QRCode, you must accept terms and conditions in webpage", bundle: .module)
        }
        #if !os(watchOS)
        .navigationTitle(String(localized: "Fudan QR Code", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            loadCodeData()
        }
    }
}
