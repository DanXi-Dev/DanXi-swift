//
//  IntroSheet.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-24.
//

import SwiftUI

struct IntroSheet: View {
    @EnvironmentObject private var model: AppModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Spacer()
                Spacer()
                Image("Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .padding(12)
                Text(String(localized:"DanXi") + String(localized:"2.0"))
                    .font(.largeTitle)
                    .bold()
                    .padding(8)
                Text("app-intro-description")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding(.horizontal, 32)
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Text("Use of this app is subject to our [Terms and Conditions](https://danxi.fduhole.com/doc/app-terms-and-condition) and [Privacy Policy](https://danxi.fduhole.com/doc/app-privacy)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.horizontal, 32)
                NavigationLink(destination: IntroLoginSheet(), label: {
                    Text("Continue")
                        .font(.title3)
                        .frame(maxWidth: 320)
                        .padding(8)
                })
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    IntroSheet()
}

struct IntroLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    
    private var noAccountLogined: Bool {
        get { !DXModel.shared.isLogged && !FDModel.shared.isLogged }
    }
    
    private var allAccountLogined: Bool {
        get { DXModel.shared.isLogged && FDModel.shared.isLogged }
    }
    
    var body: some View {
        Form {
            FormTitle(title: "Login", description: "danxi-app-account-system-description")
            
            Section {
                NavigationLink("Fudan Campus Account", destination: FDLoginSheet(style: .subpage))
                    .disabled(FDModel.shared.isLogged)
                NavigationLink("FDU Hole Account", destination: DXAuthSheet(style: .subpage))
                    .disabled(DXModel.shared.isLogged)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if DXModel.shared.isLogged {
                        model.section = .forum
                    } else if FDModel.shared.isLogged {
                        model.section = .campus
                    }
                    model.showIntro = false
                } label: {
                    Text("Skip")
                }
                .disabled(noAccountLogined)
            }
        }
        .onAppear() {
            if allAccountLogined {
                model.section = .campus
                model.showIntro = false
            }
        }
        .interactiveDismissDisabled()
    }
}
