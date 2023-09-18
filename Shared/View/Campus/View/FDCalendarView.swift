import SwiftUI

struct FDCourseView: View {
    let title: String
    let subtitle: String
    let length: CGFloat
    
    @ScaledMetric private var titleSize = 15
    @ScaledMetric private var subtitleSize = 10
    
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    
    var body: some View {
        let color = randomColor(title)
        
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .padding(.top, 5)
                .foregroundColor(color)
                .font(.system(size: titleSize))
            Text(subtitle)
                .foregroundColor(color.opacity(0.5))
                .font(.system(size: subtitleSize))
            Spacer()
        }
        .padding(.horizontal, 2)
        .frame(width: dx,
               height: length)
        .background(color.opacity(0.2))
        .overlay(Rectangle()
            .frame(width: 3)
            .foregroundColor(color), alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FDTimeSlotView: View {
    let timeSlot: FDTimeSlot
    
    @ScaledMetric private var courseSize = 14
    @ScaledMetric private var timeSize = 9
    
    var body: some View {
        VStack {
            Text(String(timeSlot.id))
                .font(.system(size: courseSize))
                .bold()
            Group {
                Text(timeSlot.start)
                Text(timeSlot.end)
            }
            .font(.system(size: timeSize))
        }
        .foregroundColor(.secondary)
    }
}

struct TimeslotsSidebar: View {
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    var body: some View {
        ZStack {
            ForEach(FDTimeSlot.list) { timeSlot in
                let point = CGPoint(x: x / 2 + 5,
                                    y: y - (dy / 2) + CGFloat(timeSlot.id) * dy)
                FDTimeSlotView(timeSlot: timeSlot)
                    .position(point)
            }
        }
        .frame(width: x, height: y + CGFloat(h) * dy)
    }
}

struct GridBackground: View {
    let width: Int
    
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    let h = FDTimeSlot.list.count
    
    var body: some View {
        Canvas { context, size in
            let separatorColor = Color.secondary.opacity(0.5)
            
            // draw horizontal lines
            for i in 0...h {
                let start = CGPoint(x: 0, y: CGFloat(i) * dy)
                let end = CGPoint(x: CGFloat(width) * dx, y: CGFloat(i) * dy)
                let path = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(path, with: .color(separatorColor))
            }
            
            // draw vertical lines
            for i in 0...width {
                let start = CGPoint(x: CGFloat(i) * dx, y: 0)
                let end = CGPoint(x: CGFloat(i) * dx, y: CGFloat(h) * dy)
                let path = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(path, with: .color(separatorColor))
            }
        }
        .frame(width: CGFloat(width) * dx, height: CGFloat(h) * dy)
    }
}
