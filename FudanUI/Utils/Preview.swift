import SwiftUI
import FudanKit
import ViewUtils
import Utils
#if !os(watchOS)
import Disk
#endif

// MARK: Preview Wrapper

enum PreviewWrapper {
    case navigation
    case card
}

struct PreviewModifier: ViewModifier {
    let previewWrapper: PreviewWrapper?
    
    func body(content: Content) -> some View {
        AsyncContentView {
            await setupPreview()
        } content: {
            if let previewWrapper {
                switch previewWrapper {
                case .navigation:
                    NavigationStack {
                        content
                    }
                case .card:
                    List {
                        content
                            .tint(.primary)
                            .frame(height: 85)
                    }
                }
            } else {
                content
            }
        }
    }
}

extension View {
    func previewPrepared(wrapped: PreviewWrapper? = .navigation) -> some View {
        self.modifier(PreviewModifier(previewWrapper: wrapped))
    }
}

// MARK: Preview Data

func decodePreviewData<T: Decodable>(filename: String, directory: String? = nil) -> T {
    let file = if let directory {
        Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Preview/\(directory)")!
    } else {
        Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Preview")!
    }
    let data = try! Data(contentsOf: file)
    let decoder = JSONDecoder()
    return try! decoder.decode(T.self, from: data)
}

func setupPreview() async {
    await CampusModel.shared.forceLogin(username: "123456", password: "")
    
    let courseCacheURL = Bundle.module.url(forResource: "course", withExtension: "json", subdirectory: "Preview")!
    try! Disk.save(try! Data(contentsOf: courseCacheURL), to: .applicationSupport, as: "preview/fdutools/course-model.json")
    
    let walletLogs: [WalletLog] = decodePreviewData(filename: "wallet-logs", directory: "my")
    let electricityLogs: [ElectricityLog] = decodePreviewData(filename: "electricity-logs", directory: "my")
    let userInfo: UserInfo = decodePreviewData(filename: "userinfo", directory: "my")
    await MyStore.shared.setupPreivew(electricity: electricityLogs, wallet: walletLogs, user: userInfo)
    
    let transactions: [FudanKit.Transaction] = decodePreviewData(filename: "transactions")
    await WalletStore.shared.setupPreview(transactions: transactions)
    
    let routes: BusRoutes = decodePreviewData(filename: "bus")
    await BusStore.shared.setupPreview(routes: routes)
    
    let playgrounds: [Playground] = decodePreviewData(filename: "playgrounds", directory: "reservation")
    await ReservationStore.shared.setupPreview(playgrounds: playgrounds)
    
    let usage: ElectricityUsage = decodePreviewData(filename: "electricity")
    await ElectricityStore.shared.setupPreview(usage: usage)
    
    let exercise: [Exercise] = decodePreviewData(filename: "exercise", directory: "sport")
    let exerciseLogs: [ExerciseLog] = decodePreviewData(filename: "exercise-log", directory: "sport")
    await SportStore.shared.setupPreview(exercises: exercise, exerciseLogs: exerciseLogs)
    
    var classroomCache: [Building: [Classroom]] = [:]
    for building in Building.allCases {
        guard building != .empty else { continue }
        classroomCache[building] = decodePreviewData(filename: "\(building.rawValue)", directory: "classrooms")
    }
    await ClassroomStore.shared.setupPreview(classroomCache)
}
