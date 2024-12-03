//
//  LoadingProgressPublisherKey.swift
//  Utils
//
//  Created by Singularity on 2024-12-03.
//

import Combine

/// A generic task-local publisher that allows subroutines to report loading progress to UI.
public enum LoadingProgressPublisherKey {
    @TaskLocal public static var progressPublisher = PassthroughSubject<Float, Never>()
}
