//
//  THRenderer.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/12.
//

import Foundation

import UIKit
import SwiftUI

class PlaceHolderView: UIView {
    func animate() {
        UIView.animate(withDuration: 1.0) {
            self.alpha = 0.0
            self.transform = .identity.rotated(by: 360.0)
        } completion: { _ in
            self.reset()
        }
    }
    
    func reset() {
        UIView.animate(withDuration: 1.0) {
            self.alpha = 1.0
            self.transform = .identity
        } completion: { _ in
            self.animate()
        }
    }
}

class CustomViewRendererProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        if let data = textAttachment?.contents {
            // Data for this view. Use this to determine what the view should be
            print(String(data: data, encoding: .utf8))
        }
        view = PlaceHolderView()
        view?.backgroundColor = .purple
        (view as? PlaceHolderView)?.animate()
    }
}

