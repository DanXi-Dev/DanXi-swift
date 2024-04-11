import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    
    init(progress: Double) {
        self.progress = progress
    }
    
    init(value: Int, total: Int) {
        let progress = Double(value) / Double(total)
        if progress > 1.0 {
            self.progress = 1.0
        } else if progress < 0.0 {
            self.progress = 0.0
        } else {
            self.progress = progress
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.5),
                    lineWidth: 5
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 20)
    }
}
