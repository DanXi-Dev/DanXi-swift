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
                    HStack {
                        TimeslotsSidebar()
                            .offset(x: 0, y: dy / 2)
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(alignment: .leading) {
                                ClassroomHeader(classrooms: classrooms)
                                ClanedarEvents(classrooms: classrooms)
                            }
                        }
                    }
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
    
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    @ScaledMetric private var classroomFont = 15
    
    var body: some View {
        ZStack {
            ForEach(Array(classrooms.enumerated()), id: \.offset) { i, classroom in
                let point = CGPoint(x: dx / 2 + CGFloat(i) * dx,
                                    y: y)
                VStack(alignment: .center) {
                    Spacer()
                    Text(classroom.name)
                        .font(.system(size: classroomFont))
                        .frame(width: dx)
                    Text("\(classroom.capacity) seats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 2 * y)
                .position(point)
            }
        }
        .frame(width: CGFloat(classrooms.count) * dx, height: 2 * y)
    }
}

fileprivate struct ClanedarEvents: View {
    let classrooms: [FDClassroom]
    
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    let h = FDCalendarConfig.h
    
    @ScaledMetric private var courseTitle = 15
    @ScaledMetric private var courseTeacher = 10
    
    @State private var eventSelected: FDEvent?
    
    var body: some View {
        ZStack {
            GridBackground(width: classrooms.count)
            ForEach(Array(classrooms.enumerated()), id: \.offset) { i, classroom in
                ForEach(Array(classroom.courses.enumerated()), id: \.offset) { _, course in
                    EventView(course)
                        .position(x: (CGFloat(i) * dx) + (dx / 2),
                                  y: CGFloat(course.start + course.end) * dy / 2 + dy / 2)
                        .onTapGesture {
                            eventSelected = course
                        }
                }
            }
        }
        .frame(width: CGFloat(classrooms.count) * dx, height: CGFloat(h) * dy)
        .sheet(item: $eventSelected) { event in
            EventDetailSheet(event: event)
                .presentationDetents([.medium])
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

fileprivate struct EventView: View {
    @ScaledMetric private var x = FDCalendarConfig.x
    @ScaledMetric private var y = FDCalendarConfig.y
    @ScaledMetric private var dx = FDCalendarConfig.dx
    @ScaledMetric private var dy = FDCalendarConfig.dy
    
    @ScaledMetric private var courseTitle = 15
    @ScaledMetric private var courseTeacher = 10
    
    let event: FDEvent
    let length: CGFloat
    let color: Color
    
    init(_ event: FDEvent) {
        self.event = event
        length = CGFloat(event.end + 1 - event.start) * FDCalendarConfig.dy
        color = randomColor(event.name)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.name)
                .bold()
                .padding(.top, 5)
                .foregroundStyle(color)
                .font(.system(size: courseTitle))
            if let teacher = event.teacher {
                Text(teacher)
                    .foregroundColor(color.opacity(0.5))
                    .font(.system(size: courseTeacher))
            }
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
    }
}


#Preview {
    NavigationStack {
        FDClassroomPage()
    }
}
