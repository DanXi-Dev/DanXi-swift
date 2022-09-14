//
//  EcardView.swift
//  DanXi-native
//
//  Created by Singularity on 2022/9/14.
//

import SwiftUI

struct EcardView: View {
    var body: some View {
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
                    Text("13:30 交大")
                    Spacer()
                    Text("¥0")
                }
            }
            .font(.caption)
            Spacer()
            HStack {
                Spacer()
                Text("¥10000.00")
            }
            .font(.body)
        }
    }
}

struct EcardView_Previews: PreviewProvider {
    static var previews: some View {
        EcardView()
            .frame(width: 180, height: 180)
    }
}
