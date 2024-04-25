import SwiftUI
import ViewUtils

struct THDivisionSheet: View {
    @ObservedObject private var appModel = THModel.shared
    @State private var divisionId: Int
    @State private var divisionName: String
    @State private var divisionDescription: String
    @State private var pinned: [Int]
    @State private var pinnedText = ""
    
    init(divisionId: Int) {
        self._divisionId = State(initialValue: divisionId)
        if let division = THModel.shared.divisions.filter({ $0.id == divisionId }).first {
            self._divisionName = State(initialValue: division.name)
            self._divisionDescription = State(initialValue: division.description)
            self._pinned = State(initialValue: division.pinned.map(\.id))
        } else {
            self._divisionName = State(initialValue: "")
            self._divisionDescription = State(initialValue: "")
            self._pinned = State(initialValue: [])
        }
    }
    
    var body: some View {
        Sheet("Edit Division") {
            _ = try await THRequests.modifyDivision(id: divisionId, name: divisionName, description: divisionDescription, pinned: pinned)
        } content: {
            Section {
                Picker(selection: $divisionId,
                       label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(appModel.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            .onChange(of: divisionId) { id in
                if let division = appModel.divisions.filter({ $0.id == id }).first {
                    divisionName = division.name
                    divisionDescription = division.description
                    pinned = division.pinned.map(\.id)
                }
            }
            
            Section {
                TextField("Division Name", text: $divisionName)
                TextField("Division Description", text: $divisionDescription)
            }
            
            Section {
                ForEach(Array(pinned.enumerated()), id: \.offset) { (idx, hole) in
                    Text("#\(String(hole))")
                        .swipeActions {
                            Button(role: .destructive) {
                                pinned.remove(at: idx)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }
                
                HStack {
                    TextField("Enter Pinned Hole ID (Digits Only)", text: $pinnedText)
                        .keyboardType(.decimalPad)
                    
                    Button {
                        if let holeId = Int(pinnedText) {
                            if !pinned.contains(where: { $0 == holeId }) {
                                pinned.append(holeId)
                            }
                        }
                        pinnedText = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
