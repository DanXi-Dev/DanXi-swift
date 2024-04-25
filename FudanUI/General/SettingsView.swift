import SwiftUI
import FudanKit

public struct CampusSettingsView: View {
    @ObservedObject private var model = CampusModel.shared
    
    public init() { }
    
    public var body: some View {
        if model.loggedIn {
            Section("Campus.Tab") {
                Picker(selection: $model.studentType) {
                    Text("Undergraduate").tag(StudentType.undergrad)
                    Text("Graduate").tag(StudentType.grad)
                    Text("Staff").tag(StudentType.staff)
                } label: {
                    Label("Student Type", systemImage: "person.text.rectangle")
                }
            }
        }
    }
}
