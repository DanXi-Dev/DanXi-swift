#if !os(watchOS)
import SwiftUI
import SwiftUIIntrospect

extension View {
    /// Control spacing between `Section` in `List`
    ///
    /// - Important:
    ///   Below iOS 17, the section's `header` will not display.
    ///   Use alternative method, like `listRowBackground` to display content on older systems.
    public func compactSectionSpacing(spacing: CGFloat? = nil) -> some View {
        self.modifier(CompactSectionSpacing(spacing: spacing))
    }
}

struct CompactSectionSpacing: ViewModifier {
    let spacing: CGFloat?
    
    @available(iOS 17.0, *)
    private var sectionSpacing: ListSectionSpacing {
        if let spacing = spacing {
            return .custom(spacing)
        }
        return .compact
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.listSectionSpacing(sectionSpacing)
        } else if #available(iOS 16.2, *) {
            content
                .introspect(.list(style: .insetGrouped), on: .iOS(.v16)) { collectionView in
                    let layout = UICollectionViewCompositionalLayout() { sectionIndex, environment in
                        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                        
                        /*
                         Current implementation will hide section's header.
                         If you want to display the section header, you can set
                         ```
                         configuration.headerMode = .supplementary
                         ```
                         However, if the section doesn't have a header,
                         this will cause app to **CRASH**.
                         
                         Therefore, you should set this property based on sectionIndex.
                         
                         However, which section will have a header must leave to caller to decide.
                         It's hard to design a succinct API.
                         
                         I decide to simply hide all headers in older platforms and let caller to implement
                         availability test.
                         */
                        
                        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                        section.contentInsets.top = spacing ?? 10
                        section.contentInsets.bottom = 0
                        return section
                    }
                    collectionView.collectionViewLayout = layout
                }
        } else {
            content
        }
    }
}
#endif
