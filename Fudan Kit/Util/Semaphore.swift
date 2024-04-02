//
//  File.swift
//  
//
//  Created by Kavin Zhao on 2024-03-23.
//

import Foundation

actor Semaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(count: Int = 0) {
        self.count = count
    }
    
    func wait() async {
        count -= 1
        if count >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }
    
    func signal (count: Int = 1) {
        self.count += count
        for _ in 0..<count {
            if waiters.isEmpty { return }
            waiters.removeFirst().resume()
        }
    }
}
