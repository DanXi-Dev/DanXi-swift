//
//  CampusInfoPage.swift
//  DanXi-native
//
//  Created by Singularity on 2022/9/13.
//

import SwiftUI

struct CampusInfoPage: View {
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 0, alignment: .top)]) {
            EcardView()
            EcardView()
            EcardView()
            EcardView()
            EcardView()
            EcardView()
        }
        .navigationTitle("校园信息")
    }
}

struct CampusInfoPage_Previews: PreviewProvider {
    static var previews: some View {
        CampusInfoPage()
    }
}
