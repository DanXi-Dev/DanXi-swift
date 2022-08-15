//
//  MLModels.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/14.
//

import Foundation
import CoreML
import NaturalLanguage

// TODO: Use Cloud Deployment
let config = MLModelConfiguration()
let tagPredModel = try? NLModel(mlModel:TagPredictor(configuration: config).model)

/// A debug function for ML Text Classification in Tree Hole
func predictTagForText(_ text: String) -> String {
    guard let tagPredModel = tagPredModel else {
        return "NLModel Initialization Failure"
    }
    
    let labelHypotheses = tagPredModel.predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: 25)
    var string = ""
    for (label, confd) in labelHypotheses {
        if confd < 0.2 {
            continue
        }
        let roundedValue = round(confd * 100) / 100.0
        string += " \(label):\(roundedValue)"
    }
    return string
}
