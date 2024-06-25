import SwiftUI
import FudanKit

public struct CampusSettingsView: View {
    @ObservedObject private var model = CampusModel.shared
    
    public init() { }
    
    public var body: some View {
        if model.loggedIn {
            Section {
                Picker(selection: $model.studentType) {
                    Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                    Text("Graduate", bundle: .module).tag(StudentType.grad)
                    Text("Staff", bundle: .module).tag(StudentType.staff)
                } label: {
                    Label(String(localized: "Student Type", bundle: .module), systemImage: "person.text.rectangle")
                }
            } header: {
                Text("Campus.Tab", bundle: .module)
            }
        }
    }
}
