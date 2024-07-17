import SwiftUI
import DanXiKit
import ViewUtils

struct CurriculumModeratePage: View {
    var body: some View {
        AsyncContentView {
            try await CurriculumAPI.listAllSensitiveReviews()
        } content: { sensitives in
            CurriculumModeratePageContent(sensitives)
        }
    }
}

fileprivate struct CurriculumModeratePageContent: View {
    @State private var sensitives: [CurriculumSensitive]
    
    init(_ sensitives: [CurriculumSensitive]) {
        self.sensitives = sensitives
    }
    
    var body: some View {
        List {
            ForEach(sensitives) { sensitive in
                Text(sensitive.content)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                try await withHaptics {
                                    try await CurriculumAPI.setReviewSensitive(reviewId: sensitive.id, sensitive: true)
                                    sensitives.removeAll(where: { $0.id == sensitive.id })
                                }
                            }
                        } label: {
                            Text("Sensitive", bundle: .module)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                try await withHaptics {
                                    try await CurriculumAPI.setReviewSensitive(reviewId: sensitive.id, sensitive: true)
                                    sensitives.removeAll(where: { $0.id == sensitive.id })
                                }
                            }
                        } label: {
                            Text("Normal", bundle: .module)
                        }
                        .tint(.green)
                    }
            }
        }
        .navigationTitle(String(localized: "Sensitive Review", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}
