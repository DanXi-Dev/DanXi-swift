import SwiftUI

struct FDClassroomPage: View {
    @ScaledMetric private var dy = FDCalendarConfig.dy
    @AppStorage("building-selection") private var building: FDBuilding = .empty
    var vpnLogged = false
    
    var body: some View {
        List {
            Picker("Select Building", selection: $building) {
                if building == .empty {
                    Text("Not Selected").tag(FDBuilding.empty)
                }
                Text("第二教学楼").tag(FDBuilding.h2)
                Text("第三教学楼").tag(FDBuilding.h3)
                Text("第四教学楼").tag(FDBuilding.h4)
                Text("第五教学楼").tag(FDBuilding.h5)
                Text("第六教学楼").tag(FDBuilding.h6)
                Text("光华楼西辅楼").tag(FDBuilding.hgx)
                Text("光华楼东辅楼").tag(FDBuilding.hgd)
                Text("新闻学院").tag(FDBuilding.hq)
                Text("江湾校区").tag(FDBuilding.j)
                Text("张江校区").tag(FDBuilding.z)
                Text("枫林校区").tag(FDBuilding.f)
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
                    if !vpnLogged {
                        try await FDWebVPNAPI.login()
                    }
                    return try await FDClassroomAPI.getClassrooms(building: building)
                } content: { classrooms in
                    CalDimensionReader { dim in
                        HStack {
                            TimeslotsSidebar()
                                .offset(x: 0, y: dim.dy / 2)
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(alignment: .leading) {
                                    ClassroomHeader(classrooms: classrooms)
                                    ClanedarEvents(classrooms: classrooms)
                                }
                            }
                        }
                    }
                    .environment(\.calDimension, CalDimension(dx: 80))
                }
                .id(building)
                .listRowSeparator(.hidden, edges: .bottom)
            }
        }
        .listStyle(.inset)
        .navigationTitle("Empty Classrooms")
    }
}

fileprivate struct ClassroomHeader: View {
    let classrooms: [FDClassroom]
    private let h = FDTimeSlot.list.count
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

fileprivate struct ClanedarEvents: View {
    let classrooms: [FDClassroom]
    private let h = FDTimeSlot.list.count
    @State private var eventSelected: FDEvent?
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                GridBackground(width: classrooms.count)
                ForEach(Array(classrooms.enumerated()), id: \.offset) { i, classroom in
                    ForEach(Array(classroom.courses.enumerated()), id: \.offset) { _, course in
                        FDCourseView(title: course.name, subtitle: course.teacher ?? "",
                                     span: course.end + 1 - course.start)
                        .position(x: (CGFloat(i) * dim.dx) + (dim.dx / 2),
                                  y: CGFloat(course.start + course.end) * dim.dy / 2 + dim.dy / 2)
                        .onTapGesture {
                            eventSelected = course
                        }
                    }
                }
            }
            .frame(width: CGFloat(classrooms.count) * dim.dx, height: CGFloat(h) * dim.dy)
            .sheet(item: $eventSelected) { event in
                EventDetailSheet(event: event)
                    .presentationDetents([.medium])
            }
        }
    }
}

fileprivate struct EventDetailSheet: View {
    let event: FDEvent
    
    var body: some View {
        NavigationStack {
            List {
                LabeledContent {
                    Text(event.name)
                } label: {
                    Label("Course Name", systemImage: "magazine")
                }
                
                if let teacher = event.teacher {
                    LabeledContent {
                        Text(teacher)
                    } label: {
                        Label("Instructor", systemImage: "person")
                    }
                }
                
                if let id = event.courseId {
                    LabeledContent {
                        Text(id)
                    } label: {
                        Label("Course ID", systemImage: "number")
                    }
                }
                
                if let category = event.category {
                    LabeledContent {
                        Text(category)
                    } label: {
                        Label("Course Category", systemImage: "square.grid.3x3.middle.filled")
                    }
                }
                
                if let count = event.count {
                    LabeledContent {
                        Text(count)
                    } label: {
                        Label("Course Capacity", systemImage: "person.3.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
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
