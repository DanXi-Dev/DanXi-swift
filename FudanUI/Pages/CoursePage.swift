import SwiftUI
import Combine
import ViewUtils
import Utils
import FudanKit
import TipKit
#if canImport(EventKitUI)
import EventKit
import EventKitUI
#endif

public struct CoursePage: View {
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var courseSettings = CourseSettings.shared
    @State private var loadingProgress: Float?
    
    private let loadingProgressPublisher = PassthroughSubject<Float, Never>()
    
    
    public init() { }
    
    public var body: some View {
        let asyncContentStyle = AsyncContentStyle {
            if let loadingProgress {
                ProgressView {
                    Text("Loading \(Int(loadingProgress * 100))%", bundle: .module)
                }
            } else {
                ProgressView {
                    Text("Loading", bundle: .module)
                }
            }
        } errorView: { error, retry in
            VStack {
                Text("Loading Failed", bundle: .module)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.callout)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button {
                    retry()
                } label: {
                    Text("Retry", bundle: .module)
                }
                .foregroundStyle(Color.accentColor)
            }
            .padding()
        }
        
        AsyncContentView(style: asyncContentStyle) {
            if let cachedModel = try? CourseModel.loadCache(for: campusModel.studentType) {
                return cachedModel
            }
            
            switch campusModel.studentType {
            case .undergrad:
                return try await CourseModel.freshLoadForUndergraduate()
            case .grad:
                return try await GraduateCourseAPI.LoadingProgress.$progressPublisher.withValue(loadingProgressPublisher) { // This sets the task-local publisher for this refresh task. It will be received by this instance of CoursePage to update the UI progress.
                    return try await CourseModel.freshLoadForGraduate()
                }
            case .staff:
                let description = String(localized: "Calendar for staff is not supported.", bundle: .module)
                throw LocatableError(description)
            }
        } content: { (model : CourseModel) in
            if let conflicts = model.getConflictingCourses(){
                ConflictResolver(conflits: conflicts)
            }
            else{
                CalendarContent(model: model)
            }
        }
        .onReceive(loadingProgressPublisher) { progress in
            loadingProgress = progress
        }
        .id(campusModel.studentType) // ensure the page will refresh when student type changes
        .navigationTitle(String(localized: "Calendar", bundle: .module))
    }
}


fileprivate struct CalendarContent: View {
    @EnvironmentObject private var tabViewModel: TabViewModel
    @ObservedObject private var campusModel = CampusModel.shared
    @StateObject var model: CourseModel
    @State private var showErrorAlert = false
    @State private var showExportSheet = false
    @State private var showColorSheet = false
    @State private var showManualDateSelectionSheet = false
    @available(iOS 17.0, *)
    private var exportToCalendarTip : ExportToCalendarTip {.init()}
    @AppStorage("calendar-theme-color") private var themeColor: ThemeColor = ThemeColor.none
    
    @ScaledMetric var minWidth = CalendarConfig.dx * 7
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("cal-top")
                
#if os(watchOS)
                toolbar
#endif
                
                Section {
                    if !model.courses.isEmpty {
                        Stepper(value: $model.week, in: model.weekRange) {
                            Text(String(localized: "Week \(String(model.week))", bundle: .module))
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
                                        .environment(\.courseTint, themeColor.color)
                                }
                            }
                        }
                    }
                }
            }
            .onReceive(tabViewModel.navigationControl) { _ in
                withAnimation {
                    proxy.scrollTo("cal-top")
                }
            }
            .refreshable {
                await model.refresh()
            }
#if targetEnvironment(macCatalyst)
            .listRowBackground(Color.clear)
#endif
        }
#if !os(watchOS)
        .toolbar {
            toolbar
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
        }
        .sheet(isPresented: $showColorSheet) {
            colorSheet
        }
        .sheet(isPresented: $showManualDateSelectionSheet) {
            ManualResetSemesterStartDateSheet()
        }
        .listStyle(.inset)
#endif
        .alert(String(localized: "Error", bundle: .module), isPresented: $showErrorAlert) {
            
        } message: {
            Text(verbatim: model.networkError?.localizedDescription ?? "")
        }
        .environmentObject(model)
    }
    
#if !os(watchOS)
    
    @ViewBuilder
    private var toolbar: some View {
        let baseMenu = Menu {
            Picker(selection: $model.semester) {
                ForEach(Array(model.filteredSemsters.enumerated().reversed()), id: \.offset) { _, semester in
                    Text(semester.name).tag(semester)
                }
            } label: {
                Text("Select Semester", bundle: .module)
            }
            .pickerStyle(.menu)
            .disabled(campusModel.studentType == .grad)
            
            Button {
                if #available(iOS 17.0, *) {
                    exportToCalendarTip.invalidate(reason: .actionPerformed)
                }
                Task(priority: .userInitiated) {
                    let eventStore = EKEventStore()
                    if #available(iOS 17, *) {
                        try await eventStore.requestWriteOnlyAccessToEvents()
                    } else {
                        try await eventStore.requestAccess(to: .event)
                    }
                    showExportSheet = true
                }
            } label: {
                Label {
                    Text("Export to Calendar", bundle: .module)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(model.semester.startDate == nil)
            
            Button{
                CourseSettings.shared.hiddenCourses = []
            } label: {
                Label {
                    Text("Clear Hidden Courses", bundle: .module)
                } icon: {
                    Image(systemName: "clear")
                }
            }
            
            Divider()
            
            Menu {
                Button {
                    showColorSheet = true
                } label: {
                    Label {
                        Text("Change Color", bundle: .module)
                    } icon: {
                        Image(systemName: "paintpalette")
                    }
                }
                
                Button {
                    showManualDateSelectionSheet = true
                } label: {
                    Label {
                        Text("Set Semester Start Date", bundle: .module)
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
            } label: {
                Text("Advanced Settings", bundle: .module)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .onChange(of: model.semester.semesterId) { _ in
            Task {
                await model.updateSemester()
            }
        }
        if #available(iOS 17.0, *) {
            baseMenu
                .popoverTip(exportToCalendarTip)
        } else {
            baseMenu
        }
    }
    
#else
    
    private var toolbar: some View {
        Picker(selection: $model.semester) {
            ForEach(Array(model.filteredSemsters.enumerated()), id: \.offset) { _, semester in
                Text(semester.name).tag(semester)
            }
        } label: {
            Text("Select Semester", bundle: .module)
        }
        .onChange(of: model.semester.semesterId) { _, _ in
            Task {
                await model.updateSemester()
            }
        }
    }
    
#endif
    
    private var colorSheet: some View {
        ColorSheet(themeColor: $themeColor)
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
    @State private var showLocationSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                LabeledContent {
                    Text(course.name)
                } label: {
                    Text("Course Name", bundle: .module)
                }
                LabeledContent {
                    Text(course.teacher)
                } label: {
                    Text("Instructor", bundle: .module)
                }
                
                LabeledContent {
                    Text(course.code)
                } label: {
                    Text("Course ID", bundle: .module)
                }
                
                LabeledContent {
                    if #available(iOS 17.0, *){
                        Button {
                            showLocationSheet = true
                        } label: {
                            Text(course.location)
                        }
                    }
                    else{
                        Text(course.location)
                    }
                } label: {
                    Text("Location", bundle: .module)
                }
            }
#if !os(watchOS)
            .listStyle(.insetGrouped)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .sheet(isPresented: $showLocationSheet){
                if #available(iOS 17.0, *) {
                    LocationSheet(location: course.location)
                }
            }
            .navigationTitle(String(localized: "Course Detail", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if canImport(EventKitUI)
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
            .navigationTitle(String(localized: "Export to Calendar", bundle: .module))
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
                            Text("Unselect All", bundle: .module)
                        }
                    } else {
                        Button {
                            selectedKeys = Set(allKeys)
                        } label: {
                            Text("Select All", bundle: .module)
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if selectedKeys.isEmpty {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                    } else {
                        Button {
                            Task(priority: .userInitiated) {
                                try await presentCalendarChooser()
                            }
                        } label: {
                            Text("Export", bundle: .module)
                        }
                    }
                }
            }
            .alert(String(localized: "Calendar Access not Granted", bundle: .module), isPresented: $showPermissionDeniedAlert) { }
            .alert(String(localized: "Error", bundle: .module), isPresented: $showExportError) {
                
            } message: {
                Text(verbatim: exportError?.localizedDescription ?? "")
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
#endif

private struct ManualResetSemesterStartDateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: CourseModel
    @State private var startDate: Date = .now
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker(selection: $startDate, displayedComponents: .date) {
                        Text("Semester Start Date", bundle: .module)
                    }
                } footer: {
                    Text("Semester Start Date Prompt", bundle: .module)
                }
            }
            .navigationTitle(String(localized: "Manually Set Semester Start Date", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        model.manualResetSemesterStartDate(startDate: startDate)
                        dismiss()
                    } label: {
                        Text("Confirm", bundle: .module)
                    }
                }
            }
            .onAppear {
                if let startDate = model.semester.startDate {
                    self.startDate = startDate
                }
            }
        }
    }
}

#Preview {
    let model = TabViewModel()
    
    CoursePage()
        .environmentObject(model)
        .previewPrepared()
}

private struct ConflictResolver: View {
    public let conflits: [Course]
    @State private var hiddenCourses: Set<String>

    public init(conflits: [Course]) {
        self.conflits = conflits
        self.hiddenCourses = Set<String>(CourseSettings.shared.hiddenCourses)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "Course conflict — select course(s) to hide", bundle: .module),
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                ForEach(conflits, id: \.code) { course in
                    HStack(alignment: .top) {
                        Toggle(isOn: Binding(
                            get: { hiddenCourses.contains(course.code) },
                            set: { on in
                                if on { hiddenCourses.insert(course.code) }
                                else  { hiddenCourses.remove(course.code) }
                            }
                        )) {
                            Text(course.name).font(.headline)
                            Text(course.code).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary)
                    )
                }
                
                HStack {
                    Spacer()
                    Button {
                        CourseSettings.shared.hiddenCourses = Array(hiddenCourses)
                    } label: {
                        Text("Confirm", bundle: .module)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
