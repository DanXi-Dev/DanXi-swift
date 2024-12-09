import Foundation
import UserNotifications
import Combine
import FudanKit
import DanXiUI
import SwiftUI
import Utils

@MainActor
class AppModel: ObservableObject {
    @Published var screen: AppScreen
    
    init() {
        if CampusModel.shared.loggedIn {
            screen = .campus
        } else if CommunityModel.shared.loggedIn {
            screen = .forum
        } else {
            screen = .settings
        }
    }
    
    func handleOpenURL(url: URL) {
        guard url.scheme == "fduhole" else { return }
        
        if let navigation = AppNavigations.initialize(from: url) {
            handleNavigation(navigation: navigation)
            return
        }
        
        if let action = AppActions.initialize(from: url) {
            Task {
                await handleAction(action: action)
            }
            return
        }
    }
    
    func handleNavigation(navigation: AppNavigations) {
        switch navigation {
        case .campus(let section):
            screen = .campus
            AppEvents.Navigation.campusSection.send(section)
        case .forumHole(holeId: let holeId):
            screen = .forum
            AppEvents.Navigation.forumHole.send(holeId)
        case .forumFloor(floorId: let floorId):
            screen = .forum
            AppEvents.Navigation.forumFloor.send(floorId)
        }
    }
    
    func handleAction(action: AppActions) async {
        switch action {
        case .setCampusCredential(let username, let password):
            guard !CampusModel.shared.loggedIn else { return }
            CampusModel.shared.forceLogin(username: username, password: password)
        case .setCommunityToken(let access, let refresh):
            guard !CommunityModel.shared.loggedIn else { return }
            await CommunityModel.shared.forceLogin(access: access, refresh: refresh)
        }
    }
}

/// URL Schemes that represents a navigation.
///
/// These URL schemes have host as `navigation`, and their paths and parameters represents navigation detail.
public enum AppNavigations {
    /// `fduhole://navigation/campus?section=<section>`
    case campus(section: String)
    /// `fduhole://navigation/forum-hole?hole-id=<hole-id>`
    case forumHole(holeId: Int)
    /// `fduhole://navigation/forum-floor?floor-id=<floor-id>`
    case forumFloor(floorId: Int)
    
    static func initialize(from url: URL) -> AppNavigations? {
        guard url.host == "navigation" else {
            return nil
        }
        
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        switch path {
        case "campus":
            guard let section = queryItems.first(where: { $0.name == "section" })?.value else {
                return nil
            }
            return .campus(section: section)
        
        case "forum-hole":
            guard let holeIdString = queryItems.first(where: { $0.name == "hole-id" })?.value,
                  let holeId = Int(holeIdString) else {
                return nil
            }
            return .forumHole(holeId: holeId)
        
        case "forum-floor":
            guard let floorIdString = queryItems.first(where: { $0.name == "floor-id" })?.value,
                  let floorId = Int(floorIdString) else {
                return nil
            }
            return .forumFloor(floorId: floorId)
        
        default:
            return nil
        }
    }
}

/// URL Schemes that represents an action.
///
/// These URL schemes have host as `action`, and their paths and parameters represents navigation detail.
public enum AppActions {
    /// `fduhole://action/set-campus-credential?username=<username>&password=<password>`
    case setCampusCredential(username: String, password: String)
    /// `fduhole://action/set-community-token?access=<access>&refresh=<refresh>`
    case setCommunityToken(access: String, refresh: String)
    
    static func initialize(from url: URL) -> AppActions? {
        guard url.host == "action" else {
            return nil
        }
        
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        switch path {
        case "set-campus-credential":
            guard let username = queryItems.first(where: { $0.name == "username" })?.value,
                  let password = queryItems.first(where: { $0.name == "password" })?.value else {
                return nil
            }
            return .setCampusCredential(username: username, password: password)
            
        case "set-community-token":
            guard let access = queryItems.first(where: { $0.name == "access" })?.value,
                  let refresh = queryItems.first(where: { $0.name == "refresh" })?.value else {
                return nil
            }
            return .setCommunityToken(access: access, refresh: refresh)
            
        default:
            return nil
        }
    }
}
