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
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                let usage = try await ElectricityStore.shared.getCachedElectricityUsage()
                let dateValues = try? await MyStore.shared.getCachedElectricityLogs().map { DateValueChartData(date: $0.date, value: $0.usage) }
                
                var filteredDateValues: [DateValueChartData] = []
                if let dateValues {
                    let nonZeroDateValues = dateValues.filter { $0.value != 0 }
                    filteredDateValues = Array(nonZeroDateValues.prefix(3))
                } else {
                    filteredDateValues = []
                }
                
                let electricityAvailable = usage.electricityAvailable
                let average: Float = if filteredDateValues.isEmpty {
                    15.0
                } else {
                    filteredDateValues.prefix(3).map { $0.value }.reduce(0, +) / Float(min(3, filteredDateValues.count))
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

public struct ElectricityEntry: TimelineEntry {
    public let date: Date
    public var placeholder = false
    public let electricityAvailable: Float
    /// 3 days average usage
    public let average: Float
    public var loadFailed = false
    public var warnLevel: WarnLevel
    
    public enum WarnLevel: Int {
        case full
        case low
        case critical
    }
    
    public init(_ warnLevel: WarnLevel = .full) {
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
    
    public init(_ electricityAvailable: Float, _ average: Float) {
        date = Date()
        self.electricityAvailable = electricityAvailable
        self.average = average
        let ratio = electricityAvailable / average
        
        self.warnLevel = switch ratio {
        case ..<0.5: .critical
        case 0.5..<1.8: .low
        case 1.8...: .full
        default: .full
        }
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
        if entry.loadFailed {
            Text("Load Failed", bundle: .module)
                .foregroundColor(.secondary)
        } else {
            widgetContent
                .containerBackground(.fill.quinary, for: .widget)
        }
    }
    
    private var widgetContent: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(String(localized: "Dorm Electricity", bundle: .module), systemImage: "bolt.fill")
                    .bold()
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
            }
            .padding(.bottom, 18)
            
            switch entry.warnLevel {
            case .full:
                HStack{
                    Image(systemName: "battery.100")
                        .foregroundColor(widgetColor)
                    Text(String(localized: "Sufficient charge", bundle: .module))
                        .bold()
                        .font(.system(size: 22, design: .rounded))
                        .privacySensitive()
                        .foregroundColor(widgetColor)
                }
            case .low:
                HStack{
                    Image(systemName: "battery.50percent")
                        .foregroundColor(widgetColor)
                    Text(String(localized: "Battery tension", bundle: .module))
                        .bold()
                        .font(.system(size: 22, design: .rounded))
                        .privacySensitive()
                        .foregroundColor(widgetColor)
                }
            case .critical:
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
