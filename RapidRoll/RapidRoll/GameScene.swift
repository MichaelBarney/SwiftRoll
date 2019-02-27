//
//  GameScene.swift
//  RapidRoll
//
//  Created by Michael Barney on 25/02/19.
//  Copyright © 2019 michaelbarney. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //Structures
    struct paddle {
        var midX:CGFloat;
        var topY:CGFloat;
    }
    struct ball_structure {
        var midX:CGFloat;
        var bottomY:CGFloat;
    }

    //Outputs
    var personDoing:CGFloat = 0;
    
    //Inputs
    var velocity:CGFloat = 0;
    
    //Game Constants
    let paddleHeight:CGFloat = 30;
    let paddleWidth:CGFloat = 200;
    var ballHeight:CGFloat = 75;
    let baseVelocity:CGFloat = 5;
    var frameWidth:CGFloat = 0;
    var frameHeight:CGFloat = 0;

    //General Data
    var paddles:[paddle] = [];
    var SKPaddles:[SKShapeNode] = [];
    let scoreLabel = SKLabelNode();
    let generationLabel = SKLabelNode();
    
    //General SKNodes
    private var label : SKLabelNode?

    //Neural Network Variables
    let nInputs = 9;
    let HiddenLayerOneSize = 10;
    let HiddenLayerTwoSize = 10;
    struct hiddenLayersStruct{
        var HL1:[NNNode];
        var HL2:[NNNode];
    }
    
    //Genetic Algorithm Constants
    //SEED
    let n_genomes = 500;
    //WEED
    var score = 0;
    //BREED
    var breed_top = 10;
    var breed_count = 50;
    var crossover_chance = 10;
    //MUTATE
    var mutate_chance = 10; //by a number between 0 and 1;
    
    //Genetic Algorithm Variables
    var generation = 0;
    var top_full_genomes:[[CGFloat]] = [];
    var new_generation_full_genomes:[[CGFloat]] = [];
    
    var running = false;
    
    struct genome {
        //Score
        var score = 0;
        
        var doing:CGFloat = 0.5;

        //Ball data
        var ball:ball_structure? = nil
        //Ball SKNode
        var SKball:SKShapeNode?;
        //Neural Network
        var hiddenLayers:hiddenLayersStruct?
        var outputNode:NNNode?;
        //Ball Color
        var color:[CGFloat];
        //Full Genome
        var fullGenome:[CGFloat];
        var isActive:Bool;
    }
    var genomes:[genome] = [];

    
    //INIT
    override func didMove(to view: SKView) {
        //Init Scene
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        frameWidth = self.frame.width;
        frameHeight = self.frame.height;
        
        let data_queue = DispatchQueue(label: "data_queue");
        data_queue.async {
            while self.running == true {
                self.updateData();
            }
        }
        
        re_init();
    }
    
    func re_init(){
        genomes = [];
        
        //General Inits
        score = 0;
        velocity = baseVelocity;
        scoreLabel.position = CGPoint(x: 0, y: frameHeight/2 - 60);
        scoreLabel.text = "0";
        scoreLabel.fontSize = 50;
        self.addChild(scoreLabel);
        
        //Genenetic Algorithm Initializers
        generationLabel.position = CGPoint(x: 0, y: 0);
        generationLabel.text = "Generation: \(generation)";
        generationLabel.fontSize = 50;
        self.addChild(generationLabel);
        
        //CROSSOVER;
        if (generation != 0){
            new_generation_full_genomes = [];
            for (i, _) in top_full_genomes.enumerated(){
                //For Each Top Genome, Find "breed_count" Pairs
                var paired = 0;
                while paired < breed_count {
                    if paired != 0{
                        //select a random full_genome
                        let x = Int.random(in: 0...top_full_genomes.count - 1);
                        let to_pair = top_full_genomes[x];
                        //and for each gene in the full_genome
                        var new_genome = top_full_genomes[i];
                        for j in 0...top_full_genomes[i].count - 1{
                            let to_pair_gene = to_pair[j];
                            //now, we have a setted chance that a crossover will occur
                            var dice = Int.random(in: 0...100);
                            if dice < crossover_chance{
                                //Crossover Will Happen
                                new_genome[j] = to_pair_gene;
                            }
                            
                            //Mutation
                            dice = Int.random(in: 0...100);
                            if dice < mutate_chance{
                                //Mutation Will Happen
                                let mutationValue = CGFloat.random(in: 0.1 ... 1.5)
                                new_genome[i] = new_genome[i] * mutationValue;
                            }
                            
                        }
                        //Add the new genome to the next batch
                        new_generation_full_genomes.append(new_genome)
                    }
                    else{
                        new_generation_full_genomes.append(top_full_genomes[i]);
                    }
                    paired += 1;
                    
                    
                }
                print(new_generation_full_genomes.count);
            }
            
            //Now we have our new genomes, but it doesnt have substance to run yet, we need to decode the genes
            running = true;
        }

        top_full_genomes = [];
        
        
        //CREATE THE BALLS BASED ON GENES
        for i in 0...n_genomes - 1 {
            //Init Ball
            //Sprite Ball
            let SKball = SKShapeNode(circleOfRadius: ballHeight/2)
            SKball.lineWidth = 0;
            SKball.position.y = self.frame.height/2;
            SKball.position.x = 0;
            self.addChild(SKball);
            //Data Ball
            let ball = ball_structure(midX: 0, bottomY: self.frame.height/2 - ballHeight - 1)
            
            
            //Neural Network
            //If it is the first generation, things will be completely random
            if generation == 0 {
                //Init Hidden Layer 1
                var HL1:[NNNode] = [];
                for _ in 0...HiddenLayerOneSize - 1{
                    var randomWeights:[CGFloat] = [];
                    for _ in 0...nInputs - 1{
                        randomWeights.append(CGFloat.random(in: -1...1));
                    }
                    let randomBias = CGFloat.random(in: -1...1);
                    let myNode = NNNode(weights: randomWeights, bias: randomBias);
                    HL1.append(myNode);
                }
                //Init Hidden Layer 2
                var HL2:[NNNode] = [];
                for _ in 0...HiddenLayerTwoSize - 1{
                    var randomWeights:[CGFloat] = [];
                    for _ in 0...HiddenLayerOneSize - 1{
                        randomWeights.append(CGFloat.random(in: -1...1));
                    }
                    let randomBias = CGFloat.random(in: -1...1);
                    let myNode = NNNode(weights: randomWeights, bias: randomBias);
                    HL2.append(myNode);
                }
                let hiddenLayers = hiddenLayersStruct(HL1: HL1, HL2: HL2);
                
                //Init Output Layer
                var randomWeights:[CGFloat] = [];
                for _ in 0...HiddenLayerTwoSize - 1{
                    randomWeights.append(CGFloat.random(in: -1...1));
                }
                let randomBias = CGFloat.random(in: -1...1);
                let outputNode = NNNode(weights: randomWeights, bias: randomBias);
                
                //GENERATE THE FIRST FULL GENOME
                var fullGenome:[CGFloat] = [];
                
                var color:[CGFloat] = []
                for _ in 0...2{
                    fullGenome.append(CGFloat.random(in: 0...1));
                    color.append(CGFloat.random(in: 0...1));
                }
                
                SKball.fillColor = UIColor(red: color[0], green: color[1], blue: color[2], alpha: 1);
                
                //Color + H1 Weights + H1 Bias + H2 Weights + H2 Bias + Output Weight + Output Bias
                for n in HL1{
                    for weight in n.weights{
                        fullGenome.append(weight);
                    }
                    fullGenome.append(n.bias);
                }
                for n in HL2{
                    for weight in n.weights{
                        fullGenome.append(weight);
                    }
                    fullGenome.append(n.bias);
                }
                for weight in outputNode.weights{
                    fullGenome.append(weight);
                }
                fullGenome.append(outputNode.bias);
                
                print("CREATED THE FULL GENOME: \(fullGenome.count)");
                
                genomes.append(genome(score: 0, doing: 0.5, ball: ball, SKball: SKball, hiddenLayers: hiddenLayers, outputNode: outputNode, color: color, fullGenome: fullGenome, isActive: true));
            }
            //else, we need to decode those genomes
            else{
                 //Color + H1 Weights + H1 Bias + H2 Weights + H2 Bias + Output Weight + Output Bias
                var selected_full_genome = new_generation_full_genomes[i];
                var cursor = 0; //This will help navigate the genome, starting in index 0
                
                //First, we need to get the color, the top 3 genomes
                var color:[CGFloat] = []
                for i in 0...2{
                    color.append(selected_full_genome[i]);
                }
                SKball.fillColor = UIColor(red: color[0], green: color[1], blue: color[2], alpha: 1);
                cursor = 3;
                
                //Next, its the first hidden leyer, with weights and biases
                var HL1:[NNNode] = [];
                var before_cursor = cursor;
                for _ in 0...HiddenLayerOneSize - 1{
                    //Decode Weights
                    let weight_index_start = cursor;
                    let number_of_weights = nInputs;
                    let weight_index_end = cursor + (number_of_weights - 1);
                    var weights:[CGFloat] = [];
                    print("MAKING H1");
                    print("Count: \(selected_full_genome.count)");
                    print("Cursor: \(cursor)");
                    print("End: \(weight_index_end)");
                    for x in weight_index_start...weight_index_end {
                        print(x);
                        weights.append(selected_full_genome[x]);
                    }
                    //Decode Bias
                    let bias_index = weight_index_end + 1;
                    let bias = selected_full_genome[bias_index]
                    cursor = bias_index + 1;
                    
                    let myNode = NNNode(weights: weights, bias: bias);
                    HL1.append(myNode);
                    print("Final cursor: \(cursor)");
                }
                
                //Now the second hidden layer
                var HL2:[NNNode] = [];
                before_cursor = cursor;
                for h in 0...HiddenLayerTwoSize - 1{
                    //Decode Weights
                    let weight_index_start = cursor;
                    let number_of_weights = HiddenLayerTwoSize;
                    let weight_index_end = cursor + (number_of_weights - 1);
                    var weights:[CGFloat] = [];
                    print("MAKING H2");
                    print("Count: \(selected_full_genome.count)");
                    print("Cursor: \(cursor)");
                    print("End: \(weight_index_end)");
                    for x in weight_index_start...weight_index_end {
                        print(x);
                        weights.append(selected_full_genome[x]);
                    }
                    //Decode Bias
                    let bias_index = weight_index_end + 1;
                    let bias = selected_full_genome[bias_index]
                    cursor = bias_index + 1;
                    
                    let myNode = NNNode(weights: weights, bias: bias);
                    HL2.append(myNode);
                }
                
                //Finally, the output
                //Decode Weights
                before_cursor = cursor;
                let weight_index_start = cursor;
                let number_of_weights = HiddenLayerTwoSize;
                let weight_index_end =  cursor + (number_of_weights - 1);
                var weights:[CGFloat] = [];
                print("MAKING OUTPUT");
                print("Count: \(selected_full_genome.count)");
                print("Cursor: \(cursor)");
                print("End: \(weight_index_end)");
                for x in weight_index_start...weight_index_end {
                    print(x);
                    weights.append(selected_full_genome[x]);
                }
                //Decode Bias
                let bias_index = weight_index_end + 1;
                let bias = selected_full_genome[bias_index]
                cursor = bias_index + 1;
                let outputNode = NNNode(weights: weights, bias: bias);
                
                //Now create the node
                let hiddenLayers = hiddenLayersStruct(HL1: HL1, HL2: HL2);
                genomes.append(genome(score: 0, doing: 0.5, ball: ball, SKball: SKball, hiddenLayers: hiddenLayers, outputNode: outputNode, color: color, fullGenome: selected_full_genome, isActive: true));
            }
        }
        
        //Init Paddles
        paddles = [];
        SKPaddles = [];
        for i in 0...2{
            let randomX = CGFloat(Int.random(in: -5 ... 5)) * (self.frame.width - 200)/10;
            
            //SpritePaddles
            let SKPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight));
            SKPaddle.lineWidth = 0;
            SKPaddle.fillColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1);
            
            SKPaddle.position.y = -CGFloat(i*500);
            SKPaddle.position.x = randomX;
            SKPaddles.append(SKPaddle);
            self.addChild(SKPaddle);
            print("added new paddle")
            
            //Data Paddles
            let p = paddle(midX: randomX, topY: SKPaddle.position.y + paddleHeight/2);
            paddles.append(p);
        }
    }
    
    //Manual Controls
    func touchDown(atPoint pos : CGPoint) {
        if pos.x > 0 {
            personDoing = 1;
        }
        else{
            personDoing = -1;
        }
    }
    func touchUp(atPoint pos : CGPoint) {
        personDoing = 0;
    }
    
    //Frame Update
    func updateData(){
        for (i, _) in genomes.enumerated(){
            var g = genomes[i];
            if (g.isActive == true){
                /***************Neural Network Begin*************/
                let myInputs:[CGFloat] = [
                    g.ball!.bottomY/(frameHeight/2),
                    g.ball!.midX/(frameWidth/2),
                    paddles[0].midX/(frameWidth/2),
                    paddles[0].topY/(frameHeight/2),
                    paddles[1].midX/(frameWidth/2),
                    paddles[1].topY/(frameHeight/2),
                    paddles[2].midX/(frameWidth/2),
                    paddles[2].topY/(frameHeight/2),
                    velocity / (1 + abs(velocity))
                ];
                
                //First Layer
                var HL1Results:[CGFloat] = [];
                for node in g.hiddenLayers!.HL1{
                    HL1Results.append(node.calculate(inputs: myInputs));
                }
                
                //Second Layer
                var HL2Results:[CGFloat] = [];
                for node in g.hiddenLayers!.HL2{
                    HL2Results.append(node.calculate(inputs: HL1Results));
                }
                
                //Output Layer
                let output = g.outputNode!.calculate(inputs: HL2Results);
                g.doing = output;
                /**************Neural Network END************/
                
                /*****COLLISION DETECTION****/
                //Check If Dead
                if(g.ball!.bottomY + ballHeight > frameHeight/2 || g.ball!.bottomY < -frameHeight/2){
                    g.SKball?.removeFromParent();
                    g.isActive = false;
                    g.score = score;
                    killed += 1;
                    genomes[i] = g;
                    
                    print(killed);
                    //Check if it was a good genome
                    if killed > n_genomes - breed_top{
                        print("GOOD SOLDIER!");
                        top_full_genomes.append(g.fullGenome);
                        print(top_full_genomes);
                    }
                    
                    //All Killed, Reset
                    if killed >= n_genomes{
                        velocity = baseVelocity;
                        killed = 0;
                        for child in self.children{
                            child.removeFromParent();
                        }
                        generation += 1;
                        re_init();
                    }
                }
                else{
                    g.ball!.bottomY -= velocity;
                    if (g.doing <= -0.33 && g.ball!.midX - ballHeight/2 > -frameWidth/2){
                        g.ball!.midX -= velocity;
                    }
                    else if (g.doing >= 0.33 && g.ball!.midX + ballHeight/2 < frameWidth/2){
                        g.ball!.midX += velocity;
                    }
                    for (i, _) in paddles.enumerated(){
                        //Check if Paddle Ended
                        if paddles[i].topY - paddleHeight >= self.frame.height/2{
                            print("ended");
                            print(i);
                            print(mod((i - 1), SKPaddles.count));
                            let randomX = CGFloat(Int.random(in: -5 ... 5)) * (self.frame.width - paddleWidth)/10;
                            paddles[i].midX = randomX;
                            paddles[i].topY = paddles[mod((i - 1), paddles.count)].topY - 500;
                            
                        }
                        
                        //check if collides with ball;
                        if  paddles[i].topY >= (g.ball?.bottomY)! &&
                            paddles[i].topY - paddleHeight <= (g.ball?.bottomY)! + ballHeight &&
                            paddles[i].midX - paddleWidth/2 <= (g.ball?.midX)! + ballHeight/2 &&
                            paddles[i].midX + paddleWidth/2  >= (g.ball?.midX)!  - ballHeight/2{
                            g.ball?.bottomY = paddles[i].topY;
                        }
                    }
                    //Update Drawing
                    //Ball
                    genomes[i] = g;
                }
            }
        }
    }
    
    func drawData(){
        //Balls
        for (i, _) in genomes.enumerated(){
            genomes[i].SKball!.position.x = (genomes[i].ball?.midX)!;
            genomes[i].SKball!.position.y = (genomes[i].ball?.bottomY)! + ballHeight/2;
        }
        //Paddles
        for (i, _) in paddles.enumerated(){
            paddles[i].topY += velocity;
            SKPaddles[i].position.x = paddles[i].midX;
            SKPaddles[i].position.y = paddles[i].topY - paddleHeight/2;
        }
        //Update Score
        score += 1;
        scoreLabel.text = String(score);
    }
    override func update(_ currentTime: TimeInterval) {
        // Calculate Positions
        updateData();
        drawData();
       
        //Update Velocity
        velocity += 0.005;
    }
    
    var killed = 0;

    
    //: TOUCH DETECTION
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    //: Utilitary Functions
    func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
}


class NNNode {
    var weights: [CGFloat];
    var bias:CGFloat;
    var result:CGFloat = 0;
    init(weights:[CGFloat], bias:CGFloat) {
        self.weights = weights;
        self.bias = bias;
    }
    
    func calculate(inputs:[CGFloat]) -> CGFloat{
        var sum:CGFloat = 0
        for (i, _) in inputs.enumerated(){
            sum += inputs[i] * weights[i];
        }
        self.result = sigmoid(x: (sum + bias))
        return self.result;
    }
    
    private func sigmoid(x: CGFloat) -> CGFloat {
        return (2.0 / (1.0 + exp(-x))) - 1
    }
}
