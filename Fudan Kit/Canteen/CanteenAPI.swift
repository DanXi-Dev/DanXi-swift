import Foundation

/// API collection to get the canteen queuing time
///
/// The server will respond with an HTML page with a `script` tag. The content of the script tag is as following:
/// ```javascript
/// initStqkChart('chart_bb', ['光华楼\n光华咖啡', '光华楼-光华咖啡(学府餐饮)', '光华楼-光华咖啡(学校餐饮)', '北区食堂-北区二楼德保', '北区食堂-北区二楼（学府）', '北区\n千喜鹤', '北区\n新世纪早餐', '北区食堂-北区新世纪早餐(高校)', '北区\n清真', '北区食堂-北区清真(伊源)', '北区\n西餐厅', '北区食堂-北区西餐厅(乐烹西东)', '北区\n面包房', '北区食堂-北区面包房(东兴鼎昊)', '北区\n颐谷', '南区\n一楼同茂兴', '南区\n中快餐饮', '南区\n清真', '南区食堂-南区清真(伊源)', '南区\n南苑餐厅', '南区食堂-南苑餐厅(东大)', '南区\n同茂兴', '南区\n教工快餐', '南区食堂-教工快餐(东大)', '文科图书馆-文图咖啡', '文科图书馆-文图咖啡(报格)', '文图咖啡馆', '旦苑\n清真', '旦苑\n一楼大厅', '旦苑\n教授餐厅', '旦苑\n二楼大厅', '旦苑\n面包房', '旦苑-本部学校面包房(佳乐餐饮)', '旦苑-本部学校面包房(学校餐饮)', '旦苑-本部西餐厅(乐烹西东)', '旦苑\n西餐厅'],
///     ['0', '2', '0', '0', '39', '0', '0', '54', '0', '15', '0', '18', '0', '8', '63', '30', '11', '0', '8', '0', '26', '10', '0', '33', '0', '0', '0', '20', '60', '3', '25', '0', '21', '0', '11', '0'],
///     ['5', '2', '2', '77', '77', '118', '79', '66', '45', '36', '54', '30', '52', '21', '134', '167', '51', '49', '36', '100', '74', '113', '171', '109', '10', '6', '10', '79', '232', '44', '167', '75', '57', '57', '35', '46'])
/// initStqkChart('chart_fl', ['书院楼西园餐厅', '书院楼西园餐厅(养吉)', '书院楼风味餐厅', '书院楼风味餐厅(颐谷)', '护理学院', '护理学院', '枫林清真餐厅-枫林清真餐厅', '枫林清真餐厅-枫林清真餐厅(伊源)', '枫林食堂-枫林一楼科桥'],
///     ['0', '5', '0', '57', '2', '0', '0', '22', '43'],
///     ['49', '26', '167', '107', '21', '37', '60', '49', '144'])
/// initStqkChart('chart_jw', ['一楼中快', '二楼颐谷', '清真', '清真(伊源)', '点心', '点心(中快)', '点心(佳乐)', '花园餐厅', '花园餐厅(雷汇柏祺)'],
///     ['67', '21', '0', '10', '0', '0', '8', '0', '0'],
///     ['209', '133', '46', '40', '39', '29', '29', '10', '1'])
/// initStqkChart('chart_zj', ['一餐二楼教师', '一餐二楼自选', '一餐二楼风味', '一楼中快', '佳乐餐饮', '清真', '清真(伊源)'],
///     ['0', '0', '0', '15', '3', '0', '5'],
///     ['22', '41', '23', '67', '29', '32', '26'])
/// ```
/// We  parse the JavaScript code to get the information we need.
public enum CanteenAPI {
    
    /// Get canteen queuing time from server.
    ///
    /// - Important
    /// This API is only available during dining time. Otherwise it will throw `CampusError.notDiningTime`
    public static func getCanteenQueuing() async throws -> [Canteen] {
        // get data from server
        let url = URL(string: "https://my.fudan.edu.cn/simple_list/stqk")!
        let data = try await Authenticator.shared.authenticate(url)
        let htmlStr = String(data: data, encoding: String.Encoding.utf8)!
        
        // check for dining time
        if htmlStr.contains("仅在用餐时段开放") {
            throw CampusError.notDiningTime
        }
        
        // get and preprocess javascript string
        let element = try decodeHTMLElement(data, selector: "body > div.container-fluid > script")
        let script = try element.html().replacing("\\n", with: "") // remove "\n" text, not new line character, e.g.: '光华楼\n光华咖啡'
        
        // split a `initStqkChart` statement into 4 parts:
        // campus-name, dining-room-name (list), current (list), capacity (list)
        let canteenPattern = /initStqkChart\('(?<campus>.*)'.*(?<name>\[.*\]).*\n.*(?<current>\[.*\]),.*\n.*(?<capacity>\[.*\])\)/
        let matches = script.matches(of: canteenPattern)
        
        // construct canteen list
        var canteenList: [Canteen] = []
        let decoder = JSONDecoder()
        for match in matches {
            // hack: by replacing ' with ", we can convert list to a JSON-list and decode it with JSONDecoder
            let nameString = match.name.replacing("'", with: "\"").data(using: String.Encoding.utf8)!
            let nameList = try decoder.decode([String].self, from: nameString)
            let currentString = match.current.replacing("'", with: "").data(using: String.Encoding.utf8)!
            let currentList = try decoder.decode([Int].self, from: currentString)
            let capacityString = match.capacity.replacing("'", with: "").data(using: String.Encoding.utf8)!
            let capacityList = try decoder.decode([Int].self, from: capacityString)
            
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
            var diningRooms: [DiningRoom] = []
            for i in 0..<length {
                let diningRoom = DiningRoom(id: UUID(), name: nameList[i], current: currentList[i], capacity: capacityList[i])
                diningRooms.append(diningRoom)
            }
            let canteen = Canteen(id: UUID(), campus: campusName, diningRooms: diningRooms)
            canteenList.append(canteen)
        }
        
        return canteenList
    }
}
