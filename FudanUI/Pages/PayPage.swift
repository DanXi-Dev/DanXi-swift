import SwiftUI
#if os(watchOS)
import EFQRCode
#else
import UIKit
#endif
import FudanKit
import Utils

struct PayPage: View {
    private static let codeLifetime: TimeInterval = 30
    private static let refreshInterval: TimeInterval = 25
    private static let retryInterval: TimeInterval = 5

    @Environment(\.openURL) var openURL
    
    @State private var imageData: Data? = nil
    @State private var loading = false
    @State private var showTermsAlert = false
    @State private var expirationDate: Date?
    @State private var nextRefreshDate: Date?
    @State private var currentDate = Date()
    @State private var refreshTimer: Timer?
    @State private var loadTask: Task<Void, Never>?

    private var secondsRemaining: Int {
        guard let expirationDate else { return 0 }
        return max(0, Int(ceil(expirationDate.timeIntervalSince(currentDate))))
    }

    private var codeIsValid: Bool {
        imageData != nil && secondsRemaining > 0
    }

    private func loadCodeData() {
        guard !loading else { return }

        loading = true
        loadTask = Task { @MainActor in
            defer {
                if !Task.isCancelled {
                    loading = false
                    loadTask = nil
                }
            }

            do {
                let qrcodeStr = try await WalletAPI.getQRCode()
                let newImageData: Data
                
                #if os(watchOS)
                // generate QR code data
                
                if let image = EFQRCode.generate(for: qrcodeStr) {
                    let uiImage = UIImage(cgImage: image)
                    guard let data = uiImage.pngData() else {
                        throw LocatableError()
                    }
                    newImageData = data
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
                guard let data = uiImage.pngData() else {
                    throw LocatableError()
                }
                newImageData = data
                #endif

                guard !Task.isCancelled else { return }
                let loadedAt = Date()
                imageData = newImageData
                currentDate = loadedAt
                expirationDate = loadedAt.addingTimeInterval(Self.codeLifetime)
                nextRefreshDate = loadedAt.addingTimeInterval(Self.refreshInterval)
            } catch CampusError.termsNotAgreed {
                guard !Task.isCancelled else { return }
                nextRefreshDate = nil
                showTermsAlert = true
            } catch {
                guard !Task.isCancelled else { return }
                nextRefreshDate = Date().addingTimeInterval(Self.retryInterval)
            }
        }
    }

    private func startRefreshing() {
        stopRefreshing()
        currentDate = Date()

        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            let now = Date()
            currentDate = now

            if let nextRefreshDate, now >= nextRefreshDate {
                loadCodeData()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
        loadCodeData()
    }

    private func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        loadTask?.cancel()
        loadTask = nil
        loading = false
    }
    
    var body: some View {
        VStack {
            
            if expirationDate != nil {
                Text("Expires in \(secondsRemaining)s", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.bottom, 10)
            }
            
            
            Group {
                if codeIsValid,
                   let imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                } else if loading || imageData != nil {
                    ProgressView()
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
            .disabled(loading)
            .padding(.top, 10)
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
        .onAppear {
            startRefreshing()
        }
        .onDisappear {
            stopRefreshing()
        }
    }
}
