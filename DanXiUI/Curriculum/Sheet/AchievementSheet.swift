import SwiftUI
import DanXiKit
import ViewUtils
import Foundation

struct AchievementSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    var obtainDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: achievement.obtainDate)
    }

    var body: some View {
        
        NavigationStack {
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
            .navigationTitle(String(localized: "Achievement Detail", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Close", bundle: .module)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

