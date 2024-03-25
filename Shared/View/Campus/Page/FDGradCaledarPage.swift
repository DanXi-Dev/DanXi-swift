import SwiftUI

struct FDGradCalendarPage: View {
    var body: some View {
        AsyncContentView { () -> FDGradCalendar in
            return try await FDGradAgendaAPI.getSemesters()
        } content: { calendar in
            CalendarPicker(calendar)
        }
    }
}

fileprivate struct CalendarPicker: View {
    let calendar: FDGradCalendar
    @State private var semester: FDGradTerm
    
    init(_ calendar: FDGradCalendar) {
        self.calendar = calendar
        self._semester = State(initialValue: calendar.current)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Picker(selection: $semester) {
                    ForEach(calendar.all) { term in
                        Text("\(term.year)年第\(term.term)学期").tag(term)
                    }
                } label: {
                    Text("Select Semester")
                }
                
                AsyncContentView(style: .widget) {
                    let courses = try await FDGradAgendaAPI.getAllCourses(term: semester)
                    let model = CalendarModel(calendar: calendar, semester: semester, courses: courses)
                    return model
                } content: { model in
                    CalendarContent(model: model)
                }
                .id(semester)
                .listRowSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle("Calendar")
        }
    }
}

fileprivate class CalendarModel: ObservableObject {
    let calendar: FDGradCalendar
    let semester: FDGradTerm
    
    let courses: Dictionary<Int, [FDGradCourse]>
    var currentCourses: [FDGradCourse] {
        courses[week] ?? []
    }
    
    @Published var week: Int
    var weekStart: Date {
        let calendar = Calendar.current
        let components = DateComponents(weekOfYear: week - 1)
        return calendar.date(byAdding: components, to: semester.startDay)!
    }
    
    init(calendar: FDGradCalendar, semester: FDGradTerm, courses: Dictionary<Int, [FDGradCourse]>) {
        self.calendar = calendar
        self.semester = semester
        self.courses = courses
        if semester.id == calendar.current.id {
            self.week = calendar.currentWeek
        } else {
            self.week = 1
        }
    }
}

fileprivate struct CalendarContent: View {
    @StateObject var model: CalendarModel
    
    var body: some View {
        Group {
            Stepper(value: $model.week, in: 1...model.semester.totalWeek) {
                Label("Week \(String(model.week))", systemImage: "calendar.badge.clock")
            }
            
            HStack {
                TimeslotsSidebar()
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack {
                        DateHeader(model.weekStart)
                        CourseTable(courses: model.currentCourses)
                    }
                }
            }
            .environmentObject(model)
        }
    }
}

fileprivate struct CourseTable: View {
    let courses: [FDGradCourse]
    
    @State private var selectedCourse: FDGradCourse?
    
    private let h = FDCalendarConfig.h
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                GridBackground(width: 7)
                
                ForEach(courses) { course in
                    let length = CGFloat(course.end + 1 - course.start) * dim.dy
                    let point = CGPoint(x: CGFloat(course.weekday - 1) * dim.dx + dim.dx / 2,
                                        y: CGFloat(course.start - 1) * dim.dy + length / 2)
                    FDCourseView(title: course.name, subtitle: course.location,
                                 span: course.end + 1 - course.start)
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
    
    let course: FDGradCourse
    
    var body: some View {
        NavigationStack {
            Form {
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
                    LabeledContent {
                        Text(String(course.credit))
                    } label: {
                        Label("Credit", systemImage: "graduationcap")
                    }
                }
                .labelStyle(.titleOnly)
                .listStyle(.insetGrouped)
            }
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

#Preview {
    FDGradCalendarPage()
}
