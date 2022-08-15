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
    
    static let shared = try? TagPredictor()
    
    enum TagPredictionModelOption {
        case maxEntropy
        case transferLearning
        case mixed
    }
    
    init() throws {
        // TODO: Use Cloud Deployment
        let config = MLModelConfiguration()
        let tagPredModelME = try NLModel(mlModel:TagPredictorME(configuration: config).model)
        let tagPredModelTL = try NLModel(mlModel:TagPredictorTL(configuration: config).model)
        
        models = [tagPredModelME, tagPredModelTL]
    }
    
    func debugPredictTagForText(_ text: String, modelId: Int = 0) -> String {
        let labelHypotheses = self.models[modelId].predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: 25)
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
