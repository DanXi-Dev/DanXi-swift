import SwiftUI
import ViewUtils
import DanXiKit
import WebKit

public struct InnovationHomePage: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigator: AppNavigator
    @StateObject private var model = WebViewModel()
    
    public init() { }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                InnovationWebView(url: URL(string: "https://danta.fudan.edu.cn/lobby/1")!, frame: proxy.frame(in: .local))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(model)
                
                overlay
            }
        }
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                menu
            }
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        switch model.loadingStatus {
        case .completed:
            EmptyView()
        case .loading:
            VStack {
                ProgressView()
                Text("Loading", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .failed(let error):
            VStack {
                Text("Loading Failed", bundle: .module)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.callout)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button {
                    model.reload()
                } label: {
                    Text("Retry", bundle: .module)
                }
                .foregroundStyle(Color.accentColor)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var backButton: some View {
        Button {
            if model.canGoBack {
                model.goBack()
                return
            }
            
            if navigator.isCompactMode {
                dismiss()
            }
        } label: {
            Label {
                Text("Back", bundle: .module)
            } icon: {
                Image(systemName: "chevron.left")
            }
        }
        .disabled(!(model.canGoBack || navigator.isCompactMode)) // no need to go to home page in case of wide screen
    }
    
    private var menu: some View {
        Menu {
            if navigator.isCompactMode {
                Button {
                   dismiss()
                } label: {
                    Label {
                        Text("Community Home Page", bundle: .module)
                    } icon: {
                        Image(systemName: "house")
                    }
                }
            }
            
            Button {
                model.goBack()
            } label: {
                Label {
                    Text("Go Back", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.left")
                }
            }
            .disabled(!model.canGoBack)
            
            Button {
                model.goBack()
            } label: {
                Label {
                    Text("Go Forward", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.right")
                }
            }
            .disabled(!model.canGoBack)
            
            Button {
                model.reload()
            } label: {
                Label {
                    Text("Refresh", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

#Preview {
    NavigationStack {
        InnovationHomePage()
    }
    .environmentObject(AppNavigator())
}
