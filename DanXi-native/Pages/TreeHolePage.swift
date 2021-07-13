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
    @State private var endReached = false
    @State private var errorReason: String? = nil
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        currentPage = 1
        async {
            do {
                errorReason = nil
                isLoading = true
                discussions = try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated)
                isLoading = false
            }
            catch {
                isLoading = false
                errorReason = error.localizedDescription
            }
        }
    }
    
    func loadNextPage() {
        currentPage += 1
        async {
            do {
                errorReason = nil
                isLoading = true
                discussions.append(contentsOf: try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated) as [THDiscussion])
                isLoading = false
            }
            catch {
                isLoading = false
                errorReason = error.localizedDescription
            }
        }
    }
    
    var body: some View {
        if (errorReason == nil) {
            if (discussions.isEmpty) {
                List {
                    ProgressView()
                }
                .navigationTitle("treehole")
                .onAppear(perform: refreshDiscussions)
            }
            else {
                List {
                    Button(action: refreshDiscussions) {
                        HStack {
                            Text("refresh")
                            if (isLoading) {
                                ProgressView()
                            }
                        }
                    }
                    ForEach(discussions) { discussion in
                        VStack {
                            ZStack {
                                THPostView(discussion: discussion)
                                NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.posts)) {
                                    EmptyView()
                                }
                            }
                        }
                    }
                    if(!endReached) {
                        ProgressView()
                            .onAppear(perform: loadNextPage)
                    }
                    else {
                        Text("end_reached")
                    }
                }
                .navigationTitle("treehole")
            }
        }
        else {
            ErrorView(errorInfo: errorReason ?? "Unknown Error")
                .onTapGesture {
                    refreshDiscussions()
                }
        }
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
