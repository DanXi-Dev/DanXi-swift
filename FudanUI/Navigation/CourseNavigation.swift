//
//  CourseNavigation.swift
//
//
//  Created by Kavin Zhao on 2024-04-20.
//

import SwiftUI
import Utils

public struct CoursePageContent: View {
    @State private var path: NavigationPath
    
    public init() {
        path = NavigationPath()
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            CoursePage()
        }
        .onReceive(OnDoubleTapCalendarTabBarItem, perform: { _ in
            if path.isEmpty {
                CalendarScrollToTop.send()
            } else {
                path.removeLast(path.count)
            }
        })
    }
}
