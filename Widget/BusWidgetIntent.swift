//
//  BusWidgetIntent.swift
//  DanXi
//
//  Created by Yifan Fei on 4/19/24.
//

import AppIntents
import WidgetKit

struct BusScheduleIntent: WidgetConfigurationIntent {
    
    static let title: LocalizedStringResource = "Backyard"
    static let description: LocalizedStringResource  = "订阅校车时刻表"

    @Parameter(title: "始发地", default: .handan)
    var startPoint: CampusEnum

    @Parameter(title: "目的地", default: .fenglin)
    var endPoint: CampusEnum

    init(startPoint: CampusEnum = .handan, endPoint: CampusEnum = .fenglin) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        
    }
    
    init() {}
}

enum CampusEnum: String, AppEnum {
    case handan = "邯郸"
    case fenglin = "枫林"
    case jiangwan = "江湾"
    case zhangjiang = "张江"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "校区列表")

    static let caseDisplayRepresentations: [CampusEnum: DisplayRepresentation] = [
        .handan: DisplayRepresentation(title: "邯郸"),
        .fenglin: DisplayRepresentation(title: "枫林"),
        .jiangwan: DisplayRepresentation(title: "江湾"),
        .zhangjiang: DisplayRepresentation(title: "张江")
    ]
}
