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
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            //.frame(width: size, height: size, alignment: .topLeading)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(30)
            .shadow(radius: 30)
            .aspectRatio(1, contentMode: .fill)
    }
}

extension View {
    func cardStyle(colors: [Color] = [.purple, .indigo], size: CGFloat = 200) -> some View {
        modifier(CardStyle(colors: colors, size: size))
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardView(title: "校园卡消费") {
                VStack {
                    HStack {
                        Text("12:00 北区")
                        Spacer()
                        Text("¥500")
                    }
                    HStack {
                        Text("13:00 南区")
                        Spacer()
                        Text("¥600")
                    }
                    HStack {
                        Text("13:30 交大")
                        Spacer()
                        Text("¥0")
                    }
                    HStack {
                        Text("14:30 同济")
                        Spacer()
                        Text("¥10")
                    }
                    HStack {
                        Text("18:30 财大")
                        Spacer()
                        Text("¥-10")
                    }
                }
                .font(.caption)
                Spacer()
                HStack {
                    Spacer()
                    Text("余额")
                    Spacer()
                    Text("¥10000.00")
                }
                .font(.body)
            }
            .preferredColorScheme(.dark)
        }
    }
}
