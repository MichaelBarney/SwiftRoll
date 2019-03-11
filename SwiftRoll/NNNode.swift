//
//  NNNode.swift
//  SwiftRoll
//
//  Created by Michael Barney on 11/03/19.
//  Copyright © 2019 michaelbarney. All rights reserved.
//

import Foundation
import SpriteKit
/**************Neural Network Node Class************/
// MARK: Neural Network Node
class NNNode {
    var weights: [CGFloat];
    var bias:CGFloat;
    var result:CGFloat = 0;
    
    //Initializations
    init(weights:[CGFloat], bias:CGFloat) {
        self.weights = weights;
        self.bias = bias;
    }
    
    //Node Foward Propagation
    func calculate(inputs:[CGFloat]) -> CGFloat{
        var sum:CGFloat = 0
        for (i, _) in inputs.enumerated(){
            sum += inputs[i] * weights[i];
        }
        self.result = sigmoid(x: (sum + bias))
        return self.result;
    }
    
    //Sigmoid Function
    private func sigmoid(x: CGFloat) -> CGFloat {
        return 1 / (1 + exp(-x))
    }
}
