import SwiftUI
import WidgetKit

private struct QRCodeWidgetEntry: TimelineEntry {
    let date: Date
}

private struct QRCodeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QRCodeWidgetEntry {
        QRCodeWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (QRCodeWidgetEntry) -> Void) {
        completion(QRCodeWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QRCodeWidgetEntry>) -> Void) {
        completion(Timeline(entries: [QRCodeWidgetEntry(date: .now)], policy: .never))
    }
}

struct QRCodeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "qrcode.fudan.edu.cn", provider: QRCodeWidgetProvider()) { _ in
            QRCodeWidgetView()
                .widgetURL(URL(string: "fduhole://navigation/campus?section=pay")!)
        }
        .configurationDisplayName("Fudan QR Code")
        .description("Open the Fudan QR Code page.")
        .supportedFamilies([.accessoryCircular])
    }
}

private struct QRCodeWidgetView: View {
    private var icon: some View {
        Image(systemName: "qrcode")
            .font(.system(size: 30, weight: .medium))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Fudan QR Code")
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 17.0, *) {
            icon.containerBackground(.clear, for: .widget)
        } else {
            icon
        }
    }
}

@available(iOS 17.0, *)
#Preview("QR Code", as: .accessoryCircular) {
    QRCodeWidget()
} timeline: {
    QRCodeWidgetEntry(date: .now)
}
