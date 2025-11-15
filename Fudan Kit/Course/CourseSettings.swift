import SwiftUI
import Utils

public class CourseSettings: ObservableObject {
    public static let shared = CourseSettings()

    @AppStorage("hidden-courses") public var hiddenCourses : [String] = []

}
