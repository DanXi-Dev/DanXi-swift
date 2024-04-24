//
//  IntroSheet.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-24.
//

import SwiftUI
import FudanKit
import FudanUI
import DanXiUI
import ViewUtils

struct IntroSheet: View {
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
                Text(String(localized:"DanXi") + " 2.0")
                    .font(.largeTitle)
                    .bold()
                    .padding(8)
                Spacer()
                VStack(alignment: .leading) {
                    NewFeature(title: "Redesigned Interface", subtitle: "Rebuilt from the ground up for a smoother experience.", icon: "app")
                    NewFeature(title: "Import Schedules to Calendar", subtitle: "Import your schedules directly into the calendar app.", icon: "calendar")
                    NewFeature(title: "Details in Classroom Schedules", subtitle: "View and search for schedule details in each classroom.", icon: "calendar.day.timeline.leading")
                }
                .padding(.horizontal, 32)
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Text("Use of this app is subject to our [Terms and Conditions](https://danxi.fduhole.com/doc/app-terms-and-condition) and [Privacy Policy](https://danxi.fduhole.com/doc/app-privacy)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .padding(.horizontal, 32)
                NavigationLink(destination: IntroNotificationSheet(), label: {
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

struct NewFeature: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.accent)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .bold()
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct IntroLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var communityModel = CommunityModel.shared
    
    private var noAccountLogined: Bool {
        get { !communityModel.loggedIn && !campusModel.loggedIn }
    }
    
    private var allAccountLogined: Bool {
        get { communityModel.loggedIn && campusModel.loggedIn }
    }
    
    var body: some View {
        Form {
            FormTitle(title: "Login", description: "danxi-app-account-system-description")
            
            Section(content: {
                NavigationLink(destination: LoginSheet(style: .subpage), label: {
                    LabeledContent("Fudan Campus Account") {
                        if campusModel.loggedIn {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                })
                .disabled(campusModel.loggedIn)
            }, footer: {
                Text("danxi-app-account-system-footer-uis")
            })
            
            Section {
                NavigationLink(destination: AuthenticationSheet(style: .subpage), label: {
                    LabeledContent("FDU Hole Account") {
                        if communityModel.loggedIn {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                })
                .disabled(communityModel.loggedIn)
            } footer: {
                Text("danxi-app-account-system-footer-danxi")
            }

        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if communityModel.loggedIn {
                        model.screen = .forum
                    } else if campusModel.loggedIn {
                        model.screen = .campus
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
                model.screen = .campus
                model.showIntro = false
            }
        }
        .interactiveDismissDisabled()
    }
}

struct IntroNotificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var campusModel = CampusModel.shared
    
    @State private var nextPage: Bool = false
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Image(systemName: "app.badge")
                .symbolRenderingMode(.multicolor)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
                .padding(12)
            Text("Enable Notifications")
                .font(.largeTitle)
                .bold()
                .padding(8)
            Text("DanXi provides timely notifications to keep you updated. You will be prompted for permission to enable this feature in the upcoming step. You can adjust this setting at any time within the system settings.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Button(action: {
                #if targetEnvironment(macCatalyst)
                nextPage = true
                #endif
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings]) { granted, error in
                    // Next page
                    nextPage = true
                }
            }, label: {
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
        .navigationDestination(isPresented: $nextPage, destination: { IntroLoginSheet() })
    }
}

#Preview {
    IntroSheet()
}
