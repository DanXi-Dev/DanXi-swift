//
//  CardView.swift
//  DanXi-native
//
//  Created by Singularity on 2022/9/13.
//

import SwiftUI

struct CardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            self.content
        }
        .cardStyle()
    }
}

struct CardStyle: ViewModifier {
    let colors: [Color]
    
    func body(content: Content) -> some View {
        content
            .padding(15)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(20)
            .shadow(radius: 20)
            .aspectRatio(1, contentMode: .fill)
            .foregroundColor(.white)
    }
}

extension View {
    func cardStyle(colors: [Color] = [.purple, .indigo]) -> some View {
        modifier(CardStyle(colors: colors))
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EcardView()
            .frame(width: 180, height: 180)
        }
    }
}
