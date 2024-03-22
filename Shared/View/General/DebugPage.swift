import SwiftUI

struct DebugPage: View {
    @State private var showURLSheet = false
    @State private var showHTTPSheet = false
    
    var body: some View {
        List {
            Section {
                Button("Debug Base URL") {
                    showURLSheet = true
                }
                
                Button("Test HTTP Request") {
                    showHTTPSheet = true
                }
            }
            
            Section {
                ScreenshotAlert()
            }
        }
        .navigationTitle("Debug")
        .sheet(isPresented: $showURLSheet) {
            DebugURLForm()
        }
        .sheet(isPresented: $showHTTPSheet) {
            DebugHTTPForm()
        }
    }
}

fileprivate struct DebugURLForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var auth: String = FDUHOLE_AUTH_URL
    @State private var fduhole: String = FDUHOLE_BASE_URL
    @State private var danke: String = DANKE_BASE_URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Auth", text: $auth)
                    TextField("fduhole", text: $fduhole)
                    TextField("danke", text: $danke)
                }
            }
            .navigationTitle("Debug Base URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if let authURL = URL(string: auth),
                           let fduholeURL = URL(string: fduhole),
                           let dankeURL = URL(string: danke) {
                            FDUHOLE_AUTH_URL = authURL.absoluteString
                            FDUHOLE_BASE_URL = fduholeURL.absoluteString
                            DANKE_BASE_URL = dankeURL.absoluteString
                        }
                        dismiss()
                    } label: {
                        Text("Submit")
                    }
                }
            }
        }
    }
}

fileprivate struct DebugHTTPForm: View {
    enum BaseURL {
        case fduhole, auth, danke, custom
    }
    
    @State private var baseURL = BaseURL.fduhole
    @State private var requestURL = ""
    @State private var requestMethod = ""
    @State private var requestBody = ""
    
    @State private var showResponse = false
    @State private var code = ""
    @State private var response = ""
    
    private func sendRequest() async throws {
        showResponse = false
        code = ""
        response = ""
        
        var base = ""
        switch baseURL {
        case .fduhole:
            base = FDUHOLE_BASE_URL
        case .auth:
            base = FDUHOLE_AUTH_URL
        case .danke:
            base = DANKE_BASE_URL
        case .custom:
            base = ""
        }
        guard let url = URL(string: base + requestURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = requestMethod.isEmpty ? "GET" : requestMethod
        if !requestBody.isEmpty {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestBody.data(using: String.Encoding.utf8)!
        }
        
        do {
            let data = try await autoRefresh(request)
            self.response = String(data: data, encoding: String.Encoding.utf8)!
            showResponse = true
        } catch let error as HTTPError {
            let code = error.code
            let data = error.data
            self.code = String(code)
            self.response = String(data: data, encoding: String.Encoding.utf8)!
            showResponse = true
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Base URL", selection: $baseURL) {
                        Text("FDUHole").tag(BaseURL.fduhole)
                        Text("DanKe").tag(BaseURL.danke)
                        Text("Auth").tag(BaseURL.auth)
                        Text("Custom").tag(BaseURL.custom)
                    }
                    TextField("URL", text: $requestURL)
                    TextField("Method (Default GET)", text: $requestMethod)
                }
                
                if !requestMethod.isEmpty {
                    Section("Request Body") {
                        TextEditor(text: $requestBody)
                            .frame(minHeight: 200)
                    }
                }
                
                Section {
                    AsyncButton("Submit") {
                        try await sendRequest()
                    }
                }
                
                Section("Response") {
                    if !code.isEmpty {
                        LabeledContent("Code", value: code)
                    }
                    Text(response)
                        .font(.callout.monospaced())
                }
            }
            .navigationTitle("Debug HTTP Request")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

fileprivate struct ScreenshotAlert: View {
    @ObservedObject private var settings = THSettings.shared
    @State private var showWarning = false
    
    var body: some View {
        Toggle(isOn: $settings.screenshotAlert) {
            Label("Screenshot Alert", systemImage: "camera.viewfinder")
        }
        .alert("Screenshot Policy", isPresented: $showWarning) {
            
        } message: {
            Text("Screenshot Warning")
        }
        .onChange(of: settings.screenshotAlert) { willShowAlert in
            if !willShowAlert {
                showWarning = true
            }
        }
    }
}
