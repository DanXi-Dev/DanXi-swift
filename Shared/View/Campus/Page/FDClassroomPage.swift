import SwiftUI
import FudanKit

struct FDClassroomPage: View {
    @ScaledMetric private var dy = FDCalendarConfig.dy
    @AppStorage("campus-building-selection") private var building: Building = .empty
    var vpnLogged = false
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            Picker("Building", selection: $building) {
                if building == .empty {
                    Text("Not Selected").tag(Building.empty)
                }
                Text("第二教学楼").tag(Building.h2)
                Text("第三教学楼").tag(Building.h3)
                Text("第四教学楼").tag(Building.h4)
                Text("第五教学楼").tag(Building.h5)
                Text("第六教学楼").tag(Building.h6)
                Text("光华楼西辅楼").tag(Building.hgx)
                Text("光华楼东辅楼").tag(Building.hgd)
                Text("新闻学院").tag(Building.hq)
                Text("江湾校区").tag(Building.j)
                Text("张江校区").tag(Building.z)
                Text("枫林校区").tag(Building.f)
            }
            
            if building == .empty {
                HStack {
                    Spacer()
                    Text("Building not selected")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(50)
                .listRowSeparator(.hidden, edges: .bottom)
            } else {
                AsyncContentView(style: .widget) {
                    return try await ClassroomStore.shared.getCachedClassroom(building: building)
                } content: { (classrooms: [Classroom]) in
                    let filteredClassrooms = searchText.isEmpty ? classrooms : classrooms.filter({
                        $0.name.localizedCaseInsensitiveContains(searchText) || $0.schedules.contains(where: {
                            $0.courseId.localizedCaseInsensitiveContains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText)
                        })
                    })
                    if filteredClassrooms.count > 0 {
                        CalDimensionReader { dim in
                            HStack {
                                TimeslotsSidebar()
                                    .offset(x: 0, y: dim.dy / 2)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(alignment: .leading) {
                                        ClassroomHeader(classrooms: filteredClassrooms)
                                        CalendarEvents(classrooms: filteredClassrooms)
                                    }
                                }
                            }
                        }
                        .environment(\.calDimension, CalDimension(dx: 80))
                    } else {
                        Text("No Data")
                    }
                }
                .id(building)
                .listRowSeparator(.hidden, edges: .bottom)
            }
        }
        .searchable(text: $searchText)
        .listStyle(.inset)
        .navigationTitle("Classroom Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ClassroomHeader: View {
    let classrooms: [Classroom]
    private let h = ClassTimeSlot.list.count
    @ScaledMetric private var classroomFont = 15
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                ForEach(Array(classrooms.enumerated()), id: \.offset) { i, classroom in
                    let point = CGPoint(x: dim.dx / 2 + CGFloat(i) * dim.dx,
                                        y: dim.y)
                    VStack(alignment: .center) {
                        Spacer()
                        Text(classroom.name)
                            .font(.system(size: classroomFont))
                            .frame(width: dim.dx)
                        Text("\(classroom.capacity) seats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 2 * dim.y)
                    .position(point)
                }
            }
            .frame(width: CGFloat(classrooms.count) * dim.dx, height: 2 * dim.y)
        }
    }
}

fileprivate struct CalendarEvents: View {
    let classrooms: [Classroom]
    private let h = ClassTimeSlot.list.count
    @State private var scheduleSelected: CourseSchedule? = nil
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                GridBackground(width: classrooms.count)
                ForEach(Array(classrooms.enumerated()), id: \.offset) { i, classroom in
                    ForEach(classroom.schedules) { schedule in
                        FDCourseView(title: schedule.name, subtitle: schedule.teacher ?? "",
                                     span: schedule.end + 1 - schedule.start)
                        .position(x: (CGFloat(i) * dim.dx) + (dim.dx / 2),
                                  y: CGFloat(schedule.start + schedule.end) * dim.dy / 2 + dim.dy / 2)
                        .onTapGesture {
                            scheduleSelected = schedule
                        }
                    }
                }
            }
            .frame(width: CGFloat(classrooms.count) * dim.dx, height: CGFloat(h) * dim.dy)
            .sheet(item: $scheduleSelected) { schedule in
                ScheduleDetailSheet(schedule: schedule)
                    .presentationDetents([.medium])
            }
        }
    }
}

fileprivate struct ScheduleDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let schedule: CourseSchedule
    
    var body: some View {
        NavigationStack {
            List {
                LabeledContent {
                    Text(schedule.name)
                } label: {
                    Label("Course Name", systemImage: "magazine")
                }
                
                if let teacher = schedule.teacher {
                    LabeledContent {
                        Text(teacher)
                    } label: {
                        Label("Instructor", systemImage: "person")
                    }
                }
                LabeledContent {
                    Text(schedule.courseId)
                } label: {
                    Label("Course ID", systemImage: "number")
                }
                
                if let category = schedule.category {
                    LabeledContent {
                        Text(category)
                    } label: {
                        Label("Course Category", systemImage: "square.grid.3x3.middle.filled")
                    }
                }
                
                if let count = schedule.capacity {
                    LabeledContent {
                        Text(count)
                    } label: {
                        Label("Course Capacity", systemImage: "person.3.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .labelStyle(.titleOnly)
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
    NavigationStack {
        FDClassroomPage()
    }
}
