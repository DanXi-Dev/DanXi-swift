import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class CaptchaCoordinator: ObservableObject {
    struct Request: Identifiable {
        let id = UUID()
        let imageData: Data
    }

    enum Error: Swift.Error {
        case replacedByNewRequest
    }

    @Published var request: Request?
    private var continuation: CheckedContinuation<String, Swift.Error>?

    func waitForCaptcha(imageData: Data) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            if let current = self.continuation {
                current.resume(throwing: Error.replacedByNewRequest)
            }
            self.continuation = continuation
            self.request = Request(imageData: imageData)
        }
    }

    func submit(captcha: String) {
        continuation?.resume(returning: captcha)
        continuation = nil
        request = nil
    }
}

struct CaptchaBox: View {
    let imageData: Data
    let onSubmit: (String) -> Void

    @State private var captcha = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        captchaImage
                            .frame(maxWidth: 260, minHeight: 56, maxHeight: 88)
                        Spacer()
                    }
                }

                Section {
                    TextField(String(localized: "Captcha", bundle: .module), text: $captcha)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        onSubmit(captcha.trimmingCharacters(in: .whitespacesAndNewlines))
                    } label: {
                        Text("Submit", bundle: .module)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(captcha.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(String(localized: "Enter Captcha", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var captchaImage: some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        } else {
            Text("Failed to load captcha", bundle: .module)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        #else
        Text("Unsupported platform")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        #endif
    }
}
