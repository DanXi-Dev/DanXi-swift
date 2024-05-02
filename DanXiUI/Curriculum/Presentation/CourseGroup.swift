import Foundation
import DanXiKit

extension CourseGroup {
    var reviews: [Review] {
        var reviewList: [Review] = []
        for course in courses {
            reviewList.append(contentsOf: course.reviews)
        }
        return reviewList
    }
    
    var teachers: [String] {
        var teachers = Set<String>()
        for course in courses {
            teachers.insert(course.teachers)
        }
        return Array(teachers)
    }
    
    var semesters: [Semester] {
        var semesters = Set<Semester>()
        for course in courses {
            let semester = Semester(year: course.year, semester: course.semester)
            semesters.insert(semester)
        }
        return Array(semesters)
    }
}

extension Course {
    var formattedSemester: LocalizedStringResource {
        return Semester(year: year, semester: semester).formatted()
    }
    
    func matchSemester(_ semester: Semester) -> Bool {
        return self.year == semester.year && self.semester == semester.semester
    }
}
