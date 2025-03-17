import SwiftUI
import DanXiKit
import DanXiUI
import ViewUtils

struct DebugPage: View {
    @State private var showQuestionSheet = false
    @State private var resetURLSuccessAlert = false
    @ObservedObject private var settings = ForumSettings.shared
    @AppStorage("watermark-unlocked") private var watermarkUnlocked = true
    
    private func resetBaseURLs() {
        guard let urls = UIPasteboard.general.string else { return }
        let lines = urls.split(separator: "\n")
        guard lines.count == 3 else { return }
        let authURL = URL(string: String(lines[0]))
        let forumURL = URL(string: String(lines[1]))
        let curriculumURL = URL(string: String(lines[2]))
        
        guard let authURL, let forumURL, let curriculumURL else { return }
        
        UserDefaults.standard.set(authURL.absoluteString, forKey: "fduhole_auth_url")
        UserDefaults.standard.set(forumURL.absoluteString, forKey: "fduhole_base_url")
        UserDefaults.standard.set(curriculumURL.absoluteString, forKey: "danke_base_url")
        
        DanXiKit.authURL = authURL
        DanXiKit.forumURL = forumURL
        DanXiKit.curriculumURL = curriculumURL
        
        resetURLSuccessAlert = true
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    showQuestionSheet = true
                } label: {
                    Text("Register Questions")
                }
            }
            
            Section {
                Button {
                    resetBaseURLs()
                } label: {
                    Text("Reset Base URLs")
                }
                
            } footer: {
                Text("Paste the backend URLs in three lines, separated by newlines, in the order of `auth`, `forum` and `curriculum`.")
            }
            
            if watermarkUnlocked {
                Section {
                    Toggle(isOn: $settings.screenshotAlert) {
                        Label("Screenshot Alert", systemImage: "camera.viewfinder")
                    }
                    
                    Stepper("Watermark Opacity \(String(format: "%.3f", settings.watermarkOpacity))", value: settings.$watermarkOpacity, step: 0.002)
                }
            }
        }
        .navigationTitle("Debug")
        .sheet(isPresented: $showQuestionSheet) {
            QuestionSheet()
        }
        .alert("Reset URLs Success", isPresented: $resetURLSuccessAlert) {
            
        }
    }
}

#Preview {
    NavigationStack {
        DebugPage()
    }
}
