/*
Each block shows each Enemy exactly once in a random order and they fall at a specified speed
*/

class Block{
  // enemies will be an array of itns 0 - numEnemies - 1
  // the command associated with the current enemy is commandArr[shuffledIndices[currShuffledIndex]]
  int numEnemies;
  Command[] commandArr; // all commands as an array. Randomize from here
  PApplet parent; // sketch. needed to shuffle properly
  int[] shuffledIndices; // ints are Enemy types
  int currShuffledIndex; // current index in shuffledIndices
  Enemy currEnemy;
  int speed; // time each enemy takes to drop from top to bottom of screen
  int blockNum;
  int stageNum;
  
  // delay stuff for delay between trials if enemy falls off screen
  boolean inTrialDelay = false;
  int delayStartTime;
  final int delayTime = 1000; // how long to delay between trials. This is consistent with feedback time when selection made
  
  /*
  Constructor
  Input: commandArr is an array of commands. Used so randomization always starts from same order
         speed is the time it takes from an ee
         blockNum is the number block this is in the stage - 0 indexed
  */
  Block(Command[] commandArr, int speed, int blockNum, int stageNum, PApplet parent){
    this.parent = parent;
    this.commandArr = commandArr;
    this.speed = speed;
    this.blockNum = blockNum;
    this.stageNum = stageNum;
    shuffledIndices = randomizeEnemies();
    currShuffledIndex = -1;
    logBlockStart();
    initEnemy();
  }
  
  /*
  Log start of block
  */
  void logBlockStart(){
    // get array of all command names in order for this block as JSON array
    String[] taskOrderArr = new String[commandArr.length];
    for(int i = 0; i < taskOrderArr.length; i++){
      int cmdIdx = shuffledIndices[i];
      Command cmd = commandArr[cmdIdx];
      taskOrderArr[i] = "\"" + cmd.name + "\"";
    }
    String JSONTaskOrderArr = logger.buildJSONArr(taskOrderArr);
    String JSONStr = logger.buildJSON("\"type\"", "\"start\"", 
                                      "\"stageNum\"", str(stageNum + 1),
                                      "\"num\"", str(blockNum+1), 
                                      "\"dropTime\"", str(speed),
                                      "\"taskOrder\"", JSONTaskOrderArr);
    logger.doLog(new JSONEvent("E", "block", true, JSONStr));
  }
  
  /*
  Updates the block by advancing the current enemy, creating a new one, or ending the block if it is done.
  Output: returns true if all is good, false if all pieces are finished
  */
  boolean update(){
    // enemy killed
    if(currEnemy.isKilled()){
      boolean newEnemyInit = initEnemy(); // make new enemy and return whether there was new one to make or not
      if(!newEnemyInit){
        logBlockEnd();
      }
      return newEnemyInit;
    } 
    // enemy already off screen, just waiting for clock to run out so can start new enemy
    else if(inTrialDelay){
      int currTime = millis();
      if(currTime - delayStartTime > delayTime){
        inTrialDelay = false;
        boolean newEnemyInit = initEnemy();
        if(!newEnemyInit){
          logBlockEnd();
        }
        return newEnemyInit;
      }
    }
    // enemy still moving
    else {
      currEnemy.updatePosition();
      if(currEnemy.offScreen()){
        inTrialDelay = true;
        app.disableInput();
        //menu.disable();
        delayStartTime = millis();
        offScreenDeduction(currEnemy);
      }
    }
    return true; // when false is returned, new block is started. true does nothing
  }
  
  /*
  Do deduction for enemy falling offscreen.
  Input: Enemy is the enemy. Really only needed to get score deduction
  */
  void offScreenDeduction(Enemy enemy){
    int wrongChoiceDeduction = enemy.wrongChoiceDeduction;
    game.updateScore(-wrongChoiceDeduction);
  }
  
  /*
  Logs end of block
  */
  void logBlockEnd(){
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"", "\"num\"", str(blockNum+1));
    logger.doLog(new JSONEvent("E", "block", true, JSONStr));
  }
  
  void draw(){
    currEnemy.draw();
  }
  
  /*---------- SKIP ----------*/
  
  /*
  Skips to the next enemy in this block if one is available
  Output: True if there was an enemy left to move to, false otherwise
  */
  boolean skipEnemy(){
    return initEnemy();
  }
  
  /*--------- SETUP ----------*/
  
  /*
  Creates an array from 0 to game.commandArr.length - 1 in random order
  Output: Array containing each int from 0 to game.commandArr.length - 1
          exactly once in random order
  */
   int[] randomizeEnemies(){
     IntList resultList = new IntList();
     numEnemies = commandArr.length;

     // Each Enemy type is an int from 0 to numEnemies - 1
     for(int i = 0; i < numEnemies; i++){
       resultList.append(i);
     }
     
     // shuffle list
     resultList.shuffle(parent);
     
     // create result array in same order
     int[] result = resultList.array();
     return result;
   }
   
   /*
   Inits the next enemy
   Output: true if enemy init, fall if out of enemies for this block
   */
   boolean initEnemy(){
     currShuffledIndex++;
     if(currShuffledIndex < numEnemies){
       int currCmdIndex = shuffledIndices[currShuffledIndex];
       Command currEnemyType = commandArr[currCmdIndex];
       currEnemy = innerInitEnemy(currEnemyType);
       return true;
     } else {
       return false;
     }
   }
   
   /*
   Actually inits enemy. Separate so can be overwritten by RetentionBlock
   */
   Enemy innerInitEnemy(Command currEnemyType){
     Enemy result = new Enemy(currEnemyType, speed, currShuffledIndex, stageNum, blockNum);
     return result;
   }
   
   /*---------- GET INFO ----------*/
  
  /*
  Returns the current enemy
  Output: current enemy, null if there's isn't one
  */
  Enemy getCurrEnemy(){
    return currEnemy;
  }
}

/*
A block of the retention test
Only difference is inits RetentionEnemy
*/
class RetentionBlock extends Block{
  RetentionBlock(Command[] commandArr, int speed, int blockNum, int stageNum, PApplet parent){
    super(commandArr, speed, blockNum, stageNum, parent);
  }
  
   /*
   Inits retention enemy
   */
   Enemy innerInitEnemy(Command currEnemyType){
     Enemy result = new RetentionEnemy(currEnemyType, speed, currShuffledIndex, stageNum, blockNum);
     return result;
   }
   
  /*
  Updates the block by advancing the current enemy, creating a new one, or ending the block if it is done.
  Output: returns true if all is good, false if all pieces are finished
  */
  boolean update(){
    // enemy already off screen, just waiting for clock to run out so can start new enemy
    if(inTrialDelay){
      int currTime = millis();
      if(currTime - delayStartTime > delayTime){
        inTrialDelay = false;
        boolean newEnemyInit = initEnemy();
        if(!newEnemyInit){
          logBlockEnd();
        }
        return newEnemyInit;
      }
    }
    // enemy killed. still true when in trial delay so needs to come second
    // ENEMY KILLED IF CORRECT OR NOT
    else if(currEnemy.isKilled()){
      inTrialDelay = true;
      app.disableInput();
      delayStartTime = millis();
    } 
    // still alive
    else {
      currEnemy.updatePosition();
    }
    return true; // when false is returned, new block is started. true does nothing
  }
  
  void draw(){
    if(!inTrialDelay){
      currEnemy.draw();
    }
  }
}