import SwiftUI
import ViewUtils
import DanXiUI
import FudanKit
import FudanUI
import Utils

@MainActor
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model: AppModel
    @StateObject private var navigator = AppNavigator()
    @StateObject private var tabViewModel = TabViewModel() // an empty object, for environment object to exist
    
    @StateObject private var campusNavigator: CampusNavigator
    @StateObject private var forumNavigator: ForumNavigator
    
    @AppStorage("intro-done") var showIntro = true // shown once
    
    init() {
        let forumNavigator = ForumNavigator()
        let campusNavigator = CampusNavigator()
        let model = AppModel(campusNavigator: campusNavigator, forumNavigator: forumNavigator)
        
        self._campusNavigator = StateObject(wrappedValue: campusNavigator)
        self._forumNavigator = StateObject(wrappedValue: forumNavigator)
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        WideScreenReader {
            SplitNavigation(screen: $model.screen)
        } narrow: {
            TabNavigation(screen: $model.screen)
        }
        .environmentObject(navigator)
        .environmentObject(model)
        .environmentObject(tabViewModel)
        .environmentObject(forumNavigator)
        .environmentObject(campusNavigator)
        .onReceive(AppEvents.notification) { content in
            model.screen = .forum
        }
        .onReceive(AppEvents.notificationSettings) { content in
            model.screen = .settings
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                if !navigator.isCompactMode {
                    navigator.detailSubject.send((ForumSettingsSection.notification, false))
                }
            }
        }
        .onReceive(AppEvents.foldedContentSettings) { _ in
            model.screen = .settings
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                if !navigator.isCompactMode {
                    navigator.detailSubject.send((ForumSettingsSection.foldedContent, false))
                }
            }
        }
        .onAppear {
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .onChange(of: horizontalSizeClass) { horizontalSizeClass in
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .onOpenURL { url in
            model.handleOpenURL(url: url)
        }
        .sheet(isPresented: $showIntro) {
            WelcomeSheet()
                .environmentObject(model)
        }
        .onContinueUserActivity("com.fduhole.forum.viewing-hole") { userActivity in
            if let holeId = userActivity.userInfo?["hole-id"] as? Int {
                model.handleNavigation(navigation: .forumHole(holeId: holeId))
            }
        }
    }
}
