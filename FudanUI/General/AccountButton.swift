import SwiftUI
import FudanKit
import ViewUtils

public struct CampusAccountButton: View {
    @ObservedObject private var model = CampusModel.shared
    
    @State private var showLoginSheet = false
    @State private var showUserSheet = false
    
    public init() { }
    
    public var body: some View {
        Button {
            if model.loggedIn {
                showUserSheet = true
            } else {
                showLoginSheet = true
            }
        } label: {
            HStack {
                Image(systemName: model.loggedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(model.loggedIn ? Color.accentColor : Color.secondary,
                                     model.loggedIn ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.3))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 3.0) {
                    Text("Fudan Campus Account")
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Text(model.loggedIn ? "Logged in" : "Not Logged in")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showUserSheet) {
            AccountSheet()
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet()
        }
    }
}

struct AccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) { forceReload in
                        return try? await forceReload ? ProfileStore.shared.getRefreshedProfile() : ProfileStore.shared.getCachedProfile()
                    } content: { profile in
                        if let profile = profile {
                            Section {
                                LabeledContent("Name", value: profile.name)
                                LabeledContent("Fudan.ID", value: profile.campusId)
                                LabeledContent("Department", value: profile.department)
                                LabeledContent("Major", value: profile.major)
                            }
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            CampusModel.shared.logout()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Account Info")
                .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}