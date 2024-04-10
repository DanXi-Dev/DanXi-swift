import SwiftUI

struct AboutPage: View {
    @Environment(\.openURL) private var openURL
    
    private var version: String {
        Bundle.main.releaseVersionNumber ?? ""
    }
    
    private var build: String {
        Bundle.main.buildVersionNumber ?? ""
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    LinkView(url: "https://danxi.fduhole.com", text: "Website", icon: "safari")
                    LinkView(url: "https://danxi.fduhole.com/doc/app-terms-and-condition", text: "Terms and Conditions", icon: "info.circle")
                    LinkView(url: "https://apps.apple.com/app/id1568629997?action=write-review", text: "Write a Review", icon: "star")
                    
                    NavigationLink {
                        CreditPage()
                    } label: {
                        Label("Acknowledgements", systemImage: "heart")
                    }
                } header: {
                    appIcon
                        .textCase(.none)
                }
                
                if DXModel.shared.isAdmin {
                    Section {
                        NavigationLink {
                            DebugPage()
                        } label: {
                            Label("Debug", systemImage: "ant.circle.fill")
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                VStack {
                    Text("Copyright © 2024 DanXi-Dev")
                    Text("沪ICP备2021032046号-4A")
                        .onPress {
                            openURL(URL(string: "https://beian.miit.gov.cn/")!)
                        }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding()
                Spacer()
            }
        }
        .labelStyle(.titleOnly)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(.systemGroupedBackground)
    }
    
    private var appIcon: some View {
        HStack {
            Spacer()
            VStack {
                Image("Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                Text("DanXi")
                    .font(.title)
                    .bold()
                Text("Version \(version) (\(build))")
                    .font(.callout)
            }
            .padding(.bottom)
            Spacer()
        }
    }
}
