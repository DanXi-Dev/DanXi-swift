import SwiftUI
import ViewUtils
import DanXiKit

struct HoleCopySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var model: HoleModel
    @State private var selectedIDs: Set<Int> = []
    
    private func convertToText() -> String {
        var selectedFloors: [FloorPresentation] = []
        
        for id in selectedIDs {
            guard let floor = model.floors.first(where: { $0.floor.id == id }) else { continue }
            selectedFloors.append(floor)
        }
        
        selectedFloors =  selectedFloors.sorted(by: { $0.storey < $1.storey })
        
        var text = ""
        
        for presentation in selectedFloors {
            let floor = presentation.floor
            
            let firstLine = String(localized: "\(floor.anonyname) at \(floor.timeCreated.formatted())\n", bundle: .module)
            let secondLine = "\(presentation.storey)F (##\(String(floor.id)))\n"
            
            text += firstLine + secondLine
            
            for section in presentation.sections {
                let sectionText = switch section {
                case .localMention(let floor):
                    if let mentionedPresentation = model.floors.filter({ $0.floor.id == floor.id }).first {
                        String(localized: "[Mentioned \(mentionedPresentation.storey)F]", bundle: .module)
                    } else {
                        String(localized: "[Mentioned ##\(String(floor.id))]", bundle: .module)
                    }
                case .remoteMention(let mention):
                    String(localized: "[Mentioned ##\(String(mention.floorId))]", bundle: .module)
                case .text(let content):
                    replaceMarkdownTags(content.renderMarkdown())
                }
                
                text += sectionText + "\n"
            }
            
            text += "\n"
        }
        
        return text
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedIDs) {
                Section {
                    if !model.endReached || selectedIDs.count < model.floors.count {
                        AsyncButton {
                            if !model.endReached {
                                try await model.loadAllFloors()
                            }
                            selectedIDs = Set(model.floors.map(\.floor).map(\.id))
                        } label: {
                            Text("Select All", bundle: .module)
                        }
                    }
                    
                    if selectedIDs.count == model.floors.count && model.endReached {
                        Button {
                            selectedIDs = []
                        } label: {
                            Text("Unselect All", bundle: .module)
                        }
                    }
                }
                
                ForEach(model.floors) { presentation in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            PosterView(name: presentation.floor.anonyname, isPoster: presentation.floor.anonyname == model.floors.first?.floor.anonyname)
                            Spacer()
                            Text(verbatim: "\(presentation.storey)F")
                                .bold()
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                            Text(verbatim: "##\(presentation.floor.id)")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        Text(inlineAttributed(presentation.floor.content))
                            .lineLimit(2)
                    }
                    .tag(presentation.floor.id)
                }
                
                if !model.endReached {
                    AsyncButton {
                        try await model.loadAllFloors()
                    } label: {
                        Text("Load More", bundle: .module)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "Copy Text", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = convertToText()
                        dismiss()
                    } label: {
                        Text("Copy", bundle: .module)
                            .bold()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let floors: [Floor] = decodePreviewData(filename: "floors", directory: "forum")
    let model = HoleModel(hole: hole, floors: floors)
    
    HoleCopySheet()
        .environmentObject(model)
}
