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
        ElectricityEntity(0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ElectricityEntity) -> Void) {
        var entry = ElectricityEntity(0)
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
                
                let place = "\(usageLoaded.campus) \(usageLoaded.building) \(usageLoaded.room)"
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
    public var warnLevel: Int = 0
    
    public init(_ warnLevel: Int = 0) {
        date = Date()
        place = "南区 10号楼 108"
        average = 15.27898
        
        if warnLevel == 0 {
            electricityAvailable = 3 * average
        } else if warnLevel == 1 {
            electricityAvailable = 1.2 * average
        } else if warnLevel == 2 {
            electricityAvailable = 0.2 * average
        } else {
            electricityAvailable = 1.2 * average
            print("warnLevel set error: warn level must be 0/1/2")
        }
        setWarnLevel()
    }
    
    public init(_ place: String, _ electricityAvailable: Float, _ average: Float) {
        date = Date()
        self.place = place
        self.electricityAvailable = electricityAvailable
        self.average = average
        setWarnLevel()
    }
    
    public mutating func setWarnLevel() {
        let ratio = electricityAvailable / average
        warnLevel = ratio < 0.5 ? 2 : (ratio <= 1.8 ? 1 : 0)
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
        .description(String(localized: "Check the remaining electricity in the dormitory and the average electricity usage in recent days.", bundle: .module))
        .supportedFamilies([.systemSmall])
        
    }
}

@available(iOS 17.0, *)
struct ElectricityWidgetView: View {
    let entry: ElectricityEntity
    
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
                    .foregroundColor(getWidgetColor(for: entry.warnLevel))
                Spacer()
            }
            .padding(.bottom, 1)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.place)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(String(format: "%.2f", entry.electricityAvailable))
                        .bold()
                        .font(.system(size: 15, design: .rounded))
                        .privacySensitive()
                    
                    Text(verbatim: " ")
                    Text(verbatim: "kWh")
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption2)
                    
                    Spacer()
                }
            }
            .padding(.bottom, 1)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "3-day average usage", bundle: .module))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(String(format: "%.2f", entry.average))
                        .bold()
                        .font(.system(size: 15, design: .rounded))
                        .privacySensitive()
                    
                    Text(verbatim: " ")
                    Text(verbatim: "kWh")
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption2)
                    
                    Spacer()
                }
            }
            .padding(.bottom, 1)
            
            if entry.warnLevel == 0 {
                Text(String(localized: "Sufficient charge ~", bundle: .module))
                    .bold()
                    .font(.system(size: 13, design: .rounded))
                    .privacySensitive()
                    .foregroundColor(getWidgetColor(for: entry.warnLevel))
            } else if entry.warnLevel == 1 {
                Text(String(localized: "Only 1-2 days of power left...", bundle: .module))
                    .bold()
                    .font(.system(size: 12, design: .rounded))
                    .privacySensitive()
                    .foregroundColor(getWidgetColor(for: entry.warnLevel))
            } else if entry.warnLevel == 2 {
                Text(String(localized: "Power critical, cutoff in 12 hours!", bundle: .module))
                    .bold()
                    .font(.system(size: 12, design: .rounded))
                    .privacySensitive()
                    .foregroundColor(getWidgetColor(for: entry.warnLevel))
            }
        }
    }
    
    func getWidgetColor(for level: Int) -> Color {
        switch level {
        case 0:
            return .green
        case 1:
            return .orange
        case 2:
            return .red
        default:
            return .green
        }
    }
}
#endif
