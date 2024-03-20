//
//  FDDateValueChart.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-20.
//

import SwiftUI
import Charts

struct FDDateValueChartData: Identifiable, Equatable {
    var date: Date
    var value: Float
    var id = UUID()
}

struct FDDateValueChart: View {
    let data: [FDDateValueChartData]
    let backtrackRange: Int
    let color: Color
    
    private var areaBackground: Gradient {
        return Gradient(colors: [color.opacity(0.8), color.opacity(0.1)])
    }

    let filteredData: [FDDateValueChartData]
    
    init(data: [FDDateValueChartData], color:Color, backtrackRange: Int = 7) {
        self.data = data
        self.backtrackRange = backtrackRange
        self.color = color
        self.filteredData = Array(data.filter({d in d.date >= Calendar.current.date(byAdding: .day, value: -backtrackRange-1, to: .now)!}).sorted(by: {a, b in a.date > b.date}))
    }
    
    var body: some View {
        Chart {
            ForEach(filteredData) { d in
                LineMark(
                    x: .value("Date", d.date, unit: .day),
                    y: .value("", d.value)
                )
                .interpolationMethod(.cardinal)
                
                AreaMark(
                    x: .value("Date", d.date, unit: .day),
                    y: .value("", d.value)
                )
                .foregroundStyle(areaBackground)
                .interpolationMethod(.cardinal)
            }
        }
        .chartXScale(domain: Calendar.current.date(byAdding: .day, value: -backtrackRange-1, to: .now)! ... .now)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundColor(color)
    }
}

#Preview {
    let json = """
[
    [
        "2024-03-20",
        "33.44"
    ],
    [
        "2024-03-19",
        "64.44"
    ],
    [
        "2024-03-17",
        "1.68"
    ],
    [
        "2024-03-14",
        "32"
    ],
    [
        "2024-03-13",
        "1.52"
    ],
    [
        "2024-03-12",
        "23.76"
    ],
    [
        "2024-03-11",
        "83.12"
    ],
    [
        "2024-03-10",
        "1.68"
    ],
    [
        "2024-03-08",
        "64.95"
    ],
    [
        "2024-03-07",
        "55.76"
    ],
    [
        "2024-03-06",
        "22.8"
    ]
]
"""
    let dictionary = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [[String]]
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let data = dictionary.map { i in
        FDDateValueChartData(date: dateFormatter.date(from: i[0])!, value: Float(i[1])!)
    }
    return FDDateValueChart(data: data, color: .orange)
        .frame(width: 100, height: 40)
}
