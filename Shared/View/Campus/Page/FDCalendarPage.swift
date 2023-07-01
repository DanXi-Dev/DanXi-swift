import SwiftUI
import EventKitUI
import EventKit

struct FDCalendarPageLoader: View {
    var body: some View {
        AsyncContentView {
            try await FDCalendarModel.load()
        } content: { model in
            FDCalendarPage(model)
        }
    }
}

struct FDCalendarPage: View {
    @StateObject var model: FDCalendarModel
    @State var showSettingSheet = false
    @State var showExportSheet = false
    @State var showPermissionDeniedAlert = false
    
    init(_ model: FDCalendarModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    func presentExportSheet() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                showExportSheet = true
            } else {
                showPermissionDeniedAlert = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if model.expired {
                        Button {
                            showSettingSheet = true
                        } label: {
                            Label("Current semester expired, reset semester", systemImage: "calendar.badge.exclamationmark")
                        }
                        .foregroundColor(.red)
                    }
                    
                    if model.semesterStart == nil {
                        Button {
                            showSettingSheet = true
                        } label: {
                            Label("Select Semester Start Date", systemImage: "calendar.badge.exclamationmark")
                        }
                        .foregroundColor(.red)
                    } else if !model.courses.isEmpty {
                        Stepper(value: $model.week, in: model.weekRange) {
                            Label("Week \(String(model.week))", systemImage: "calendar.badge.clock")
                        }
                    }
                }
                
                HStack {
                    TimeslotsSidebar()
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack {
                            DateHeader()
                            CalendarEvents()
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettingSheet = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentExportSheet()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(model.semesterStart == nil)
                }
            }
            .sheet(isPresented: $showSettingSheet) {
                FDCalendarSetting(semester: model.semester, startDate: model.semesterStart)
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet()
                    .ignoresSafeArea()
            }
            .alert("Calendar Access not Granted", isPresented: $showPermissionDeniedAlert) { }
            .environmentObject(model)
            .onReceive(FDCalendarModel.timetablePublisher) { timetable in
                model.matchTimetable()
                Task {
                    try model.save()
                }
            }
        }
    }
}

// MARK: - Controls

fileprivate struct FDCalendarSetting: View {
    @EnvironmentObject private var model: FDCalendarModel
    @State private var semester: FDSemester
    @State private var startDate: Date
    
    init(semester: FDSemester, startDate: Date?) {
        self._semester = State(initialValue: semester)
        self._startDate = State(initialValue: startDate ?? Date.now)
    }
    
    var body: some View {
        AsyncContentView {
            try await model.reloadSemesters()
        } content: { _ in
            Sheet("Calendar Settings") {
                try await model.refresh(semester, startDate)
            } content: {
                Picker(selection: $semester, label: Text("Select Semester")) {
                    ForEach(model.semesters) { semester in
                        Text(semester.formatted()).tag(semester)
                    }
                }
                
                DatePicker(selection: $startDate, in: ...Date.now, displayedComponents: [.date]) {
                    Label("Semester Start Date", systemImage: "calendar")
                }
            }
            .completed(model.semesterStart != nil)
            .onChange(of: semester) { semester in
                if let startDate = FDCalendarModel.getStartDateFromTimetable(semester) {
                    self.startDate = startDate
                }
            }
        }
    }
}

fileprivate struct ExportSheet: UIViewControllerRepresentable {
    @EnvironmentObject var model: FDCalendarModel
    @Environment(\.dismiss) var dismiss
    let eventStore = EKEventStore()

    func makeUIViewController(context: UIViewControllerRepresentableContext<ExportSheet>) -> UINavigationController {
        let chooser = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: eventStore)
        chooser.selectedCalendars = []
        chooser.delegate = context.coordinator
        chooser.showsDoneButton = true
        return UINavigationController(rootViewController: chooser)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<ExportSheet>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, EKCalendarChooserDelegate {
        let parent: ExportSheet

        init(_ parent: ExportSheet) {
            self.parent = parent
        }

        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            if let calendar = calendarChooser.selectedCalendars.first {
                parent.model.exportToCalendar(calendar)
            }
            parent.dismiss()
        }

        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            parent.dismiss()
        }
    }
}


// MARK: - Course UI

fileprivate struct CalendarEvents: View {
    @EnvironmentObject var model: FDCalendarModel
    @State private var selectedCourse: FDCourse?
    
    @ScaledMetric var x = FDCalendarConfig.x
    @ScaledMetric var y = FDCalendarConfig.y
    @ScaledMetric var dx = FDCalendarConfig.dx
    @ScaledMetric var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    @ScaledMetric var courseTitle = 15
    @ScaledMetric var courseLocation = 10
    
    var body: some View {
        ZStack {
            GridBackground()
            
            ForEach(model.weekCourses) { course in
                let length = CGFloat(course.end + 1 - course.start) * dy
                let point = CGPoint(x: CGFloat(course.weekday) * dx + dx / 2,
                                    y: CGFloat(course.start) * dy + length / 2)
                let color = randomColor(course.name)
                VStack(alignment: .leading) {
                    Text(course.name)
                        .bold()
                        .padding(.top, 5)
                        .foregroundColor(color)
                        .font(.system(size: courseTitle))
                    Text(course.location)
                        .foregroundColor(color.opacity(0.5))
                        .font(.system(size: courseLocation))
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
        .frame(width: 7 * dx, height: CGFloat(h) * dy)
        .sheet(item: $selectedCourse) { course in
            CourseDetailSheet(course: course)
                .presentationDetents([.medium])
        }
    }
}

fileprivate struct CourseDetailSheet: View {
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
            .listStyle(.insetGrouped)
            .navigationTitle("Course Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Frameworks

fileprivate struct DateHeader: View {
    @Environment(\.calendar) var calendar
    @EnvironmentObject var model: FDCalendarModel
    
    @ScaledMetric var x = FDCalendarConfig.x
    @ScaledMetric var y = FDCalendarConfig.y
    @ScaledMetric var dx = FDCalendarConfig.dx
    @ScaledMetric var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    @ScaledMetric var dateFont = 15
    @ScaledMetric var weekFont = 10
    
    var body: some View {
        ZStack {
            let weekStart = model.weekStart ?? FDCalendarModel.getWeekStart()
            ForEach(0..<7) { i in
                let point = CGPoint(x: dx / 2 + CGFloat(i) * dx, y: y/2)
                let date = calendar.date(byAdding: .day, value: i, to: weekStart)!
                let isToday = calendar.isDateInToday(date)
                VStack(alignment: .center, spacing: 10) {
                    if model.weekStart != nil {
                        Text(date.formatted(.dateTime.month(.defaultDigits).day()))
                            .foregroundColor(isToday ? .accentColor : .primary)
                            .font(.system(size: dateFont))
                    }
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: weekFont))
                }
                .fontWeight(isToday ? .bold : .regular)
                .position(point)
            }
        }
        .frame(width: 7 * dx, height: y)
    }
}

fileprivate struct GridBackground: View {
    @ScaledMetric var x = FDCalendarConfig.x
    @ScaledMetric var y = FDCalendarConfig.y
    @ScaledMetric var dx = FDCalendarConfig.dx
    @ScaledMetric var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    var body: some View {
        Canvas { context, size in
            let separatorColor = Color.secondary.opacity(0.5)
            
            // draw horizontal lines
            for i in 0...h {
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
                let end = CGPoint(x: CGFloat(i) * dx, y: CGFloat(h) * dy)
                let path = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(path, with: .color(separatorColor))
            }
        }
        .frame(width: 7 * dx, height: CGFloat(h) * dy)
    }
}

fileprivate struct FDTimeSlotView: View {
    let timeSlot: FDTimeSlot
    
    @ScaledMetric var courseSize = 14
    @ScaledMetric var timeSize = 9
    
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

fileprivate struct TimeslotsSidebar: View {
    @ScaledMetric var x = FDCalendarConfig.x
    @ScaledMetric var y = FDCalendarConfig.y
    @ScaledMetric var dx = FDCalendarConfig.dx
    @ScaledMetric var dy = FDCalendarConfig.dy
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

// MARK: - Length Constants

fileprivate struct FDCalendarConfig {
    static let x: CGFloat = 40
    static let y: CGFloat = 40
    static let dx: CGFloat = 60
    static let dy: CGFloat = 50
    static let h = FDTimeSlot.list.count
}
