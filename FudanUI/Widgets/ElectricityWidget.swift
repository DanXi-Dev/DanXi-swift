//
//  ElectricityWidget.swift
//  FudanUI
//
//  Created by 袁新宇 on 2025/1/20.

#if !os(watchOS)
import WidgetKit
import SwiftUI
import FudanKit

struct ElectricityWidgetProvier: TimelineProvider {
    func placeholder(in context: Context) -> ElectricityEntity {
        ElectricityEntity(ElectricityEntity.WarnLevel.full)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ElectricityEntity) -> Void) {
        var entry = ElectricityEntity(ElectricityEntity.WarnLevel.full)
        if !context.isPreview {
            entry.placeholder = true
        }
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                async let usage = ElectricityStore.shared.getCachedElectricityUsage()
                async let dateValues = try? MyStore.shared.getCachedElectricityLogs().map { DateValueChartData(date: $0.date, value: $0.usage) }
                let (usageLoaded, dateValuesLoaded) = try await (usage, dateValues)
                
                var filteredDateValues: [DateValueChartData] = []
                if let dateValuesLoaded {
                    let nonZeroDateValues = dateValuesLoaded.filter { $0.value != 0 }
                    filteredDateValues = Array(nonZeroDateValues.prefix(3))
                } else {
                    filteredDateValues = []
                }
                
                let place = "\(usageLoaded.campus)\(usageLoaded.building)\(usageLoaded.room)"
                let electricityAvailable = usageLoaded.electricityAvailable
                let average = filteredDateValues.isEmpty ? 15.0 : filteredDateValues.prefix(3).map { $0.value }.reduce(0, +) / Float(min(3, filteredDateValues.count))
                let entry = ElectricityEntity(place, electricityAvailable, average)
                let date = Calendar.current.date(byAdding: .minute, value: 30, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = ElectricityEntity()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .minute, value: 30, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

public struct ElectricityEntity: TimelineEntry {
    public let date: Date
    public let place: String
    public let electricityAvailable: Float
    public let average: Float               // 3 days average usage
    public var placeholder = false
    public var loadFailed = false
    public var warnLevel: WarnLevel
    
    public enum WarnLevel: Int {
        case full = 0
        case low = 1
        case critical = 2
    }
    
    public init(_ warnLevel: WarnLevel = .full) {
        date = Date()
        place = "南区 10号楼 108"
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
    
    public init(_ place: String, _ electricityAvailable: Float, _ average: Float) {
        date = Date()
        self.place = place
        self.electricityAvailable = electricityAvailable
        self.average = average
        let ratio = electricityAvailable / average
        self.warnLevel = ratio < 0.5 ? WarnLevel.critical : (ratio <= 1.8 ? WarnLevel.low : WarnLevel.full)
    }
}

@available(iOS 17.0, *)
public struct ElectricityWidget: Widget {
    public init() { }
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "electricity.fudan.edu.cn", provider: ElectricityWidgetProvier()) { entry in
            ElectricityWidgetView(entry: entry)
                .widgetURL(URL(string: "fduhole://navigation/campus?section=electricity")!)
        }
        .configurationDisplayName(String(localized: "Dormitory battery reminder", bundle: .module))
        .description(String(localized: "Check the remaining electricity in the dormitory", bundle: .module))
        .supportedFamilies([.systemSmall])
        
    }
}

@available(iOS 17.0, *)
struct ElectricityWidgetView: View {
    let entry: ElectricityEntity
    
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
        if entry.loadFailed {
            Text("Load Failed", bundle: .module)
                .foregroundColor(.secondary)
        } else {
            ElectricityWidgetContent
                .containerBackground(.fill.quinary, for: .widget)
            
        }
    }
    
    @ViewBuilder
    private var ElectricityWidgetContent: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(String(localized: "Dorm Electricity", bundle: .module), systemImage: "bolt.fill")
                    .bold()
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
            }
            .padding(.bottom, 18)
            
            if entry.warnLevel == .full {
                HStack{
                    Image(systemName: "battery.100")
                        .foregroundColor(widgetColor)
                    Text(String(localized: "Sufficient charge", bundle: .module))
                        .bold()
                        .font(.system(size: 22, design: .rounded))
                        .privacySensitive()
                        .foregroundColor(widgetColor)
                }
            } else if entry.warnLevel == .low {
                HStack{
                    Image(systemName: "battery.50percent")
                        .foregroundColor(widgetColor)
                    Text(String(localized: "Battery tension", bundle: .module))
                        .bold()
                        .font(.system(size: 22, design: .rounded))
                        .privacySensitive()
                        .foregroundColor(widgetColor)
                }
            } else if entry.warnLevel == .critical {
                HStack{
                    Image(systemName: "battery.25percent")
                        .foregroundColor(widgetColor)
                    Text(String(localized: "Power cut imminent", bundle: .module))
                        .bold()
                        .font(.system(size: 22, design: .rounded))
                        .privacySensitive()
                        .foregroundColor(widgetColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "Remaining battery capacity", bundle: .module))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(String(format: "%.2f", entry.electricityAvailable))
                        .bold()
                        .font(.system(size: 20, design: .rounded))
                        .privacySensitive()
                    
                    Text(verbatim: " ")
                    Text(verbatim: "kWh")
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption2)
                }
            }
        }
    }
}
#endif
