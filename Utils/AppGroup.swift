//
//  AppGroup.swift
//  Utils
//
//  Created by Kavin Zhao on 2024-05-02.
//

import Disk

public let AppGroupName = "group.com.fduhole.danxi"

public extension Disk.Directory {
    static let appGroup = Disk.Directory.sharedContainer(appGroupName: AppGroupName)
}
