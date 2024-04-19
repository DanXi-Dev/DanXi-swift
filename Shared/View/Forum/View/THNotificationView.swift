import SwiftUI

struct THNotificationView: View {
    let message: THMessage
    
    var body: some View {
        HStack(alignment: .top) {
            message.icon
                .padding(.trailing)
                .padding(.vertical)
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(message.title)
                        .font(.headline)
                    Spacer()
                    Text(message.createTime.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if message.code == .permission {
                    Text(message.description)
                }
                
                if let floor = message.floor {
                    GroupBox {
                        THSimpleFloor(floor: floor)
                    }
                } else if let report = message.report {
                    GroupBox {
                        THSimpleFloor(floor: report.floor)
                    }
                } else if message.code == .mail {
                    GroupBox {
                        HStack {
                            Text(message.description)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

extension THMessage {
    public var icon: Image {
        switch self.code {
        case .favorite:
            Image(systemName: "bell")
        case .reply:
            Image(systemName: "arrowshape.turn.up.left")
        case .mention:
            Image(systemName: "quote.bubble")
        case .modify:
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
        case .permission:
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
        case .report:
            Image(systemName: "exclamationmark.circle")
        case .reportDealt:
            Image(systemName: "exclamationmark.circle")
        case .mail:
            Image(systemName: "envelope")
        default:
            Image(systemName: "questionmark.circle")
        }
    }
    
    public var title: LocalizedStringKey {
        switch self.code {
        case .favorite:
            "New reply in favorites"
        case .reply:
            "New reply"
        case .mention:
            "Mentioned"
        case .modify:
            "Violation notice"
        case .permission:
            "Ban notice"
        case .report:
            "New Report"
        case .reportDealt:
            "Report feedback"
        case .mail:
            "System mail"
        default:
            "Unknown"
        }
    }
}
