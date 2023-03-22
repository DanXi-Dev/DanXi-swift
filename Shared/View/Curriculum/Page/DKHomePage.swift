import SwiftUI

struct DKHomePage: View {
    @State var courses: [DKCourseGroup] = []
    @State var searchText = ""
    
    var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            // TODO: search course ID
            return courses.filter { $0.name.contains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            LoadingPage(finished: !DXModel.shared.courses.isEmpty) {
                try await DXModel.shared.loadCurriculum()
                self.courses = DXModel.shared.courses
            } content: {
                List {
                    ForEach(searchResults) { course in
                        NavigationLink(value: course) {
                            DKCourseView(courseGroup: course)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
                .navigationTitle("Curriculum Board")
                .navigationDestination(for: DKCourseGroup.self) { course in
                    DKCoursePage(courseGroup: course)
                }
            }
        }
    }
}

struct DKHomePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DKHomePage()
        }
    }
}
