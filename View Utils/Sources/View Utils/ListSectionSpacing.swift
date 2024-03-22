import SwiftUI
import SwiftUIIntrospect

extension View {
    
    @available(iOS 16, *)
    /// A backport of `listSectionSpacing`.
    ///
    /// This API cannot use `@backDeployed` because it returns an opaque type
    public func sectionSpacing(_ spacing: CGFloat) -> some View {
        if #available(iOS 17, *) {
            return self.listSectionSpacing(spacing)
        } else {
            return self
                .introspect(.list(style: .insetGrouped), on: .iOS(.v16)) { collectionView in
                     var layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                     layoutConfig.headerMode = .supplementary
                     layoutConfig.headerTopPadding = spacing
                     layoutConfig.footerMode = .supplementary
                     let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
                     collectionView.collectionViewLayout = listLayout
                     
                }
        }
    }
}
