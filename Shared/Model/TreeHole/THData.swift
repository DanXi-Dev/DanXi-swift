import Foundation
import SwiftUI

@MainActor
class THData: ObservableObject {
    var token = ""
    @Published var endReached = false
    @Published var loading = false
    @Published var holes: [THHole] = []
    @Published var divisions: [THDivision] = []
    @Published var currentDivision = THDivision(id: 1, name: "树洞", description: "", pinned: [])
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools") // TODO: move to keychain
        token = defaults?.string(forKey: "user_credential") ?? ""
    }
    
    init(divisions: [THDivision], holes: [THHole]) { // for preview purpose
        self.divisions = divisions
        self.holes = holes
        currentDivision = self.divisions[0]
    }
    
    var notInitiazed: Bool {
        !loading && divisions.isEmpty
    }
    
    func refresh(initial: Bool = false) async {
        loading = true
        defer { loading = false }
        do {
            let fetchedDivisions = try await THloadDivisions(token: token)
            let fetchedHoles = try await THloadHoles(token: token, divisionId: fetchedDivisions[0].id)
            
            divisions = fetchedDivisions
            holes = fetchedHoles
            if initial { currentDivision = divisions[0] }
            
        } catch {
            print("refresh fail \(error)")
        }
    }
    
    func fetchMoreHoles() async {
        loading = true
        defer { loading = false }
        do {
            let newHoles =
            try await THloadHoles(token: token,
                                  startTime: holes.last?.iso8601CreateTime, //FIXME: Shouldn't this be Update Time instead of Create Time?
                                  divisionId: currentDivision.id)
            if newHoles.isEmpty {
                endReached = true
            } else {
                holes.append(contentsOf: newHoles)
            }
        } catch {
            endReached = true
        }
    }
    
    func changeDivision(division: THDivision) async {
        
        currentDivision = division
        endReached = false
        holes = []
        
        do {
            let fetchedHoles = try await THloadHoles(token: token, divisionId: division.id)
            
            holes = fetchedHoles
            
        } catch {
            print("change division fail \(error)")
        }
    }
}
