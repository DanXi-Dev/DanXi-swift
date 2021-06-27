//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @State var discussions = [THDiscussion]()
    
    func refreshDiscussions() {
        loadDiscussions(1, completion: {(T) -> Void in discussions = T})
    }
    
    var body: some View {
        NavigationView {
            List(discussions) { cnt in
                Section {
                    Text(cnt.first_post!.content)
                }
            }
            .onAppear(perform: refreshDiscussions)
            .navigationBarTitle(Text("Tree Hole"))
        }
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
