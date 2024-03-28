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
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Select Semester", selection: $model.semester) {
                        ForEach(Array(model.semesters.enumerated()), id: \.offset) { _, semester in
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
//                parent.model.exportToCalendar(calendar)
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
