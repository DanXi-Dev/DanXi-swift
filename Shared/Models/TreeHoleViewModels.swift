import Alamofire
import Foundation
import Combine

let BASE_URL = "https://api.fduhole.com"

class OTHolesViewModel: ObservableObject {
    @Published var data = [OTHole]()

    public var token: String?

    var encounteredError: LocalizedError?
    var endReached = false
    var currentPage = 1
    var divisionId = 1 {
        didSet {
            self.fetchData()
        }
    }

    let url = URL(string: BASE_URL + "/holes")!
    private var cancellable: AnyCancellable?

    func fetchData() {
        encounteredError = nil
        guard token != nil else {
            encounteredError = TreeHoleError.notInitialized
            return
        }
        cancellable = AF.request(url, method: .get, parameters: ["division_id": self.divisionId, "start_time": data.last?.time_created], headers: ["Authorization": token!])
            .validate()
            .publishDecodable(type: [OTHole].self)
            .tryMap { $0.data! }
            .decode(type: [OTHole].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .catch { _ in Just(self.data) }
            .sink { [weak self] in
                self?.currentPage += 1
                self?.data.append(contentsOf: $0)
                if $0.isEmpty {
                    self?.endReached = true
                }
            }
    }
}



