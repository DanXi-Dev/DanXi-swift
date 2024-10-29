import SwiftUI
import ViewUtils
import DanXiKit

struct KeyAdminSection: View {
    @State private var userId: String = ""
    @AppStorage("shamir-key-identity") private var identity = ""
    
    @State private var ciphertext: String? = nil
    @State private var plaintext: String? = nil
    @State private var decryptionStatus: ShamirDecryptionStatus? = nil
    @State private var decryptionResult: ShamirDecryptionResult? = nil
    
    @State private var ciphertextCopied = false
    @State private var plaintextUploaded = false
    
    @State private var showCiphertextAlert = false
    @State private var showUploadPlaintextSheet = false
    
    var body: some View {
        Form {
            Section {
                TextField(String(localized: "User ID to decrypt", bundle: .module), text: $userId)
                    .onChange(of: userId) { _ in
                        ciphertext = nil
                        plaintext = nil
                    }
                TextField(String(localized: "Decryption Identity", bundle: .module), text: $identity)
            } footer: {
                Text(verbatim: String(localized: "Decryption identity is the identifier used to create the decryption key. It should look like this: admin_name <admin@fduhole.com>", bundle: .module))
            }
            
            copyCiphertextButton
            
            uploadPlaintextButton
            
            checkDectryptionButton
            
            Section {
                resultSection
            }
        }
        .alert(String(localized: "Ciphertext Copied", bundle: .module), isPresented: $showCiphertextAlert) {
            // nothing
        }
        .sheet(isPresented: $showUploadPlaintextSheet) {
            uploadPlaintextSheet
        }
        .navigationTitle(String(localized: "Key Admin Section", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var copyCiphertextButton: some View {
        if let userId = Int(userId), !identity.isEmpty {
            HStack {
                AsyncButton {
                    try await withHaptics {
                        ciphertext = try await GeneralAPI.retrieveEncryptedShamirShare(userId: userId, identityName: identity)
                        UIPasteboard.general.string = ciphertext
                        ciphertextCopied = true
                    }
                } label: {
                    Label {
                        Text("Copy Ciphertext", bundle: .module)
                    } icon: {
                        Image(systemName: "document.on.document")
                    }
                }
                
                Spacer()
                
                if ciphertextCopied {
                    Image(systemName: "checkmark.circle")
                }
            }
            .foregroundStyle(ciphertextCopied ? .green : Color.accentColor)
        }
    }
    
    private var uploadPlaintextSheet: some View {
        Sheet(String(localized: "Upload Plaintext", bundle: .module)) {
            guard let userId = Int(userId), let plaintext else {
                throw URLError(.badServerResponse)
            }
            
            try await GeneralAPI.uploadDecryptedShamirShare(userId: userId, share: plaintext, identityName: identity)
            plaintextUploaded = true
        } content: {
            VStack {
                HStack {
                    if let plaintext {
                        Text(plaintext)
                            .font(.system(size: 16, design: .monospaced))
                        Spacer()
                    } else {
                        Spacer()
                        Text("Paste Decrypted Plaintext Here", bundle: .module)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                
                HStack {
                    Spacer()
                    PasteButton(payloadType: String.self) { strings in
                        plaintext = strings.first
                    }
                    Spacer()
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    private var uploadPlaintextButton: some View {
        if ciphertextCopied {
            HStack {
                Button {
                    showUploadPlaintextSheet = true
                } label: {
                    Label {
                        Text("Upload Plaintext", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                Spacer()
                
                if plaintextUploaded {
                    Image(systemName: "checkmark.circle")
                }
            }
            .foregroundStyle(plaintextUploaded ? .green : Color.accentColor)
        }
    }
    
    @ViewBuilder
    private var checkDectryptionButton: some View {
        if let userId = Int(userId) {
            AsyncButton {
                try await withHaptics {
                    let decryptionStatus = try await GeneralAPI.getShamirDecryptionStatus(userId: userId)
                    self.decryptionStatus = decryptionStatus
                    if !decryptionStatus.shamirUploadReady {
                        return
                    }
                    
                    let decryptionResult = try await GeneralAPI.getShamirDecryptionResult(userId: userId)
                    UIPasteboard.general.string = decryptionResult.userEmail
                    self.decryptionResult = decryptionResult
                }
            } label: {
                Label {
                    Text("Check Decryption Status", bundle: .module)
                } icon: {
                    Image(systemName: "person.badge.key")
                }
            }
        }
    }
    
    @ViewBuilder
    private var resultSection: some View {
        if let decryptionResult {
            VStack(alignment: .leading) {
                Label {
                    Text("Copied", bundle: .module)
                } icon: {
                    Image(systemName: "document.on.clipboard")
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                
                Text("Decryption Result: \(decryptionResult.userEmail)", bundle: .module)
            }
        } else if let decryptionStatus {
            if let identities = decryptionStatus.uploadedSharesIdentityNames {
                VStack(alignment: .leading) {
                    Text("Plaintext Uploaded:", bundle: .module)
                    
                    GroupBox {
                        ForEach(identities, id: \.self) { identity in
                            Text(identity)
                        }
                    }
                    .font(.system(size: 14, design: .monospaced))
                }
            } else {
                Text("Not enough plaintext yet", bundle: .module)
            }
        }
    }
}

#Preview {
    KeyAdminSection()
        .previewPrepared()
}
