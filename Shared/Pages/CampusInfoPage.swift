//
//  CampusInfoPage.swift
//  DanXi-native
//
//  Created by Singularity on 2022/9/13.
//

import SwiftUI

struct CampusInfoPage: View {
    var body: some View {
        VStack {
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
            
        }
            .navigationTitle("校园信息")
    }
}

struct CampusInfoPage_Previews: PreviewProvider {
    static var previews: some View {
        CampusInfoPage()
    }
}
