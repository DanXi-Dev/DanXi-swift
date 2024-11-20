import SwiftUI
import ViewUtils
import DanXiKit
import Utils
import Disk


// MARK: Preview Wrapper

enum PreviewWrapper {
    case navigation
    case list
    case sheet
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
                case .list:
                    List {
                        content
                    }
                case .sheet:
                    List {
                        
                    }
                    .sheet(isPresented: .constant(true)) {
                        content
                    }
                }
            } else {
                content
            }
        }
        .environmentObject(AppNavigator())
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
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        var iso8601TimeString = dateString
        if !iso8601TimeString.contains("+") && !iso8601TimeString.contains("Z") {
            iso8601TimeString.append("+00:00") // add timezone manually
        }
        
        let formatter = ISO8601DateFormatter()
        if iso8601TimeString.contains(".") {
            formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
        } else {
            formatter.formatOptions = [.withTimeZone, .withInternetDateTime]
        }
        if let date = formatter.date(from: iso8601TimeString) {
            return date
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
    }
    return try! decoder.decode(T.self, from: data)
}

func setupPreview() async {
    DivisionStore.shared.divisions = decodePreviewData(filename: "divisions", directory: "forum")
    ProfileStore.shared.profile = decodePreviewData(filename: "profile", directory: "forum")
    ProfileStore.shared.initialized = true
    TagStore.shared.tags = decodePreviewData(filename: "tags", directory: "forum")
    TagStore.shared.initialized = true
}
