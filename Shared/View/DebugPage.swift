import SwiftUI
import DanXiKit
import DanXiUI
import ViewUtils

struct DebugPage: View {
    @EnvironmentObject private var model: AppModel
    @State private var showURLSheet = false
    @State private var showQuestionSheet = false
    @ObservedObject private var settings = ForumSettings.shared
    @AppStorage("watermark-unlocked") private var watermarkUnlocked = false
    
    var body: some View {
        List {
            Section {
                Button("Debug Base URL") {
                    showURLSheet = true
                }
            }
            
            Section {
                ScreenshotAlert()
                Toggle(isOn: settings.$showBanners) {
                    Label("Show Activity Announcements", systemImage: "bell")
                }
                
                if watermarkUnlocked {
                    Stepper("Watermark Opacity \(String(format: "%.3f", settings.watermarkOpacity))", value: settings.$watermarkOpacity, step: 0.002)
                }
                
                Button("Test Register Questions") {
                    showQuestionSheet = true
                }
            }
            
            Section {
                Button("Reset Intro") {
                    model.showIntro.toggle()
                }
            }
            
            if let token = UserDefaults.standard.string(forKey: "notification-token") {
                Section("APNS Token") {
                    Text(token)
                        .onPress {
                            UIPasteboard.general.string = token
                        }
                }
            }
        }
        .navigationTitle("Debug")
        .sheet(isPresented: $showURLSheet) {
            DebugURLForm()
        }
        .sheet(isPresented: $showQuestionSheet) {
            QuestionSheet()
        }
    }
}

private struct DebugURLForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var auth: String = authURL.absoluteString
    @State private var fduhole: String = forumURL.absoluteString
    @State private var danke: String = curriculumURL.absoluteString
    
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
                           let forumURL = URL(string: fduhole),
                           let curriculumURL = URL(string: danke) {
                            UserDefaults.standard.set(authURL.absoluteString, forKey: "fduhole_auth_url")
                            UserDefaults.standard.set(forumURL.absoluteString, forKey: "fduhole_base_url")
                            UserDefaults.standard.set(curriculumURL.absoluteString, forKey: "danke_base_url")
                            
                            DanXiKit.authURL = authURL
                            DanXiKit.forumURL = forumURL
                            DanXiKit.curriculumURL = curriculumURL
                        }
                        dismiss()
                    } label: {
                        Text("Submit")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

fileprivate struct ScreenshotAlert: View {
    @ObservedObject private var settings = ForumSettings.shared
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
