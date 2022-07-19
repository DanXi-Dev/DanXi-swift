import SwiftUI

struct TreeHoleLoginPrompt: View {
    
    var body: some View {
        VStack {
            Text("Open Tree Hole")
                .font(.system(size: 35))
                .fontWeight(.heavy)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 30.0)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureEntry(imageName: "bell", title: "时刻保持最新", caption: "在您关注的帖子更新时，您将收到推送通知")
                FeatureEntry(imageName: "message", title: "分区讨论", caption: "在专门的空间里进行更专注的讨论")
                FeatureEntry(imageName: "pencil.and.outline", title: "轻松编辑", caption: "在帖子中使用LaTeX和Markdown语法")
            }
            .frame(width: 300)
            
            Spacer()
            
            Text("请前往设置内登录旦夕账号")
                .foregroundColor(.secondary)
                .bold()
                .padding(.bottom, 40.0)
        }
    }
}

struct FeatureEntry: View {
    let imageName: String
    let title: String
    let caption: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .font(.title)
                .foregroundColor(.accentColor)
                .padding(.trailing, 15.0)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .bold()
                Text(caption)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
            }
        }
    }
}

struct TreeHoleLoginPrompt_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TreeHoleLoginPrompt()
            TreeHoleLoginPrompt()
                .preferredColorScheme(.dark)
        }
    }
}
