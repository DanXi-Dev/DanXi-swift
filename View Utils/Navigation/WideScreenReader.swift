import SwiftUI

/**
 A view that switch between compact and regular view while preventing app to lose state.
 
 When the app enters background, the `horizontalSizeClass` will change between `.regular` and `.compact`.
 If the view directly depend on `horizontalSizeClass`, this change causes the view to recompute and lose state.
 This wrapper is a workaround.
 */
public struct WideScreenReader<Wide: View, Narrow: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var model = WideScreenReaderModel()
    
    private var actualHorizontalSizeClass: UserInterfaceSizeClass? {
        if scenePhase == .active {
            model.storedHorizontalSizeClass = horizontalSizeClass
            return horizontalSizeClass
        } else {
            return model.storedHorizontalSizeClass
        }
    }
    
    private let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    private let wide: () -> Wide
    private let narrow: () -> Narrow
    
    public init(wide: @escaping () -> Wide, narrow: @escaping () -> Narrow) {
        self.wide = wide
        self.narrow = narrow
    }
    
    public var body: some View {
        if isPhone || actualHorizontalSizeClass == .compact {
            narrow()
        } else {
            wide()
        }
    }
}

private class WideScreenReaderModel: ObservableObject {
    var storedHorizontalSizeClass: UserInterfaceSizeClass? = nil
}
