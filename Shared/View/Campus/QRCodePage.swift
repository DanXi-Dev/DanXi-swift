import SwiftUI

struct QRCodePage: View {
    @State var qrCodeData: Data? = nil
    @State var loading = false
    @State var errorInfo = ""
    
    func loadCodeData() {
        Task {
            loading = true
            defer { loading = false }
            do {
                qrCodeData = try await EcardRequests.getQRCode()
            } catch {
                errorInfo = error.localizedDescription
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
        .navigationTitle("Fudan QR Code")
        .task {
            loadCodeData()
        }
    }
}

struct QRCodePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QRCodePage()
        }
    }
}
