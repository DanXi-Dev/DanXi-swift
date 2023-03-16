import Foundation

// MARK: - Request

struct FDCanteenAPI {
    static func getCanteenInfo() async throws -> [FDCanteen] {
        let url = URL(string: "http://my.fudan.edu.cn/simple_list/stqk")!
        let data = try await FDAuthAPI.auth(url: url)
        let htmlStr = String(data: data, encoding: String.Encoding.utf8)!
        if htmlStr.contains("仅在用餐时段开放") {
            throw FDError.notDiningTime
        }
        
        // prepare data
        let element = try processHTMLData(data, selector: "body > div.container-fluid > script")
        let script = try element.html().replacing("\\n", with: "") // remove "\n" text, not new line character
        
        /*   match javascript statement pattern:
             ```
             initChart('chart_fl', ['xx餐厅',...],
                ['0',...],
                ['49',...])
             ```                                         */
        let canteenPattern = /initChart\('(?<campus>.*)'.*(?<name>\[.*\]).*\n.*(?<current>\[.*\]),.*\n.*(?<capacity>\[.*\])\)/
        let matches = script.matches(of: canteenPattern)
        var canteenList: [FDCanteen] = []
        for match in matches {
            // decode list from string to JSON, need to replace ' to transform to valid JSON format
            let decoder = JSONDecoder()
            let nameList = try decoder.decode([String].self,
                                              from: match.name.replacing("'", with: "\"").data(using: String.Encoding.utf8)!)
            let currentList = try decoder.decode([Int].self,
                                                 from: match.current.replacing("'", with: "").data(using: String.Encoding.utf8)!)
            let capacityList = try decoder.decode([Int].self,
                                                  from: match.capacity.replacing("'", with: "").data(using: String.Encoding.utf8)!)
            
            
            // match campus name from code to text
            var campusName = ""
            if match.campus.contains("bb") {
                campusName = "本部"
            } else if match.campus.contains("fl") {
                campusName = "枫林"
            } else if match.campus.contains("jw") {
                campusName = "江湾"
            } else if match.campus.contains("zj") {
                campusName = "张江"
            }
            
            // construct data model
            let length = min(nameList.count, currentList.count, capacityList.count)
            var diningRooms: [FDDiningRoom] = []
            for i in 0..<length {
                let diningRoom = FDDiningRoom(name: nameList[i],
                                              current: currentList[i],
                                              capacity: capacityList[i])
                diningRooms.append(diningRoom)
            }
            let canteen = FDCanteen(campus: campusName,
                                    diningRooms: diningRooms)
            canteenList.append(canteen)
        }
        
        return canteenList
    }
}

// MARK: - Model

struct FDDiningRoom {
    let name: String
    let current: Int
    let capacity: Int
}

struct FDCanteen {
    let campus: String
    let diningRooms: [FDDiningRoom]
}

