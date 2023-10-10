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
    @StateObject private var model: FDCalendarModel
    @State private var showSettingSheet = false
    @State private var showExportSheet = false
    @State private var showPermissionDeniedAlert = false
    
    init(_ model: FDCalendarModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    func presentExportSheet() {
        let eventStore = EKEventStore()
        eventStore.requestAccess { (granted, error) in
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
                            DateHeader(model.weekStart)
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
                
                if FDCalendarModel.getStartDateFromTimetable(semester) == nil {
                    // provide the option for user to pick semester start date when match failed
                    DatePicker(selection: $startDate, displayedComponents: [.date]) {
                        Label("Semester Start Date", systemImage: "calendar")
                    }
                }
            }
            .onChange(of: semester) { semester in
                if let startDate = FDCalendarModel.getStartDateFromTimetable(semester) {
                    self.startDate = startDate
                }
            }
        }
    }
}

fileprivate struct ExportSheet: UIViewControllerRepresentable {
    @EnvironmentObject private var model: FDCalendarModel
    @Environment(\.dismiss) private var dismiss
    private let eventStore = EKEventStore()

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
    @EnvironmentObject private var model: FDCalendarModel
    @State private var selectedCourse: FDCourse?
    
    private let h = FDCalendarConfig.h
    @ScaledMetric private var courseTitle = 15
    @ScaledMetric private var courseLocation = 10
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                GridBackground(width: 7)
                ForEach(model.weekCourses) { course in
                    let length = CGFloat(course.end + 1 - course.start) * dim.dy
                    let point = CGPoint(x: CGFloat(course.weekday) * dim.dx + dim.dx / 2,
                                        y: CGFloat(course.start) * dim.dy + length / 2)
                    FDCourseView(title: course.name, subtitle: course.location,
                                 span: course.end - course.start + 1)
                    .position(point)
                    .onTapGesture {
                        selectedCourse = course
                    }
                }
            }
            .frame(width: 7 * dim.dx, height: CGFloat(h) * dim.dy)
            .sheet(item: $selectedCourse) { course in
                CourseDetailSheet(course: course)
                    .presentationDetents([.medium])
            }
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


// MARK: - Length Constants

struct FDCalendarConfig {
    static let x: CGFloat = 40
    static let y: CGFloat = 40
    static let dx: CGFloat = 60
    static let dy: CGFloat = 50
    static let h = FDTimeSlot.list.count
}
