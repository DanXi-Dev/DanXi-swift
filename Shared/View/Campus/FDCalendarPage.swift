import SwiftUI

struct FDCalendarPage: View {
    @StateObject var model = FDCalendarModel()
    
    var body: some View {
        LoadingPage(action: model.load) {
            NavigationStack {
                ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        FDCalendarSidebar()
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack {
                                FDCalendarDateHeader()
                                FDCalendarContent()
                            }
                        }
                    }
                }
                .navigationTitle("Calendar")
            }
            .environmentObject(model)
        }
    }
}

// MARK: - Controls

// TODO


// MARK: - Course UI

fileprivate struct FDCalendarContent: View {
    @EnvironmentObject var model: FDCalendarModel
    @State private var selectedCourse: FDCourse?
    
    var body: some View {
        ZStack {
            FDCalendarGrid()
            
            ForEach(model.courses) { course in
                let length = CGFloat(course.endTime + 1 - course.startTime) * dy
                let point = CGPoint(x: CGFloat(course.weekday) * dx + dx / 2,
                                    y: CGFloat(course.startTime) * dy + length / 2)
                let color = randomColor(course.name)
                VStack(alignment: .leading) {
                    Text(course.name)
                        .bold()
                        .padding(.top, 5)
                        .foregroundColor(color)
                        .font(.system(size: 15))
                    Text(course.location)
                        .foregroundColor(color.opacity(0.5))
                        .font(.system(size: 10))
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
                .position(point)
                .onTapGesture {
                    selectedCourse = course
                }
            }
        }
        .frame(width: 7 * dx, height: 12 * dy)
        .sheet(item: $selectedCourse) { course in
            FDCourseSheet(course: course)
                .presentationDetents([.medium])
        }
    }
}

fileprivate struct FDCourseSheet: View {
    let course: FDCourse
    
    var body: some View {
        NavigationStack {
            List {
                LabeledContent {
                    Text(course.name)
                } label: {
                    Label("Course Name", systemImage: "magazine")
                }
                LabeledContent {
                    Text(course.instructor)
                } label: {
                    Label("Instructor", systemImage: "person")
                }
                LabeledContent {
                    Text(course.code)
                } label: {
                    Label("Course ID", systemImage: "number")
                }
                LabeledContent {
                    Text(course.location)
                } label: {
                    Label("Location", systemImage: "mappin.and.ellipse")
                }
                
            }
            .navigationTitle("Course Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Frameworks

fileprivate struct FDCalendarDateHeader: View {
    @Environment(\.calendar) var calendar
    @EnvironmentObject var model: FDCalendarModel
    
    var body: some View {
        ZStack {
            ForEach(0..<7) { i in
                let point = CGPoint(x: dx / 2 + CGFloat(i) * dx, y: y/2)
                let date = calendar.date(byAdding: .day, value: i, to: model.weekStart)!
                let isToday = calendar.isDateInToday(date)
                VStack(alignment: .center, spacing: 10) {
                    Text(date.formatted(.dateTime.month(.defaultDigits).day()))
                        .foregroundColor(isToday ? .accentColor : .primary)
                        .font(.system(size: 15))
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 10))
                }
                .fontWeight(isToday ? .bold : .regular)
                .position(point)
            }
        }
        .frame(width: 7 * dx, height: y)
    }
}

fileprivate struct FDCalendarGrid: View {
    var body: some View {
        Canvas { context, size in
            let separatorColor = Color.secondary.opacity(0.5)
            
            // draw horizontal lines
            for i in 0...12 {
                let start = CGPoint(x: 0, y: CGFloat(i) * dy)
                let end = CGPoint(x: 7 * dx, y: CGFloat(i) * dy)
                let path = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(path, with: .color(separatorColor))
            }
            
            // draw vertical lines
            for i in 0...7 {
                let start = CGPoint(x: CGFloat(i) * dx, y: 0)
                let end = CGPoint(x: CGFloat(i) * dx, y: 12 * dy)
                let path = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(path, with: .color(separatorColor))
            }
        }
        .frame(width: 7 * dx, height: 12 * dy)
    }
}

fileprivate struct FDTimeSlotView: View {
    let timeSlot: FDTimeSlot
    
    var body: some View {
        VStack {
            Text(String(timeSlot.id))
                .font(.system(size: 14))
                .bold()
            Group {
                Text(timeSlot.startTime)
                Text(timeSlot.endTime)
            }
            .font(.system(size: 9))
        }
        .foregroundColor(.secondary)
    }
}

fileprivate struct FDCalendarSidebar: View {
    var body: some View {
        ZStack {
            ForEach(FDTimeSlot.list) { timeSlot in
                let point = CGPoint(x: x / 2 + 5,
                                    y: y - (dy / 2) + CGFloat(timeSlot.id) * dy)
                FDTimeSlotView(timeSlot: timeSlot)
                    .position(point)
            }
        }
        .frame(width: x, height: y + 12 * dy)
    }
}



// MARK: - Length Constants

fileprivate let x: CGFloat = 40
fileprivate let y: CGFloat = 40
fileprivate let dx: CGFloat = 60
fileprivate let dy: CGFloat = 70


// MARK: - Test Data

let courses = [FDCourse(id: 12, instructor: "张三", code: "PEDU1244334.3", name: "羽毛球", location: "H正大体育馆", startTime: 3, endTime: 5)]


struct FDCalendarPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FDCalendarPage()
        }
    }
}
