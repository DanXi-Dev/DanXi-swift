import SwiftUI
import ViewUtils
import Utils
import FudanKit
import EventKit
import EventKitUI

public struct CoursePage: View {
    @ObservedObject private var campusModel = CampusModel.shared
    
    public init() { }
    
    public var body: some View {
        AsyncContentView { forceReload in
            let context = ConfigurationCenter.configuration.semesterStartDate
            
            if !forceReload {
                if let cachedModel = try? CourseModel.loadCache(for: campusModel.studentType) {
                    cachedModel.receiveUndergraduateStartDateContextUpdate(startDateContext: context)
                    return cachedModel
                }
            }
            
            switch campusModel.studentType {
            case .undergrad:
                return try await CourseModel.freshLoadForUndergraduate(startDateContext: context)
            case .grad:
                return try await CourseModel.freshLoadForGraduate()
            case .staff:
                throw URLError(.unknown) // calendar for staff is not supported
            }
        } content: { model in
            CalendarContent(model: model)
        }
        .id(campusModel.studentType) // ensure the page will refresh when student type changes
        .navigationTitle("Calendar")
    }
}

fileprivate struct CalendarContent: View {
    @StateObject var model: CourseModel
    @State private var showErrorAlert = false
    @State private var showExportSheet = false
    
    @ScaledMetric var minWidth = CalendarConfig.dx * 7
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("cal-top")
                
                Section {
                    Picker("Select Semester", selection: $model.semester) {
                        ForEach(Array(model.filteredSemsters.enumerated()), id: \.offset) { _, semester in
                            Text(semester.name).tag(semester)
                        }
                    }
                    
                    if !model.courses.isEmpty {
                        Stepper(value: $model.week, in: model.weekRange) {
                            Label("Week \(String(model.week))", systemImage: "calendar.badge.clock")
                                .labelStyle(.titleOnly)
                        }
                    }
                }
                #if targetEnvironment(macCatalyst)
                .listRowBackground(Color.clear)
                #endif
                
                Section {
                    HStack {
                        TimeslotsSidebar()
                        
                        ViewThatFits(in: .horizontal) {
                            GeometryReader { geometry in
                                VStack(alignment: .leading, spacing: 0) {
                                    DateHeader(model.weekStart)
                                    CalendarEvents()
                                }
                                .environment(\.calDimension, CalDimension(dx: geometry.size.width / 7))
                            }
                            .frame(minWidth: minWidth)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    DateHeader(model.weekStart)
                                    CalendarEvents()
                                }
                            }
                        }
                    }
                }
                #if targetEnvironment(macCatalyst)
                .listRowBackground(Color.clear)
                #endif
            }
            .onReceive(OnDoubleTapCalendarTabBarItem) {
                withAnimation {
                    proxy.scrollTo("cal-top")
                }
            }
        }
        .onReceive(ConfigurationCenter.semesterMapPublisher) { context in
            model.receiveUndergraduateStartDateContextUpdate(startDateContext: context)
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
                .environment(\EnvironmentValues.refresh as! WritableKeyPath<EnvironmentValues, RefreshAction?>, nil) // FIXME: a hacky way to disable .refreshable for child
        }
        .listStyle(.inset)
        .alert("Error", isPresented: $showErrorAlert) {
            
        } message: {
            Text(model.networkError?.localizedDescription ?? "")
        }
        .environmentObject(model)
    }
}

fileprivate struct CalendarEvents: View {
    @EnvironmentObject private var model: CourseModel
    @State private var selectedCourse: Course?
    
    private let h = ClassTimeSlot.list.count
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
                    CourseView(title: course.name, subtitle: course.location,
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
    let eventStore = EKEventStore()
    
    private var allSelected: Bool {
        selectedKeys.count == allKeys.count
    }
    
    private func presentCalendarChooser() async throws {
        let eventStore = EKEventStore()
        
        if #available(iOS 17, *) {
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            if granted {
                showCalendarChooser = true
            } else {
                showPermissionDeniedAlert = true
            }
        } else {
            let granted = try await eventStore.requestAccess(to: .event)
            if granted {
                showCalendarChooser = true
            } else {
                showPermissionDeniedAlert = true
            }
        }
    }
    
    private func exportToCalendar(calendar: EKCalendar) {
        do {
            try model.exportToCalendar(to: calendar, keys: selectedKeys, eventStore: eventStore)
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
                            Text("Cancel")
                        }
                    } else {
                        Button {
                            Task(priority: .userInitiated) {
                                try await presentCalendarChooser()
                            }
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
                CalendarChooserSheet(selectedCalendar: $selectedCalendar, eventStore: eventStore)
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
    let eventStore: EKEventStore
    
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
