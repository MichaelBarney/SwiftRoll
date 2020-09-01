Accepted **WWDC19** Scholarship Submission

# Swift Roll
A simple artificial intelligence made in Swift to play a version of the old Nokia game "Rapid Roll", using Neural Networks and a simple Genetic Algorithm.

### Youtube Video (Click to Watch):

[![SwiftRoll Youtube Video (Click to Watch)](https://img.youtube.com/vi/OW2NTA4YytE/0.jpg)](https://www.youtube.com/watch?v=OW2NTA4YytE)

![AI on Generation 37](https://i.imgur.com/YbAh4yy.png)

## App Installation
**This project  was made to run on iOS devices (12.1) and is only able to be installed through MacOS computers.** 
 1. Download [Xcode](https://developer.apple.com/xcode/).
 2. Clone/download this folder to your computer.
 3. Open [SwiftRoll.xcodeproj](https://github.com/MichaelBarney/SwiftRoll/tree/master/SwiftRoll.xcodeproj "SwiftRoll.xcodeproj").
 4. Build the project.
 
## Running the Playground
Download and unzip [Playground/SwiftRoll.playground.zip](Playground) then open it through Xcode.

## How it works - Neural Network
We have a total of 9 inputs nodes:

 1. Ball - X Coordinate
 2. Ball - Y Coordinate
 3. Paddle 1 - X Coordinate
 4. Paddle 2 - X Coordinate
 5. Paddle 3 - X Coordinate
 6. Paddle 1 - Y Coordinate
 7. Paddle 2 - Y Coordinate
 8. Paddle 3 - Y Coordinate
 9. Current Velocity

And one output with 3 possible states:

 1. Left   (<0.33) 
 2. Right (>0.66)
 3. Nothing
 
Each Neural Network calculates it's output through the use of 2 Hidden Layers with size 10 `(HiddenLayerOneSize and HiddenLayerTwoSize)`
 
## How it works - Genetic Algorithm
Each Generation generation consists of 250 `(n_genomes)` neural networks (Genomes).

Each genome is consisted of genes, which are the genomes Neural Network Weights and Biasses and the Player's color, in the following order:

    Color + H1 Weights + H1 Bias + H2 Weights + H2 Bias + Output Weight + Output Bias

When the game is training, we keep track of each genome's fitness `(score)` to select the 9 `(breed_top - 1)` best and 1 worse players, saving them in the `top_full_genomes` array.

When the entire generation has completed, we take the top full genomes and for each one apply 2 evolution processes:

 1. **Crossover:** Given a chance of 75% of this happening `(crossover_chance)`, we select another random top genome and cross-over their genes.
 2. **Mutation:** Given a chance of 75% of this happening `(mutation_chance)`, we apply a modification to the genome by adding it to a random value between -3 and 3 `(mutationRange)`

These processes are repeated 25 times `(breed_count)`, resulting back to the original size of 250 genomes.

## Little Nods

 - All genomes in a given generation are processed and shown at the same time, giving the observer a more profound undersanding of progress being made.
 - The player's ball color is a part of the genome, therefore they start completelly random but during the training patterns can be seen through crossovers and mutations.
 - The top genomes of a generation are repeated for the next, they can be seen with a higher opacity and a white border.

## Implementation
The implementation was done using Swift with a target for 12.1 iOS devices.

While there are a couple of files in the project, the main ones are:

 - [GameViewController.swift](https://github.com/MichaelBarney/SwiftRoll/blob/master/SwiftRoll/GameViewController.swift): Creates the game scene and calls it, basically.
 - [GameScene.swift](https://github.com/MichaelBarney/SwiftRoll/blob/master/SwiftRoll/GameScene.swift): The heart of the project, it contains the entire playable game, the neural network implementation and the genetic algorithm.
 - [NNNode.swift](https://github.com/MichaelBarney/SwiftRoll/blob/master/SwiftRoll/NNNode.swift "NNNode.swift"): A seperata class for a hadcoded implementation of a Neural Network Node

### Navigating GameScene.swift
It probably wasn't best practice to fit so many components (game, neural network and genetic algorithm) inside only one file. But I did so in order to be a bit less confusing navigating everything spread out into 5 different files. Yet, it does need some clarifications about the positioning of code.
 - **MARK: Variables, Constants and Structs**
 At the start of the code is all structs, variables and constants used, separated by **Game**, **Neural Network** and **Genetic Algorithm**. Fiddling with the constants can give you new training configurations.
 - **MARK: Initiallization**
Here is all the code for initializing all generations of the game, it includes the creation of the SpriteKitNodes and the Genetic Algorithm's Evolution and Gene Decoding to construct Genome Neural Networks.
 - **MARK: Update Data**
 This is where the game itself ocurres and the players move according to it's Neural Network and collision detections occur.
  - **MARK: Draw Data**
This takes the updated data from the game and draws it to the screen.
  - **MARK: Manual Controls**
This is used in case the user want's to play the game for himself, using Touchscreen controls.
  - **MARK: Utilitary Functions**
This is houses any functions that may be used throughout the code only as a primordial tool.

## Communication

-   If you  **found a bug**, open an issue.
-   If you  **have a feature request**, open an issue.
-   If you  **want to contribute**, submit a pull request.


## Credits

 - [Michael Barney](https://github.com/michaelbarney)

## Inspiration
[IAMDinosaur](https://github.com/ivanseidel/IAMDinosaur/blob/master/README.md)

