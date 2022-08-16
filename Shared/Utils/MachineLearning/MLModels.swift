//
//  MLModels.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/14.
//

import Foundation
import CoreML
import NaturalLanguage

class TagPredictor {
    let models: [NLModel]
    let modelCapacity = 25
    
    static let shared = try? TagPredictor()
    
    init() throws {
        // TODO: Use Cloud Deployment
        let config = MLModelConfiguration()
        let tagPredModelME = try NLModel(mlModel:TagPredictorME(configuration: config).model)
        let tagPredModelTL = try NLModel(mlModel:TagPredictorTL(configuration: config).model)
        
        models = [tagPredModelME, tagPredModelTL]
    }
    
    func suggest(_ text: String, threshold: Double = 0.2) -> [String] {
        var suggestions: [String] = []
        for model in models {
            let labelHypotheses = model.predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: modelCapacity)
            suggestions += labelHypotheses.filter({ key, value in
                return value >= threshold
            }).keys
        }
        return suggestions
    }
    
    func debugPredictTagForText(_ text: String, modelId: Int = 0) -> String {
        let labelHypotheses = self.models[modelId].predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: modelCapacity)
        var string = ""
        for (label, confd) in labelHypotheses {
            if confd < 0.1 {
                continue
            }
            let roundedValue = round(confd * 100) / 100.0
            string += " \(label):\(roundedValue)"
        }
        return string
    }
}
