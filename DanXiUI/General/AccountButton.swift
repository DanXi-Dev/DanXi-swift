import SwiftUI
import ViewUtils
import DanXiKit

public struct CommunityAccountButton: View {
    @ObservedObject private var model = CommunityModel.shared
    
    @Binding private var showLoginSheet: Bool
    @Binding private var showUserSheet: Bool
    
    public init(showLoginSheet: Binding<Bool>, showUserSheet: Binding<Bool>) {
        self._showLoginSheet = showLoginSheet
        self._showUserSheet = showUserSheet
    }
    
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
                    Text("FDU Hole Account", bundle: .module)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Text(model.loggedIn ? "Logged in" : "Not Logged in", bundle: .module)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

public struct CommunityAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) {
                        if let profile = ProfileStore.shared.profile {
                            return profile
                        }

                        return try await ProfileStore.shared.getRefreshedProfile()
                    } refreshAction: {
                        try await ProfileStore.shared.getRefreshedProfile()
                    } content: { user in
                        Section {
                            LabeledContent {
                                Text(String(user.id))
                            } label: {
                                Label(String(localized: "User ID", bundle: .module), systemImage: "person.text.rectangle")
                            }
                            
                            LabeledContent {
                                Text(user.joinTime.formatted(date: .long, time: .omitted))
                            } label: {
                                Label(String(localized: "Join Date", bundle: .module), systemImage: "calendar.badge.clock")
                            }
                            
                            if user.isAdmin {
                                LabeledContent {
                                    Text("Enabled", bundle: .module)
                                } label: {
                                    Label(String(localized: "Admin Privilege", bundle: .module), systemImage: "person.badge.key.fill")
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await CommunityModel.shared.logout()
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout", bundle: .module)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Account Info", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
