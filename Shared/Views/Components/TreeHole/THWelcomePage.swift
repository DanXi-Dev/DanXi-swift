import SwiftUI

struct THWelcomePage: View {
    
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
                FeatureEntry(imageName: "bell", title: "th_feature1", caption: "th_detail1")
                FeatureEntry(imageName: "message", title: "th_feature2", caption: "th_detail2")
                FeatureEntry(imageName: "pencil.and.outline", title: "th_feature3", caption: "th_detail3")
            }
            .frame(width: 300)
            
            Spacer()
            
            Text("th_welcome_login_prompt")
                .foregroundColor(.secondary)
                .bold()
                .padding(.bottom, 40.0)
        }
    }
}

struct FeatureEntry: View {
    let imageName: String
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    
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
        .frame(height: 70.0)
    }
}

struct THWelcomePagePrompt_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            THWelcomePage()
            THWelcomePage()
                .preferredColorScheme(.dark)
        }
    }
}
