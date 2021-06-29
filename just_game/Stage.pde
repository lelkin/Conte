/*
Each game is divided into different Stages each with different difficulty.
A stage consisits of multiple blocks. Each block in a stage is identical, and contains all Conte points in random order
*/
class Stage{
  Command[] commandArr; // needed by blocks
  PApplet parent; // sketch. needed to shuffle properly
  // types of stages
  static final int slow = 0;
  static final int medium = 1;
  static final int fast = 2;
  static final int retention = 3;
  
  // speeds - index is stage the speed is for. Speed is in seconds for enemy to drop
  final int[] speeds = {20, 10, 5, 0}; // speeds[0] is speed for slow, speed[1] medium etc
  int speed; // speed for this stage
  
  int stageType; // what type of stage is this
  int stageNum; // number is stage sequence - needed for logger - 0 indexed
  
  int totalNumBlocks; // number of blocks per stage
  int blockNum; // number of the current block
  Block currBlock;
  
  /*
  Input: commandArr is an array containing all the commands
         stageType is the type of stage it is
         stageNum is the number stage this is - 0 indexed
         parent is sketch -- needed to shuffle properly
  */
  Stage(Command[] commandArr, int stageType, int stageNum, int totalNumBlocks, PApplet parent){
    this.commandArr = commandArr;
    this.stageType = stageType;
    this.stageNum = stageNum;
    this.totalNumBlocks = totalNumBlocks;
    this.parent = parent;
    blockNum = -1;
    speed = speeds[stageType];
    logStageStart();
    initBlock();
    totalNumBlocks = 4;
  }
  
  /*
  Logs the start of the stage
  */
  void logStageStart(){
    String JSONStr = logger.buildJSON("\"type\"", "\"start\"", "\"num\"", str(stageNum+1),
                                       "\"stageType\"", "\"" + stageNameToString(stageType) + "\"",
                                      "\"dropTime\"", str(speed), "\"numBlocks\"", str(totalNumBlocks));
    logger.doLog(new JSONEvent("E", "stage", true, JSONStr));
  }
  
  /*
  Updates stage.
  Output: true if stage is fine, false if stage is done
  */
  boolean update(){
    boolean blockResult = currBlock.update();
    
    if(!blockResult){ // block is done, start new block
      boolean initResult = initBlock();
      if(!initResult){
        // no more blocks to init, stage is done
        logStageEnd();
        return false;
      }
    }
    return true;
  }
  
  /*
  Logs end of stage
  */
  void logStageEnd(){
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"", "\"num\"", str(stageNum+1));
    logger.doLog(new JSONEvent("E", "stage", true, JSONStr));
  }
  
  void draw(){
    currBlock.draw();
  }
  
  /*--------- SETUP ---------*/
  
  /*
  Init new block in this stage
  Output: true if new block was init, false if no more blocks to init in this stage
  */
  boolean initBlock(){
    blockNum++;
    if(blockNum < totalNumBlocks){
      currBlock = innerInitBlock(); 
      return true;
    } else {
      return false;
    }
  }
  
  /*
  Actually inits block. 
  Split up so can be overwritten in by Retention Stage
  */
  Block innerInitBlock(){
    Block result = new Block(commandArr, speed, blockNum, stageNum, parent);
    return result;
  }
  
  /*---------- SKIP ----------*/
  
  /*
  Moves to the next block if available and returns true, otherwise returns false
  Output: true if there is another block left in the stage, false otherwise 
  */
  boolean skipBlock(){
    // skip all remaining enemies in block
    boolean skipEnemyResult = currBlock.skipEnemy();
    while(skipEnemyResult){
      skipEnemyResult = currBlock.skipEnemy();
    }
    // when done, init new block
    return initBlock();
  }
  
  /*
  Moves to the next enemy, moving to the next block if needed
  Output: true if next enemy or block available, false if hit end of stage
  */
  boolean skipEnemy(){
    boolean skipEnemyResult = currBlock.skipEnemy();
    // hit end of current block
    if(!skipEnemyResult){
      boolean skipBlockResult = initBlock();
      // hit end of this stage
      if(!skipBlockResult){
        return false;
      }
    }
    // stayed in stage
    return true;
  }
  
  /*---------- GET INFO ----------*/
  
  /*
  Returns the current enemy
  Output: current enemy, null if there's isn't one
  */
  Enemy getCurrEnemy(){
    if(currBlock != null){
      return currBlock.getCurrEnemy();
    } else {
      return null;
    }
  }
}

/*
Given an int representing a stageName, returns the string version
Input: int representing stage
Output: string name or "" if invalid input
Has to be outside of class since will be called before stage is init
*/
String stageNameToString(int stage){
  switch(stage){
    case Stage.slow:
      return "slow";
    case Stage.medium:
      return "medium";
    case Stage.fast:
      return "fast";
    case Stage.retention:
      return "retention";
    default:
      return "";
  }
}

/*
Stage for retention test
Differences: Hides score, only 1 block, inits RetentionBlock
*/
class RetentionStage extends Stage{
  
  RetentionStage(Command[] commandArr, int stageType, int stageNum, int totalNumBlocks, PApplet parent){
    super(commandArr, stageType, stageNum, totalNumBlocks, parent);
    game.disableScore();
    app.disableFeedback();
    menu.retentionModeOn();
  }
  
  /*
  Inits retention block.
  */
  Block innerInitBlock(){
    Block result = new RetentionBlock(commandArr, speed, blockNum, stageNum, parent);
    return result;
  }
}