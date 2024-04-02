//
//  FDDateValueChart.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-20.
//

import Charts
import SwiftUI

struct DateValueChartData: Identifiable, Equatable {
    var date: Date
    var value: Float
    var id = UUID()
    
    
    // From the last date of data, go back in time to the first day, and fill in missing data with 0s.
    // Then sort the data by date in descending order.
    // If there is no data, return [].
    // For example, if the input data is:
    // [
    //     DateValueChartData(date: "2024-03-20", value: 10),
    //     DateValueChartData(date: "2024-03-16", value: 30),
    //     DateValueChartData(date: "2024-03-18", value: 20),
    // ]
    // The output data should be:
    // [
    //     DateValueChartData(date: "2024-03-20", value: 10),
    //     DateValueChartData(date: "2024-03-19", value: 0),
    //     DateValueChartData(date: "2024-03-18", value: 20),
    //     ...
    //     DateValueChartData(date: "2024-03-16", value: 30),
    // ]
    static func formattedData(_ data: [DateValueChartData]) -> [DateValueChartData] {
        var rankedData = Array(data.sorted(by: { a, b in a.date > b.date }))
        let daysWithData = Set(rankedData.map { $0.date })
        
        if let lastDateOfData = daysWithData.max(),
           let firstDateOfData = daysWithData.min() {
            let dateInterval = Calendar.current.dateComponents([.day], from: firstDateOfData, to: lastDateOfData).day!
            for dayOffset in 0 ..< dateInterval {
                let dateToCheck = Calendar.current.date(byAdding: .day, value: -dayOffset, to: lastDateOfData)!
                if !daysWithData.contains(dateToCheck) {
                    rankedData.append(DateValueChartData(date: dateToCheck, value: 0))
                }
            }
            
            return Array(rankedData.sorted(by: { a, b in a.date > b.date }))
            
        } else {
            return []
        }
    }
}

struct DateValueChart: View {
    let data: [DateValueChartData]
    let backtrackRange: Int
    let color: Color
    
    private var areaBackground: Gradient {
        return Gradient(colors: [self.color.opacity(0.5), .clear])
    }
    
    var filteredData: [DateValueChartData]
    // set last date to now
    var lastDate: Date
    
    init(data: [DateValueChartData], color: Color, backtrackRange: Int = 7) {
        self.data = data
        self.backtrackRange = backtrackRange
        self.color = color
        self.filteredData = Array(DateValueChartData.formattedData(data)[0 ..< min(backtrackRange, data.count)])
        self.lastDate = Date()
        
        let daysWithData = Set(self.filteredData.map { $0.date })
        if !daysWithData.isEmpty {
            self.lastDate = daysWithData.max()!
        }
    }
    
    var body: some View {
        if self.filteredData.isEmpty {
            EmptyView()
        } else {
            Chart {
                ForEach(self.filteredData) { d in
                    LineMark(
                        x: .value("Date", d.date, unit: .day),
                        y: .value("", d.value)
                    )
                    .interpolationMethod(.cardinal)
                    
                    AreaMark(
                        x: .value("Date", d.date, unit: .day),
                        y: .value("", d.value)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(self.areaBackground)
                }
            }
            .chartXScale(domain: Calendar.current.date(byAdding: .day, value: -self.backtrackRange + 1, to: self.lastDate)! ... self.lastDate)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .foregroundColor(self.color)
        }
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
        DateValueChartData(date: dateFormatter.date(from: i[0])!, value: Float(i[1])!)
    }
    return DateValueChart(data: data, color: .orange)
        .frame(width: 100, height: 40)
}
