import SwiftUI
import ViewUtils
import FudanKit

struct ClassroomPage: View {
    @AppStorage("campus-building-selection") private var building: Building = .empty
    var vpnLogged = false
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            Picker(String(localized: "Building", bundle: .module), selection: $building) {
                if building == .empty {
                    Text("Not Selected").tag(Building.empty)
                }
                Text(verbatim: "第二教学楼").tag(Building.h2)
                Text(verbatim: "第三教学楼").tag(Building.h3)
                Text(verbatim: "第四教学楼").tag(Building.h4)
                Text(verbatim: "第五教学楼").tag(Building.h5)
                Text(verbatim: "第六教学楼").tag(Building.h6)
                Text(verbatim: "光华楼西辅楼").tag(Building.hgx)
                Text(verbatim: "光华楼东辅楼").tag(Building.hgd)
                Text(verbatim: "新闻学院").tag(Building.hq)
                Text(verbatim: "江湾校区").tag(Building.j)
                Text(verbatim: "张江校区").tag(Building.z)
                Text(verbatim: "枫林校区").tag(Building.f)
            }
#if targetEnvironment(macCatalyst)
            .listRowBackground(Color.clear)
#endif
            
            if building == .empty {
                HStack {
                    Spacer()
                    Text("Building not selected", bundle: .module)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(50)
                .listRowSeparator(.hidden, edges: .bottom)
                #if targetEnvironment(macCatalyst)
                .listRowBackground(Color.clear)
                #endif
            } else {
                AsyncContentView(style: .widget) {
                    try await ClassroomStore.shared.getCachedClassroom(building: building)
                } refreshAction: {
                    try await ClassroomStore.shared.getRefreshedClassroom(building: building)
                } content: { classrooms in
                    let filteredClassrooms = searchText.isEmpty ? classrooms : classrooms.filter({
                        $0.name.localizedCaseInsensitiveContains(searchText) || $0.schedules.contains(where: {
                            $0.courseId.localizedCaseInsensitiveContains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText)
                        })
                    })
                    
                    if filteredClassrooms.count > 0 {
                        HStack(alignment: .top) {
                            TimeslotsSidebar()
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ClassroomHeader(classrooms: filteredClassrooms)
                                    CalendarEvents(classrooms: filteredClassrooms)
                                }
                            }
                        }
                        .environment(\.calDimension, CalDimension(y: 80, dx: 80))
                    } else {
                        Text("No Data", bundle: .module)
                    }
                }
                .id(building)
                .listRowSeparator(.hidden, edges: .bottom)
#if targetEnvironment(macCatalyst)
                .listRowBackground(Color.clear)
#endif
            }
        }
        .searchable(text: $searchText)
        .listStyle(.inset)
        .navigationTitle(String(localized: "Classroom Schedule", bundle: .module))
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
                                        y: dim.y / 2)
                    VStack(alignment: .center) {
                        Spacer()
                        Text(classroom.name)
                            .font(.system(size: classroomFont))
                            .frame(width: dim.dx)
                        Text("\(classroom.capacity) seats", bundle: .module)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    .frame(height: dim.y)
                    .position(point)
                }
            }
            .frame(width: CGFloat(classrooms.count) * dim.dx, height: dim.y)
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
                        CourseView(title: schedule.name, subtitle: schedule.teacher ?? "",
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
                    Label(String(localized: "Course Name", bundle: .module), systemImage: "magazine")
                }

                if let teacher = schedule.teacher {
                    LabeledContent {
                        Text(teacher)
                    } label: {
                        Label(String(localized: "Instructor", bundle: .module), systemImage: "person")
                    }
                }

                LabeledContent {
                    Text(schedule.courseId)
                } label: {
                    Label(String(localized: "Course ID", bundle: .module), systemImage: "number")
                }

                if let category = schedule.category {
                    LabeledContent {
                        Text(category)
                    } label: {
                        Label(String(localized: "Course Category", bundle: .module), systemImage: "square.grid.3x3.middle.filled")
                    }
                }

                if let count = schedule.capacity {
                    LabeledContent {
                        Text(count)
                    } label: {
                        Label(String(localized: "Course Capacity", bundle: .module), systemImage: "person.3.fill")
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
                        Text("Done", bundle: .module)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Course Detail", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ClassroomPage()
    }
}
