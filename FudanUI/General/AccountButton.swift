import SwiftUI
import FudanKit
import ViewUtils

public struct CampusAccountButton: View {
    @ObservedObject private var model = CampusModel.shared
    
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
                    Text("Fudan Campus Account", bundle: .module)
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

public struct AccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) {
                        return try await ProfileStore.shared.getCachedProfile()
                    } refreshAction: {
                        return try await ProfileStore.shared.getRefreshedProfile()
                    } content: { profile in
                        Section {
                            LabeledContent {
                                Text(profile.name)
                            } label: {
                                Text("Name", bundle: .module)
                            }
                            
                            LabeledContent {
                                Text(profile.campusId)
                            } label: {
                                Text("Fudan.ID", bundle: .module)
                            }
                            
                            LabeledContent {
                                Text(profile.department)
                            } label: {
                                Text("Department", bundle: .module)
                            }
                            
                            LabeledContent {
                                Text(profile.major)
                            } label: {
                                Text("Major", bundle: .module)
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
                                Text("Logout", bundle: .module)
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle(String(localized: "Account Info", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
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
        }
    }
}

#Preview("Logged In") {
    List {
        CampusAccountButton(showLoginSheet: .constant(false), showUserSheet: .constant(false))
    }
    .previewPrepared(wrapped: nil)
}

#Preview("Not Logged In") {
    List {
        CampusAccountButton(showLoginSheet: .constant(false), showUserSheet: .constant(false))
    }
}
