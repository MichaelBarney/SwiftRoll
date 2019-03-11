//
//  GameScene.swift
//  SwiftRoll
//
//  Created by Michael Barney on 25/02/19.
//  Copyright © 2019 michaelbarney. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: Variables, Constants and Structs
    //******************Game Structures************************/
    struct paddle_structure {
        var x:CGFloat;
        var y:CGFloat;
    }
    struct ball_structure {
        var x:CGFloat;
        var y:CGFloat;
    }

    /******************Game Constants*******************/
    let paddleHeight:CGFloat = 30;
    let paddleWidth:CGFloat = 200;
    var ballHeight:CGFloat = 75;
    let baseVelocity:CGFloat = 5;
    var frameWidth:CGFloat = 0;
    var frameHeight:CGFloat = 0;
    
    /******************Game Variables*******************/
    var velocity:CGFloat = 0;
    var score = 0;
    var paddles:[paddle_structure] = [];

    /*******************Sprite Kit Nodes***************/
    var SKPaddles:[SKShapeNode] = [];
    let scoreLabel = SKLabelNode();
    let generationLabel = SKLabelNode();
    private var label : SKLabelNode?

    /**************Neural Network Structures************/
    struct hiddenLayersStruct{
        var HL1:[NNNode];
        var HL2:[NNNode];
    }
    
    /**************Neural Network Constants************/
    let nInputs = 9;
    let HiddenLayerOneSize = 10;
    let HiddenLayerTwoSize = 10;

    /**************Genetic Algorithm Structures************/
    struct genome {
        var doing:CGFloat = 0.5; //the final output of the genome, determining if it goes left, right or doesn't move
        var ball:ball_structure? = nil  //Ball data
        var SKball:SKShapeNode?;    //Ball SKNode

        
        //Neural Network
        var hiddenLayers:hiddenLayersStruct?
        var outputNode:NNNode?;
        
        var color:[CGFloat]; //Ball Color
        var fullGenome:[CGFloat]; //The collection of all of the genome's weight, biases and color
        var isActive:Bool; //If the given genome is still active
        
        var standing_still_negative:CGFloat;
        var fitness:CGFloat;
    }
    /**************Genetic Algorithm Constants************/
    let n_genomes = 250;  //number of genomes per generation
    var breed_top = 10;   //how many genomes will be kept
    var breed_count = 25; //how many genomes each top genome will generate (including itself)
                          //ATTENTION! n_genomes must be equal to breed_top * breed_count

    var crossover_chance = 75; //the chance (0 to 100) of a crossover happening
    let mutate_chance = 75;    //the chance (0 to 100) of a mutation happening
    let mutationRange:CGFloat = 3 //by how much a gene can be added by in a mutation
    
    /**************Genetic Algorithm Variables************/
    var generation = 0; //current generation
    var top_full_genomes:[[CGFloat]] = []; //the best genomes in a generation
    var new_generation_full_genomes:[[CGFloat]] = []; //the new genomes on the next generation
    var genomes:[genome] = []; //the current genomes being played
    var killed = 0; //number of killed genomes

    /**************Manual Control Variables************/
    var playerOutput:CGFloat = 0;
    
    /**************Initialization************/
    // MARK: Initialization
    //Called when the scene is presented, normally only once
    override func didMove(to view: SKView) {
        //Init Dimensions
        frameWidth = self.frame.width;
        frameHeight = self.frame.height;
        
        //Initialize the Game
        re_init();
    }
    
    //Function called to initialize a generation
    func re_init(){
        //Init SKNode properties that don't change
        scoreLabel.position = CGPoint(x: frameWidth/2, y: frameHeight - 60);
        scoreLabel.fontSize = 50;
        self.addChild(scoreLabel);
        
        generationLabel.position = CGPoint(x: frameWidth/2, y: frameHeight/2);
        generationLabel.fontSize = 50;
        generationLabel.text = "Generation: \(generation)";
        self.addChild(generationLabel);
        
        genomes = []; //clean the genomes array
        
        //Initialize the game's variables to its base values
        score = 0;
        velocity = baseVelocity;
        scoreLabel.text = "0";
        killed = 0;
        
        //GENETIC ALGORITHM
        if (generation != 0){ //If it's not the first generation
            new_generation_full_genomes = []; //Start with a clean array of the next genomes
            for (i, _) in top_full_genomes.enumerated(){
                //For Each Top Genome, find "breed_count" pairs
                var paired = 0;
                while paired < breed_count {
                    if paired == 0 { //We let the first pairing be just the entire "good" genome
                        new_generation_full_genomes.append(top_full_genomes[i]);
                    }
                    else { //If it's not the first pairing
                        //select a random full_genome
                        let x = Int.random(in: 0...top_full_genomes.count - 1);
                        let to_pair = top_full_genomes[x];
                        var new_genome = top_full_genomes[i];
                        
                        //iterate between each gene in the full_genome
                        for j in 0...top_full_genomes[i].count - 1{
                            //CROSSOVER
                            //A crossover will switch with the random full_genome a given gene
                            let to_pair_gene = to_pair[j];
                            var dice = Int.random(in: 0...100);
                            if dice < crossover_chance{ //See if a crossover should occur
                                //Crossover Will Happen
                                new_genome[j] = to_pair_gene;
                            }
                            
                            //Mutation
                            //A mutation will alter in some capacity a gene, by adding it with a random number
                            dice = Int.random(in: 0...100);
                            if dice < mutate_chance{ //See if a mutation should occur
                                //Mutation Will Happen
                                new_genome[i] += CGFloat.random(in: -mutationRange...mutationRange);
                            }
                            
                        }
                        
                        //Add the new genome to the next batch
                        new_generation_full_genomes.append(new_genome)
                    }
                    paired += 1;
                    
                    
                }
            }
        }
        //Now we have our new genome array, but they are not playable just yet, we need to decode the genes
        
        //CREATE THE PLAYABLE GENOMES BASED ON ALTERED GENES
        for i in 0...n_genomes - 1 {
            //Sprite
            let SKball = SKShapeNode(circleOfRadius: ballHeight/2)
            SKball.lineWidth = 0;
            SKball.position.y = self.frame.height/2;
            SKball.position.x = 0;
            self.addChild(SKball);
            
            //Data
            let ball = ball_structure(x: frameWidth/2, y: self.frame.height - ballHeight - 1)
            
            //Neurons
            //If it is the first generation, weights and bias will be completely random numbers from -mutationRange to mutationRange
            if generation == 0 {
                //Init Hidden Layer 1
                var HL1:[NNNode] = [];
                for _ in 0...HiddenLayerOneSize - 1{
                    var randomWeights:[CGFloat] = [];
                    for _ in 0...nInputs - 1{
                        randomWeights.append(CGFloat.random(in: -mutationRange...mutationRange));
                    }
                    let randomBias = CGFloat.random(in: -mutationRange...mutationRange);
                    let myNode = NNNode(weights: randomWeights, bias: randomBias);
                    HL1.append(myNode);
                }
                //Init Hidden Layer 2
                var HL2:[NNNode] = [];
                for _ in 0...HiddenLayerTwoSize - 1{
                    var randomWeights:[CGFloat] = [];
                    for _ in 0...HiddenLayerOneSize - 1{
                        randomWeights.append(CGFloat.random(in: -mutationRange...mutationRange));
                    }
                    let randomBias = CGFloat.random(in: 0...1);
                    let myNode = NNNode(weights: randomWeights, bias: randomBias);
                    HL2.append(myNode);
                }
                let hiddenLayers = hiddenLayersStruct(HL1: HL1, HL2: HL2);
                
                //Init Output Layer
                var randomWeights:[CGFloat] = [];
                for _ in 0...HiddenLayerTwoSize - 1{
                    randomWeights.append(CGFloat.random(in: -mutationRange...mutationRange));
                }
                let randomBias = CGFloat.random(in: -mutationRange...mutationRange);
                let outputNode = NNNode(weights: randomWeights, bias: randomBias);
                
                //GENERATE THE FIRST FULL GENOME
                //It's made up of:
                //Color + H1 Weights + H1 Bias + H2 Weights + H2 Bias + Output Weight + Output Bias
                var fullGenome:[CGFloat] = [];
                
                //First we add the ball's color
                var color:[CGFloat] = []
                for _ in 0...2{
                    let color_value = CGFloat.random(in: 0...1);
                    fullGenome.append(color_value);
                    color.append(color_value);
                }
                SKball.fillColor = UIColor(red: color[0], green: color[1], blue: color[2], alpha: 1);
                
                //Then fill up the Hidden Layer 1 Weights and Bias
                for n in HL1{
                    for weight in n.weights{
                        fullGenome.append(weight);
                    }
                    fullGenome.append(n.bias);
                }
                
                //Then fill up the Hidden Layer 2 Weights and Bias
                for n in HL2{
                    for weight in n.weights{
                        fullGenome.append(weight);
                    }
                    fullGenome.append(n.bias);
                }
                
                //Finally fill up the output Node Weights and Bias
                for weight in outputNode.weights{
                    fullGenome.append(weight);
                }
                fullGenome.append(outputNode.bias);
                
                //With this, we can create a playable genome
                genomes.append(genome(doing: 0.5, ball: ball, SKball: SKball, hiddenLayers: hiddenLayers, outputNode: outputNode, color: color, fullGenome: fullGenome, isActive: true, standing_still_negative: 0, fitness: 0));
            }
                
            //If it's not the first generation, we need to decode those genomes
            else{
                //The full genome array is composed in the following manner
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
                for _ in 0...HiddenLayerOneSize - 1{
                    //Decode Weights
                    let weight_index_start = cursor;
                    let number_of_weights = nInputs;
                    let weight_index_end = cursor + (number_of_weights - 1);
                    var weights:[CGFloat] = [];
                    for x in weight_index_start...weight_index_end {
                        weights.append(selected_full_genome[x]);
                    }
                    //Decode Bias
                    let bias_index = weight_index_end + 1;
                    let bias = selected_full_genome[bias_index]
                    cursor = bias_index + 1;
                    
                    let myNode = NNNode(weights: weights, bias: bias);
                    HL1.append(myNode);
                }
                
                //Now the second hidden layer
                var HL2:[NNNode] = [];
                for _ in 0...HiddenLayerTwoSize - 1{
                    //Decode Weights
                    let weight_index_start = cursor;
                    let number_of_weights = HiddenLayerTwoSize;
                    let weight_index_end = cursor + (number_of_weights - 1);
                    var weights:[CGFloat] = [];
                    for x in weight_index_start...weight_index_end {
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
                let weight_index_start = cursor;
                let number_of_weights = HiddenLayerTwoSize;
                let weight_index_end =  cursor + (number_of_weights - 1);
                var weights:[CGFloat] = [];
                for x in weight_index_start...weight_index_end {
                    weights.append(selected_full_genome[x]);
                }
                //Decode Bias
                let bias_index = weight_index_end + 1;
                let bias = selected_full_genome[bias_index]
                cursor = bias_index + 1;
                let outputNode = NNNode(weights: weights, bias: bias);
                
                //Now create the node
                let hiddenLayers = hiddenLayersStruct(HL1: HL1, HL2: HL2);
                
                if top_full_genomes.contains(selected_full_genome){
                    SKball.lineWidth = 3;
                    SKball.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                    SKball.zPosition = 2000
                    print("IN!")
                }
                else{
                    SKball.alpha = 0.3;
                }
                
                genomes.append(genome(doing: 0.5, ball: ball, SKball: SKball, hiddenLayers: hiddenLayers, outputNode: outputNode, color: color, fullGenome: selected_full_genome, isActive: true, standing_still_negative: 0, fitness: 0));
            }
        }
        

        
        top_full_genomes = []; //clean the top genomes array for the next generation to use

        //Initialize the Moving Paddles
        paddles = [];
        SKPaddles = [];
        for i in 0...2{ //3 paddles
            //Paddle Sprite Node
            let num_options = 3
            let position = CGFloat(Int.random(in: 0...(num_options - 1)));
            let distance = (frameWidth - paddleWidth)/CGFloat(num_options - 1)
            let randomX = paddleWidth/2 +  position * distance;
            
            let SKPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight));
            SKPaddle.lineWidth = 0;
            SKPaddle.fillColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1);
            SKPaddle.position.y = -CGFloat(i*500); //each distanced by 500 points
            SKPaddle.position.x = randomX;
            SKPaddles.append(SKPaddle);
            self.addChild(SKPaddle); //add paddle to scene
            
            //Paddle Data
            let p = paddle_structure(x: randomX, y: SKPaddle.position.y);
            paddles.append(p);
        }
    }
    
    
    /**************Game Updates************/
    //Update the game's data based on the neural network
    // MARK: Update Data
    func updateData(){
        //Iterate between each playable genome
        for (i, _) in genomes.enumerated(){
            var g = genomes[i];
            if (g.isActive == true){ //If the genome is still active
                //Update Input Array
                //These values are all between 0 and 1
                let myInputs:[CGFloat] = [
                    g.ball!.y/frameHeight,
                    g.ball!.x/frameWidth,
                    paddles[0].x/frameWidth,
                    paddles[0].y/frameHeight,
                    paddles[1].x/frameWidth,
                    paddles[1].y/frameHeight,
                    paddles[2].x/frameWidth,
                    paddles[2].y/frameHeight,
                    velocity / (1 + abs(velocity))
                ];
                
                //Calculate the first layer of the neural network
                var HL1Results:[CGFloat] = [];
                for node in g.hiddenLayers!.HL1{
                    HL1Results.append(node.calculate(inputs: myInputs));
                }
                
                //Calculate the second layer of the neural network
                var HL2Results:[CGFloat] = [];
                for node in g.hiddenLayers!.HL2{
                    HL2Results.append(node.calculate(inputs: HL1Results));
                }
                
                //Calculate the output layer of the neural network
                let output = g.outputNode!.calculate(inputs: HL2Results);
                g.doing = output;
                
                //Check if ball reached the upper or lower limits of the screen
                if(g.ball!.y + ballHeight/2 > frameHeight ||
                   g.ball!.y - ballHeight/2 < 0){
                    
                    g.SKball?.removeFromParent(); //remove the sprite from the screen
                    g.isActive = false; //make the genome inactive
                    killed += 1; //increase the number of killed genomes
                    
                    g.fitness = CGFloat(score);
                    
                    genomes[i] = g; //save data
                    
                    //Check if all genomes have been killed, to end the generation
                    if killed >= n_genomes{
                        for child in self.children{
                            child.removeFromParent(); //clear entire screen
                        }

                        genomes.sort(by: { (a, b) -> Bool in
                            a.fitness > b.fitness
                        })
                        
                        //Add the top genomes and the medium genome
                        //The worse genome can give us more diversity
                        for (i, _) in genomes.enumerated(){
                            print(genomes[i].fitness);
                            if (i < breed_top - 1){
                                top_full_genomes.append(genomes[i].fullGenome);
                            }
                            else if (i == genomes.count - 1){
                                top_full_genomes.append(genomes[i].fullGenome);
                            }
                        }
                        print("Top Full Genomes Count: \(top_full_genomes.count)")
                        generation += 1; //increase the generation number

                        re_init(); //re-initialize
                    }
                }
                else{
                    //Update Positions
                    g.ball!.y -= velocity; //Ball Gravity
                    if (g.doing <= 0.33 && g.ball!.x - ballHeight/2 > 0){ //Ball go Left
                        g.ball!.x -= velocity;
                    }
                    else if (g.doing >= 0.66 && g.ball!.x + ballHeight/2 < frameWidth){ //Ball go Right
                        g.ball!.x += velocity;
                    }
                    else if (g.doing <= 0.33 || g.doing >= 0.66){ //standing still
                        g.standing_still_negative += 1;
                    }
                    //Iterate each paddle
                    for (i, _) in paddles.enumerated(){
                        //check if collides with ball;
                        if  paddles[i].y + paddleHeight/2 >= (g.ball?.y)! - ballHeight/2 &&
                            paddles[i].y - paddleHeight/2 <= (g.ball?.y)! + ballHeight/2 &&
                            paddles[i].x - paddleWidth/2 <= (g.ball?.x)! + ballHeight/2 &&
                            paddles[i].x + paddleWidth/2  >= (g.ball?.x)!  - ballHeight/2{
                            g.ball?.y = paddles[i].y + paddleHeight/2 + ballHeight/2; //ball collision with paddle
                        }
                    }
                    genomes[i] = g; //save changes
                }
            }
        }
        //Update Paddle Data
        for (i, _) in paddles.enumerated(){
            paddles[i].y += velocity;
            
            //Check if Paddle Ended
            if paddles[i].y - paddleHeight/2 >= self.frame.height{
                let num_options = 3
                let position = CGFloat(Int.random(in: 0...(num_options - 1)));
                let distance = (frameWidth - paddleWidth)/CGFloat(num_options - 1)
                let randomX = paddleWidth/2 +  position * distance;
                paddles[i].x = randomX; //update paddle x to random number
                paddles[i].y = paddles[mod((i - 1), paddles.count)].y - 500; //update paddle y
            }
        }
        score += 1;
    }
    
    //Update the SK Nodes positions based on the data
    // MARK: Draw Data
    func drawData(){
        //Balls
        for (i, _) in genomes.enumerated(){
            genomes[i].SKball!.position.x = (genomes[i].ball?.x)!;
            genomes[i].SKball!.position.y = (genomes[i].ball?.y)!;
        }
        //Paddles
        for (i, _) in paddles.enumerated(){
            SKPaddles[i].position.x = paddles[i].x;
            SKPaddles[i].position.y = paddles[i].y;
        }
        //Update Score
        scoreLabel.text = String(score);
    }
    
    //Called each frame
    override func update(_ currentTime: TimeInterval) {
        updateData();
        drawData();
        //Update Velocity
        velocity += 0.005;
    }
    
    /**************Manual Controls************/
    // MARK: Manual Controls
    //Touch Handling
    func touchDown(atPoint pos : CGPoint) {
        if pos.x > 0 {
            playerOutput = 1;
        }
        else{
            playerOutput = 0;
        }
    }
    func touchUp(atPoint pos : CGPoint) {
        playerOutput = 0.5;
    }
    //Touch Detection
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    /**************Utilitary Functions************/
    // MARK: Utilitary Functions
    func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
}

