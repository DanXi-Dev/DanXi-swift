//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @State private var discussions = [THDiscussion]()
    @State private var currentPage = 1
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        currentPage = 1
        async {
            do {
                isLoading = true
                discussions = try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated)
                isLoading = false
            }
            catch {
                isLoading = false
                fatalError()
            }
        }
    }
    
    func loadNextPage() {
        currentPage += 1
        async {
            do {
                isLoading = true
                discussions.append(contentsOf: try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated) as [THDiscussion])
                isLoading = false
            }
            catch {
                isLoading = false
                fatalError()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if (discussions.isEmpty) {
                List {
                    ProgressView()
                }
                .navigationTitle("treehole")
            }
            else {
                List(discussions) { discussion in
                    ZStack {
                        THPostView(discussion: discussion)
                        NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.posts)) {
                            EmptyView()
                        }
                    }
                }
                .navigationTitle("treehole")
            }
            Text("selectAPost")
        }
        .onAppear(perform: refreshDiscussions)
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
