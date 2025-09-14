import SwiftUI
import DanXiKit
import ViewUtils
import Foundation

struct AchievementPage: View {
    let achievement: Achievement
    
    var obtainDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: achievement.obtainDate)
    }

    
    var body: some View {
        VStack(spacing: 20) {
            Image(achievement.name, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(radius: 10)
            
            Text(achievement.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(String(localized: "Obtain Date: ", bundle: .module) + obtainDate)
                .font(.title2)
        }
        .padding()
    }
}
