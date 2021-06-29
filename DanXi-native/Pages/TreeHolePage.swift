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
    @State private var currentDiscussionSequentialId = 0
    @State private var isLoading = true
    
    func refreshDiscussions() {
        currentPage = 1
        async {
            do {
                isLoading = true
                discussions = try await loadDiscussions(currentPage)
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
                discussions.append(contentsOf: try await loadDiscussions(currentPage) as [THDiscussion])
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
                ProgressView()
                    .navigationTitle("treehole")
            }
            else {
                List(discussions) { discussion in
                    ZStack {
                        THPostView(discussion: discussion)
                            .onAppear {
                                // Load next page when needed
                                currentDiscussionSequentialId += 1
                                // TODO: WARNING: This code contains LOTS of bugs
                                if (discussions.count - currentDiscussionSequentialId <= 5 && !isLoading) {
                                    loadNextPage()
                                    print("loading next page \(currentPage)")
                                }
                            }
                            .navigationTitle("treehole")
                        Text("\(currentDiscussionSequentialId)")
                        NavigationLink(destination: THPostView(discussion: discussion)) {
                            EmptyView()
                        }
                    }
                }
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
