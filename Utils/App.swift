//
//  App.swift
//  Utils
//
//  Created by Kavin Zhao on 2024-04-07.
//

import Combine

public let OnDoubleTapCampusTabBarItem = PassthroughSubject<Void, Never>()
public let OnDoubleTapForumTabBarItem = PassthroughSubject<Void, Never>()
public let OnDoubleTapCurriculumTabBarItem = PassthroughSubject<Void, Never>()
public let OnDoubleTapCalendarTabBarItem = PassthroughSubject<Void, Never>()
public let OnDoubleTapSettingsTabBarItem = PassthroughSubject<Void, Never>()

public let CampusScrollToTop = PassthroughSubject<Void, Never>()
public let ForumScrollToTop = PassthroughSubject<Void, Never>()
public let CurriculumScrollToTop = PassthroughSubject<Void, Never>()
public let CalendarScrollToTop = PassthroughSubject<Void, Never>()
public let SettingsScrollToTop = PassthroughSubject<Void, Never>()