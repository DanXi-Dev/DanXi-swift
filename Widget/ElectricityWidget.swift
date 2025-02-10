import FudanKit
import SwiftUI
import WidgetKit

struct ElectricityWidgetProvier: TimelineProvider {
    func placeholder(in context: Context) -> ElectricityEntry {
        ElectricityEntry(ElectricityEntry.WarnLevel.full)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ElectricityEntry) -> Void) {
        var entry = ElectricityEntry(ElectricityEntry.WarnLevel.full)
        if !context.isPreview {
            entry.placeholder = true
        }
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            do {
                let usage = try await ElectricityStore.shared.getCachedElectricityUsage()
                let electricityLogs = try? await MyStore.shared.getCachedElectricityLogs()
                
                let filteredLogs: [ElectricityLog] = if let electricityLogs {
                    Array(electricityLogs.filter { $0.usage != 0 }.prefix(3))
                } else {
                    []
                }
                
                let electricityAvailable = usage.electricityAvailable
                let average: Float = if filteredLogs.isEmpty {
                    15.0
                } else {
                    filteredLogs.map { $0.usage }.reduce(0, +) / Float(min(3, filteredLogs.count))
                }
                let entry = ElectricityEntry(electricityAvailable, average)
                let date = Calendar.current.date(byAdding: .hour, value: 6, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = ElectricityEntry()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .minute, value: 30, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

struct ElectricityEntry: TimelineEntry {
    let date: Date
    var placeholder = false
    let electricityAvailable: Float
    /// 3 days average usage
    let average: Float
    var loadFailed = false
    var warnLevel: WarnLevel
    
    enum WarnLevel: Int {
        case full
        case low
        case critical
    }
    
    init(_ warnLevel: WarnLevel = .full) {
        date = Date()
        average = 15.27898
        switch warnLevel {
        case .full:
            electricityAvailable = 3 * average
        case .low:
            electricityAvailable = 1.2 * average
        case .critical:
            electricityAvailable = 0.2 * average
        }
        self.warnLevel = warnLevel
    }
    
    init(_ electricityAvailable: Float, _ average: Float) {
        date = Date()
        self.electricityAvailable = electricityAvailable
        self.average = average
        let ratio = electricityAvailable / average
        
        warnLevel = switch ratio {
        case ..<0.5: .critical
        case 0.5 ..< 1.8: .low
        case 1.8...: .full
        default: .full
        }
    }
}

@available(iOS 16.1, *)
struct ElectricityWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "electricity.fudan.edu.cn", provider: ElectricityWidgetProvier()) { entry in
            ElectricityWidgetView(entry: entry)
                .widgetURL(URL(string: "fduhole://navigation/campus?section=electricity")!)
        }
        .configurationDisplayName("Dormitory battery reminder")
        .description("Check the remaining electricity in the dormitory")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

@available(iOS 16.1, *)
struct ElectricityWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    let entry: ElectricityEntry
    
    private var widgetColor: Color {
        switch entry.warnLevel {
        case .full:
            return .green
        case .low:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var body: some View {
        WidgetWrapper(failed: entry.loadFailed) {
            Group {
                switch widgetFamily {
                case .systemSmall:
                    systemSmall
                case .accessoryRectangular:
                    accessoryRectangular
                case .accessoryInline:
                    accessoryInline
                default:
                    EmptyView()
                }
            }
        }
    }
    
    private var systemSmall: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Dorm Electricity", systemImage: "bolt.fill")
                    .bold()
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundColor(.green)
                Spacer()
            }
            .padding(.bottom, 1)
            
            Text("Daily usage: \(String(format: "%.2f", entry.average)) kWh")
                .foregroundColor(.secondary)
                .font(.caption2)
            
            Spacer()
            
            Text("Remains")
                .foregroundColor(.secondary)
                .font(.caption2)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(String(format: "%.2f", entry.electricityAvailable))
                    .bold()
                    .font(.title2)
                    .fontDesign(.rounded)
                
                Text(verbatim: " kWh")
                    .foregroundColor(.secondary)
                    .bold()
                    .font(.caption2)
            }
            
            Group {
                switch entry.warnLevel {
                case .full:
                    Label("Sufficient", systemImage: "battery.100")
                        .foregroundColor(.green)
                case .low:
                    Label("Low", systemImage: "battery.50percent")
                        .foregroundColor(.orange)
                case .critical:
                    Label("Critical", systemImage: "battery.25percent")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
        }
    }
    
    private var accessoryInline: some View {
        switch entry.warnLevel {
        case .full:
            Label("Sufficient", systemImage: "battery.100")
                .foregroundColor(.green)
        case .low:
            Label("Low", systemImage: "battery.50percent")
                .foregroundColor(.orange)
        case .critical:
            Label("Critical", systemImage: "battery.25percent")
                .foregroundColor(.red)
        }
    }
    
    private var accessoryRectangular: some View {
        VStack(alignment: .leading) {
            Group {
                switch entry.warnLevel {
                case .full:
                    Label("Sufficient", systemImage: "battery.100")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                case .low:
                    Label("Low", systemImage: "battery.50percent")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                case .critical:
                    Label("Critical", systemImage: "battery.25percent")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            // choose a smaller font to avoid overflow in English
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("\(String(format: "%.2f", entry.electricityAvailable)) kWh remains")
                    Spacer()
                }
                HStack {
                    Text("\(String(format: "%.2f", entry.electricityAvailable)) kWh remains")
                    Spacer()
                }
                .font(.caption)
            }
            
            Text("Daily usage: \(String(format: "%.2f", entry.average)) kWh")
                .foregroundColor(.secondary)
                .font(.caption2)
        }
    }
}

@available(iOS 17, *)
#Preview("Electricity", as: .systemSmall) {
    ElectricityWidget()
} timeline: {
    ElectricityEntry(.full)
    ElectricityEntry(.low)
    ElectricityEntry(.critical)
}

@available(iOS 17, *)
#Preview("Electricity", as: .accessoryRectangular) {
    ElectricityWidget()
} timeline: {
    ElectricityEntry(.full)
    ElectricityEntry(.low)
    ElectricityEntry(.critical)
}

@available(iOS 17, *)
#Preview("Electricity", as: .accessoryInline) {
    ElectricityWidget()
} timeline: {
    ElectricityEntry(.full)
    ElectricityEntry(.low)
    ElectricityEntry(.critical)
}
