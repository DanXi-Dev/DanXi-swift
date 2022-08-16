import SwiftUI

struct WelcomePage: View {
    
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
                FeatureEntry(imageName: "bell", title: "TH Feature 1", caption: "TH Detail 1")
                FeatureEntry(imageName: "message", title: "TH Feature 2", caption: "TH Detail 2")
                FeatureEntry(imageName: "pencil.and.outline", title: "TH Feature 3", caption: "TH Detail 3")
            }
            .frame(width: 300)
            
            Spacer()
            
            Text("Go to Settings Page to Login")
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

struct WelcomePage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomePage()
            WelcomePage()
                .preferredColorScheme(.dark)
        }
    }
}
