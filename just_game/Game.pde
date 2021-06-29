// global game object
Game game;

class Game{
  // stages
  int totalNumStages;
  int[] stageTypes;
  final int[] normalStageTypes = {Stage.slow, Stage.medium, Stage.fast, Stage.medium, Stage.fast, Stage.medium}; // the order the rounds will go in
  final int[] retentionStageTypes = {Stage.retention}; // the order the rounds will go in
  int stageNum; //what number round are we on ie the index in roundTypes 
  Stage currStage; // the current stage
  Command[] commandArr; // array of commands - to be used by blocks - put in game so always shuffling from same order
  final int normalStageNumBlocks = 4; // normal stages have 4 block sper stage
  final int retentionStageNumBlocks = 1; // retention stage only has 1 block
  
  // global game things
  int score = 0; // total score of the game so far, not including currStage
  boolean gameOver; // true if game is over  
  boolean started; // has the game started
  boolean stopped = false; // game is stopped after started. MUST START AS FALSE ONLY TRUE WHEN DELAYED RECEIVED
  boolean betweenStageBreak; // in break between stage
  boolean endBreak; // set when break set to end
  boolean connected; // tcp connection started
  int randomSeed;
  PApplet parent; // needed to shuffle properly
  boolean showScore = true;
  boolean showInfo = false;
  
  // able to skip through blocks and enemies for crash recovery
  // must enter skip mode before game starts
  boolean skipModeEnabled = false;
  
  /*
  Input: randomSeed is the random seed for the game
         parent is the sketch, needed to shuffle with random seed
  */
  Game(int randomSeed, PApplet parent){
    // set stage types
    if(retentionTest){
      stageTypes = retentionStageTypes;
      this.randomSeed = 200*randomSeed; // need trial order to be different than experiment
    } else {
      stageTypes = normalStageTypes;
      this.randomSeed = randomSeed;
    }
    
    this.totalNumStages = stageTypes.length;
    this.parent = parent;
    randomSeed(this.randomSeed);
    this.score = startScore; // startScore is global
    stageNum = -1; // newRound() increments it
    gameOver = false;
    started = false;
    
    // setup commandArr
    commandArr = setupCommandArr();
  }
  
  /*
  Sets up commands for game using numCommands
  if numCommands is smallCommands, just sets up white end commands
  if it's bigCommands, sets up everything
  Output: Array of all commands used in this game. NOT SHUFFLED. Block does that.
  */
  Command[] setupCommandArr(){
    Command[] result = new Command[numCommands];
    int i = 0; // current index in result
    for(Contact contact : Contact.values()){
      if(numCommands == bigCommands || contact.end.equals("W")){
        // some contacts, like B and W, are not mapped to commands.
        if(commands.containsKey(contact)){
          result[i] = commands.get(contact);
          i++;
        }
      }      
    }
    //Collection<Command> commandValues = commands.values(); // get values from commands map
    //commandValues.toArray(commandArr); // puts them in commandArry
    return result;
  }
  
  /*
  Command to start the game. Currently when conte connects but will be when user leaves splash screen
  */
  void start(){
    String id = nf(participantId, 2);
    File skipFile = new File(sketchPath(String.format("temp/P%s.txt", id)));
    if(skipFile.exists() && !retentionTest){
      try{
        enableSkipMode();
        BufferedReader reader = createReader(sketchPath(String.format("temp/P%s.txt", id)));
        String line = reader.readLine();
        String[] dataLine = split(line, " ");
        int startStage = int(dataLine[0]);
        int startBlock = int(dataLine[1]);
        int startEnemy = int(dataLine[2]);
        this.score = int(dataLine[3]);
        
        // skip 4 blocks per stage. starts at 1!
        for(int s = 1; s < startStage; s++){
          for(int b = 0; b < 4; b++){
            skipBlock();
          }
        }
        
        // skip individual blocks
        for(int b = 1; b < startBlock; b++){
          skipBlock();
        }
        
        // skip individual enemies
        for(int e = 1; e < startEnemy; e++){
          skipEnemy();
        }
        
        startFromSkip();
      }
      catch(IOException ex){}
    }
    
    // normal start
    else {
      println("normal start");
      logger.enableLogging(1,1,1);
      started = true;
      logGameStart();
      initStage();
    }
  }
  
  /*
  Stops game in middle
  */
  void stop(){
    stopped = true;
    started = false;
    skipModeEnabled = false;
    gameOver = false;
  }
  
  /*
  Logs the start of the game
  */
  void logGameStart(){
    String[] stageOrder = new String[totalNumStages];
    for(int i = 0; i < stageOrder.length; i++){
      int stageInt = stageTypes[i];
      String stageStr = stageNameToString(stageInt);
      stageOrder[i] = "\"" + stageStr + "\""; // need escaped quotes for json string
    }
    String stagerOrderJSONArr = logger.buildJSONArr(stageOrder);
    String JSONStr = logger.buildJSON("\"type\"", "\"start\"", "\"id\"", str(participantId),
                                      "\"menuType\"", "\"" + gameType + "\"",
                                      "\"numStages\"", str(totalNumStages), "\"stageOrder\"", stagerOrderJSONArr, 
                                      "\"randomSeed\"", str(randomSeed), "\"numCommands\"", str(numCommands), 
                                      "\"contactCommandPairs\"", app.contactCommandJSON());
    logger.doLog(new JSONEvent("E", "experiment", true, JSONStr));
    
  }
  
  /*
  Updates game
  */
  void update(){
    if(started){
      if(betweenStageBreak){
        if(endBreak){
          betweenStageBreak = false;
          app.enableInput();
          menu.enable();
          boolean initResult = initStage();
        }
      } else {
        boolean stageResult = currStage.update(); // true if fine, false if stage is done
        if(!stageResult){ // stage is done
          // check if this is last stage
          if(stageNum + 1 >= totalNumStages){
            gameFinished();
          } else {
            betweenStageBreak = true;
            endBreak = false;
            app.disableInput();
            menu.disable();
          }
        }
      }
    }
  }
  
  /*
  Updates the game score
  Input: deltaScore is the new score to add to the current score
  */
  void updateScore(int deltaScore){
    score += deltaScore;
  }
  
  /*
  End of game
  */
  void gameFinished(){
    gameOver = true;
    skipModeEnabled = false;
    started = false;
    logGameEnd();
  }
  
  /*
  Logs game finished event
  */
  void logGameEnd(){
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"", "\"id\"", str(participantId), "\"score\"", str(score));
    logger.doLog(new JSONEvent("E", "experiment", true, JSONStr));
  }
  
  /*---------- DRAW -----------*/
  
  /*
  Draws the current stage. Gets called after update so there is something to draw
  */
  void draw(){
    // normal game
    if(started){
        if(betweenStageBreak){
          drawBetweenStageBreak();
        } else {
          currStage.draw();
          drawInfo();
        }
    }
    // skip mode
    else if(skipModeEnabled){
      drawSplashScreen();
      drawInfo();
    }
    // game over
    else if(gameOver){
      drawGameOver();
    }
    // stopped (on delay)
    else if(stopped){
      drawStopped();
    }
    // not started    
    else{
      drawSplashScreen();
    }
  }
  
  /*
  Draws screen when stopped
  */
  void drawStopped(){
    background(app.getBackground());
    String displayStr = "CONTE DISCONNECTED";
    String infoStr = "Stage: " + (stageNum + 1) + " Block: " + (currStage.blockNum + 1) + " Enemy: " + 
                      (currStage.currBlock.currShuffledIndex + 1) + " Score: " + score;
    textAlign(CENTER, CENTER);
    fill(0);
    textSize(50);
    text(displayStr, width/2, height/2 - 40);
    text(infoStr, width/2, height/2 + 40);
  }
  
  /*
  Draws screen between stages
  */
  void drawBetweenStageBreak(){
    background(app.getBackground());
    String displayStr = "BREAK TIME";
    // at middle add extra message
    if(stageNum == stageTypes.length/2 - 1){
      displayStr += " CHANGE BATTERY!!";
    } 
    String littleDisplayStr = "push space to continue";
    textAlign(CENTER, CENTER);
    fill(0);
    textSize(50);
    text(displayStr, width/2, height/2 - 30);
    textSize(40);
    text(littleDisplayStr, width/2, height/2 + 30);
  }
  
  /*
  Draws game info at bottom of screen.
  Draws score at top
  */
  void drawInfo(){
    if(showScore){
      drawScore();
      if(showInfo){
        // draw text with stage #, block #, enemy #
        String nums = "Stage: " + (stageNum + 1) + " Block: " + (currStage.blockNum + 1) + " Enemy: " + 
                      (currStage.currBlock.currShuffledIndex + 1);
        textAlign(CENTER, BOTTOM);
        fill(0,0,0);
        textSize(40);
        text(nums, width/2.0, height-10);
      }
    }
  }
  
  /*
  Draws the current score on the screen
  */
  void drawScore(){
    String scoreStr = "Score: " + score;
    textAlign(CENTER, TOP);
    fill(0);
    textSize(40);
    text(scoreStr, width/2.0, 10);
  }
  
  /*
  Draws game over screen
  */
  void drawGameOver(){
    String gameOverStr;
    if(showScore){
      gameOverStr = "FINAL SCORE: " + score;
    } else {
      gameOverStr = "END!";
    }    
    textAlign(CENTER, CENTER);
    fill(0,0,0);
    textSize(40);
    text(gameOverStr, width/2, height/2);
    
  }
  
  /*
  Draws splash screen while waiting for conte to connect
  */
  void drawSplashScreen(){
    String splashStr = "PUSH SPACE TO START";
    if(participantId == 1){
      splashStr += "\n LISA: CHANGE PARTICIPANT ID!!";
    }
    if(retentionTest){
      splashStr += "\n LISA: don't forget to record!!";
    }
    textAlign(CENTER, CENTER);
    fill(0);
    textSize(40);    
    text(splashStr, width/2, height/2);
  }
  
  /*---------- SETUP ----------*/
  
  /*
  init new stage
  Output: returns true if new stage init, false otherwise (ie game is done)
  */
  boolean initStage(){
    stageNum++;
    if(stageNum < totalNumStages){
      int stageType = stageTypes[stageNum];
      if(stageType == Stage.retention){
        currStage = new RetentionStage(commandArr, stageType, stageNum, retentionStageNumBlocks, parent);
      } else {
        currStage = new Stage(commandArr, stageType, stageNum, normalStageNumBlocks, parent);
      }
      return true;
    } else {
      return false;
    }
  }
  
  /*
  Called when the tcp connection starts
  */
  void notifyConnected(){
    connected = true;
  }
  
  /*---------- SKIP ----------*/
  
  /*
  Puts game in skip mode - also disables logging.
  */
  void enableSkipMode(){
    logger.disableLogging();
    skipModeEnabled = true;
    initStage();
  }
  
  /*
  Skips the current block of the game
  Only called when skip mode is enabled
  */
  void skipBlock(){
    boolean skipBlockResult = currStage.skipBlock();
    // hit end of stage
    if(!skipBlockResult){
      boolean newStage = initStage();
      // hit end of available stages
      if(!newStage){
        gameFinished();
      }
    }
  }
  
  /*
  Skips the current enemy of the game
  Only called when skip mode is enabled
  */
  void skipEnemy(){
    assert skipModeEnabled : "tried skip enemy without skip mode enabled";
    boolean skipEnemyResult = currStage.skipEnemy();
    // hit end of stage
    if(!skipEnemyResult){
      boolean newStage = initStage();
      // hit end of available stages
      if(!newStage){
        gameFinished();
      }
    }
  }
  
  /*
  Starts the game after the correct location has been found
  */
  void startFromSkip(){
    // startStage, startBlock, startEnemy will be 1-indexed for use in file name.
    int startStage = stageNum + 1;
    int startBlock = currStage.blockNum + 1;
    int startEnemy = currStage.currBlock.currShuffledIndex + 1;
    
    assert skipModeEnabled : "tried to start from skip without skip mode enabled";
    skipModeEnabled = false;
    logger.enableLogging(startStage, startBlock, startEnemy);
    
    // first stage -- log game start
    if(stageNum == 0){
      println("LOG GAME START");
      logGameStart();
    }
    
    // first block in stage, need to log start of stage
    if(currStage.blockNum == 0){
      println("LOG STAGE START");
      currStage.logStageStart();
    }
    // if enemy num is 0 log block start
    Block currBlock = getCurrBlock();
    if(currBlock.currShuffledIndex == 0){
      println("LOG BLOCK START");
      currBlock.logBlockStart();
    }
    
    // log block start (if enemy is 1)
    Enemy currEnemy = getCurrEnemy();
    currEnemy.logTaskStart();
    started = true;
  }
  
  /*---------- GET INFO ----------*/
 
 /*
 Returns the current enemy
 Output: current enemy, null if there's isn't one
 */
 Enemy getCurrEnemy(){
   if(currStage != null){
     return currStage.getCurrEnemy();
   } else {
     return null;
   }
 }
 
 Block getCurrBlock(){
   if(currStage != null){
     return currStage.currBlock;
   } else {
     return null;
   }
 }
 
 /*
 Disables score being shown. It's still counted
 */
 void disableScore(){
   showScore = false;
 }
 
 /*
 Enables score being shown.
 */
 void enableScore(){
   if(!retentionTest){
     showScore = true;
   }
 }
 
 /*
 Returns current score of game
 */
 int getScore(){
   return score;
 }
 
 void toggleInfo(){
   showInfo = !showInfo;
   app.showInfo = !app.showInfo;
 }
 
  /*
  On game exit save stage block enemy score to file and then load it on crash recovery
  NOTE: If between stage break, need to save info for the first trial of the first block of the next stage
        so that it starts there.
        Otherwise, save the stage we're on
  */
  void exit(){
    if(started){
      game.stop();
      int saveStage = betweenStageBreak ? stageNum + 2 : stageNum + 1;
      int saveBlock = betweenStageBreak ? 1 : currStage.blockNum + 1;
      int saveEnemy = betweenStageBreak ? 1 : currStage.currBlock.currShuffledIndex + 1;
      String id = nf(participantId, 2);
      try {
        // create new file
        File file = new File(sketchPath(String.format("temp/P%s.txt", id)));
        PrintWriter writer = new PrintWriter(new FileWriter(file));
        writer.println(String.format("%d %d %d %d", saveStage, saveBlock, saveEnemy, score));
        writer.flush();
        writer.close();
      } catch (IOException ex) {
        println("Uncaught exception:");
        println(ex);
        System.exit(0);
      }
      
      // if not between stage break, log delay
      if(!betweenStageBreak){
        app.logDelay();
      }      
    }
  }
  
}