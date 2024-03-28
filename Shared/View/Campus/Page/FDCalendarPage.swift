import SwiftUI
import FudanKit
import EventKit
import EventKitUI

struct FDCalendarPage: View {
    @ObservedObject private var campusModel = CampusModel.shared
    
    var body: some View {
        AsyncContentView {
            if let cachedModel = try? CourseModel.loadCache(for: campusModel.studentType) {
                return cachedModel
            }
            
            switch campusModel.studentType {
            case .undergrad:
                return try await CourseModel.freshLoadForUndergraduate(startDateContext: [:])
            case .grad:
                return try await CourseModel.freshLoadForGraduate()
            case .staff:
                throw URLError(.unknown) // calendar for staff is not supported
            }
        } content: { model in
            CalendarContent(model: model)
        }
        .id(campusModel.studentType) // ensure the page will refresh when student type changes
    }
}

fileprivate struct CalendarContent: View {
    @StateObject var model: CourseModel
    @State private var showErrorAlert = false
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Select Semester", selection: $model.semester) {
                        ForEach(Array(model.semesters.enumerated()), id: \.offset) { _, semester in
                            Text(semester.name).tag(semester)
                        }
                    }
                    
                    Button("Debug") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "YYYY-MM-dd"
                        let date = dateFormatter.date(from: "2024-02-26")!
                        model.semester.startDate = date
                    }
                    
                    if !model.courses.isEmpty {
                        Stepper(value: $model.week, in: model.weekRange) {
                            Label("Week \(String(model.week))", systemImage: "calendar.badge.clock")
                                .labelStyle(.titleOnly)
                        }
                    }
                }
                
                Section {
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
            }
            .refreshable {
                await model.refresh(with: [:])
            }
            .toolbar {
                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(model.semester.startDate == nil)
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet()
            }
            .listStyle(.inset)
            .alert("Error", isPresented: $showErrorAlert) {
                
            } message: {
                Text(model.networkError?.localizedDescription ?? "")
            }
            .navigationTitle("Calendar")
            .environmentObject(model)
        }
    }
}

fileprivate struct CalendarEvents: View {
    @EnvironmentObject private var model: CourseModel
    @State private var selectedCourse: Course?
    
    private let h = FDCalendarConfig.h
    @ScaledMetric private var courseTitle = 15
    @ScaledMetric private var courseLocation = 10
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                GridBackground(width: 7)
                
                ForEach(model.coursesInThisWeek) { course in
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
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    
    var body: some View {
        NavigationStack {
            List {
                LabeledContent {
                    Text(course.name)
                } label: {
                    Label("Course Name", systemImage: "magazine")
                }
                LabeledContent {
                    Text(course.teacher)
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
            .labelStyle(.titleOnly)
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Course Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

fileprivate struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: CourseModel
    @State private var selectedCalendar: EKCalendar? = nil
    @State private var allKeys: [CourseModel.CourseKey] = []
    @State private var selectedKeys = Set<CourseModel.CourseKey>()
    @State private var showCalendarChooser = false
    @State private var showPermissionDeniedAlert = false
    @State private var showExportError = false
    @State private var exportError: Error?
    
    private var allSelected: Bool {
        selectedKeys.count == allKeys.count
    }
    
    private func presentCalendarChooser() {
        let eventStore = EKEventStore()
        eventStore.requestAccess { (granted, error) in
            if granted {
                showCalendarChooser = true
            } else {
                showPermissionDeniedAlert = true
            }
        }
    }
    
    private func exportToCalendar(calendar: EKCalendar) {
        do {
            try model.exportToCalendar(to: calendar, keys: selectedKeys)
            dismiss()
        } catch {
            exportError = error
        }
    }
    
    var body: some View {
        NavigationStack {
            List(allKeys, selection: $selectedKeys) {
                courseKey in
                VStack(alignment: .leading) {
                    Text(courseKey.name)
                    Text(courseKey.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(courseKey)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Export to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation {
                    allKeys = Array(model.calendarMap.keys)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if allSelected {
                        Button {
                            selectedKeys = []
                        } label: {
                            Text("Deselect All")
                        }
                    } else {
                        Button {
                            selectedKeys = Set(allKeys)
                        } label: {
                            Text("Select All")
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if selectedKeys.isEmpty {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .bold()
                        }
                    } else {
                        Button {
                            presentCalendarChooser()
                        } label: {
                            Text("Export")
                        }
                    }
                }
            }
            .alert("Calendar Access not Granted", isPresented: $showPermissionDeniedAlert) { }
            .alert("Error", isPresented: $showExportError) {
                
            } message: {
                Text(exportError?.localizedDescription ?? "")
            }
            .sheet(isPresented: $showCalendarChooser) {
                CalendarChooserSheet(selectedCalendar: $selectedCalendar)
                    .ignoresSafeArea()
                    .onDisappear {
                        if let selectedCalendar = selectedCalendar {
                            exportToCalendar(calendar: selectedCalendar)
                        }
                    }
            }
        }
    }
}

fileprivate struct CalendarChooserSheet: UIViewControllerRepresentable {
    @Binding var selectedCalendar: EKCalendar?
    @Environment(\.dismiss) private var dismiss
    private let eventStore = EKEventStore()
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CalendarChooserSheet>) -> UINavigationController {
        let chooser = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: eventStore)
        chooser.selectedCalendars = []
        chooser.delegate = context.coordinator
        chooser.showsDoneButton = true
        return UINavigationController(rootViewController: chooser)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<CalendarChooserSheet>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, EKCalendarChooserDelegate {
        let parent: CalendarChooserSheet
        
        init(_ parent: CalendarChooserSheet) {
            self.parent = parent
        }
        
        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            if let calendar = calendarChooser.selectedCalendars.first {
                parent.selectedCalendar = calendar
            }
            parent.dismiss()
        }
        
        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            parent.dismiss()
        }
    }
}



// MARK: - Length Constants

struct FDCalendarConfig {
    static let x: CGFloat = 40
    static let y: CGFloat = 40
    static let dx: CGFloat = 60
    static let dy: CGFloat = 50
    static let h = TimeSlot.list.count
}
