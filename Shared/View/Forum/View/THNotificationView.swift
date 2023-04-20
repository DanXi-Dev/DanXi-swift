import SwiftUI

struct THNotificationView: View {
    let message: THMessage
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            
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
            
            HStack {
                Spacer()
                Text(message.createTime.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var header: some View {
        Group {
            switch message.code {
            case .favorite:
                HStack {
                    Image(systemName: "star")
                    Text("New reply in favorites")
                }
            case .reply:
                HStack {
                    Image(systemName: "arrowshape.turn.up.left")
                    Text("New reply")
                }
            case .mention:
                HStack {
                    Image(systemName: "quote.opening")
                    Text("Mentioned")
                }
            case .modify:
                HStack {
                    Image(systemName: "exclamationmark.bubble")
                    Text("Violation notice")
                }
            case .permission:
                HStack {
                    Image(systemName: "lock.trianglebadge.exclamationmark")
                    Text("Ban notice")
                }
            case .report:
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text("New Report")
                }
            case .reportDealt:
                HStack {
                    Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                    Text("Report feedback")
                }
            case .mail:
                HStack {
                    Image(systemName: "envelope")
                    Text("System mail")
                }
            default:
                HStack {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .foregroundColor(.secondary)
        .font(.callout)
    }
}
