/*
Contains all info for the enemies ie the blocks that fall.
*/

class Enemy{  
  Command cmd; // gives us image, sliceRequired, name.
  boolean sliceRequired; // from cmd
  PImage img; // from cmd
  String stringName;
  int enemyNum; // 0 indexed since start of block
  int stageNum; // needed for logging
  int blockNum; // needed for logging
  
  // selecting
  boolean killed; // enemy has been CORRECTLY sliced or selected
  // gets set to true on down
  // set to false when we see a swipe from conte or a command executed from conte
  // does not depend on type of enemy cmd
  boolean killable;
  PVector lastPt; // last point we saw - only used for enemies that are sliceRequired
  
  // enemy location
  int cx;
  float left;
  float right;
  float top;
  float bottom;
  final float w = 100;
  final float h = 100;
  int cornerBezel = 10; // for drawing rectangle
  
  // speed
  float timeToBottom; // how long should it take for the enemy to get to the bottom of the screen
  float pixelsPerSecond;
  
  // drawing
  // background colours
  final int br = 155;
  final int bg = 155;
  final int bb = 155;
  // gradient colours
  int gradR;
  int gradG;
  int gradB;
  // red gradient
  boolean drawGradient; // true when we should be  drawing the red gradient, false otherwise
  final int maxAlpha = 155; // max possible alpha for outside of gradient
  float currMaxAlpha; // current max alpha for outside of gradient - goes from maxAlpha to 0
  boolean waitingForGreenToFade = false; // longest name ever. True when enemy has been killed but just waiting for the gradient to fade
  
  // score
  final int correctScore = 50; // score for getting the right choice
  final int wrongChoiceDeduction = 15; // lose 15 points for every wrong choice
  int numWrongChoices; // number of wrong choices so far for this enemy
  final int maxNumWrongChoices = 3; // max number of times can get deducted for an incorrect choice per enemy
  final int menuDeduction = 10; // lose ten points for looking at the menu at most ONCE per enemy
  boolean usedMenu; // used to make sure menuDeduction is only taken once 
  
  Enemy(Command cmd, float timeToBottom, int enemyNum, int stageNum, int blockNum){
    app.enableInput(); // in case up came in right after end killed from previous enemy
    menu.enable(); // in case some how miss it at end of last enemy
    this.cmd = cmd;
    this.sliceRequired = cmd.drawCmd;
    this.img = cmd.img;
    this.stringName = cmd.name;
    this.killed = false;
    this.killable = false;
    this.numWrongChoices = 0;
    this.usedMenu = false;
    this.drawGradient = false;
    this.enemyNum = enemyNum;
    this.stageNum = stageNum;
    this.blockNum = blockNum;
    
    setupSpeed(timeToBottom);
    setupLocation();
    logTaskStart();
  }
  
  /*---------- SWIPE AND SELECT ----------*/
  
  /*
  Returns true if the enemy has been swiped by the correct conte contact point, false otherwise
  Output: True if swiped correctly (or just selected) and user gets point, false otherwise
  */
  boolean isKilled(){
    return killed;
  }
  
  /*
  Called when an enemy has been swipe by a draw point on conte or when a non-draw command has been executed
  Only called if the enemy is "killable"
  Input: conteCmd is the command on the conte stick that was swiped/selected.
         This may or may not match up with the command on the enemy
         pts are the selection points
           one point for one time command and the two swipe points for swipe commands
  */
  void notifySelected(Command conteCmd, PVector... pts){
    if(checkKilled(conteCmd)){
      logSelectionWrapper(conteCmd, true, pts);
      game.updateScore(correctScore);
      doKilledWrapper(conteCmd);
    } else {
      logSelectionWrapper(conteCmd, false, pts);
      doWrongSelection("wrong");
    }
    killable = false; // either way, not killable until next down
  }
  
  /*
  Always calls doKilled
  If command was a tap command, disables Input to the app. 
  Input gets disabled on up for draw commands
  Input: conteCmd is the command that's being executed by Conte
  */
  void doKilledWrapper(Command conteCmd){
    if(!conteCmd.drawCmd){
      app.disableInput();
    }
      doKilled();
  }
  
  /*
  Called when a command is selected or a drawCmd enemy is swiped through
  Checks if it's the correct command
  Input: conteCmd is the conte command that was selected
  Output: true if it's the correct command, false otherwise
  */
  boolean checkKilled(Command conteCmd){
    String conteCmdName = conteCmd.name;
    return conteCmdName.equals(stringName);      
  }
  
  /*
  sets up green gradient Ani
  */
  void doKilled(){
    logTaskEnd("selected");
    waitingForGreenToFade = true;
    int r = 0;
    int g = 255;
    int b = 0;
    String endFuncStr = "onEnd:endKilled"; // function to call at end of fade
    int fadeTime = 1;
    int minAlpha = 0;
    setupGradient(r, g, b, endFuncStr, fadeTime, minAlpha);
  }
  
  void endKilled(){
    killed = true;
    drawGradient = false;
    app.enableInput();
    menu.enable();
  }
  
  /*
  Called when an incorrect selection is made. Updates the score accordingly and flashes border of enemy red
  Input: reason not needed here, but is needed by retetion Enemy
  */
  void doWrongSelection(String reason){
    // deduct points
    if(numWrongChoices < maxNumWrongChoices){
      numWrongChoices++;
      game.updateScore(-wrongChoiceDeduction);
    }
    
    // flash red even if no points deducted
    setupGradient(255,0,0,"onEnd:gradOff",2,0);
  }
  
  /*
  Sets drawGradient to false so we don't spike frame rate forever
  */
  void gradOff(){
    drawGradient = false;
  }
  
  /*
  Called on conte down for a drawCmd point
  sets killable to true and updates lastPt
  */
  void down(PVector pt){
    killable = true;
    lastPt = pt;
  }
  
  /*
  Called on conte move for a drawCmd point
  checks if this point and last point were both in the enemy and notifies selected if they were
  Input: pt is the new location of Conte
         conteCmd is the command Conte is currently selecting
  */
  void move(PVector pt, Command conteCmd){

    // sometimes conte is moving right when we get a new block, but there hasn't been a down event so it's not killable yet
    if(killable){
      if(hitTest()){
        notifySelected(conteCmd, lastPt, pt);
      } else {
        lastPt = pt;
      }
    }
  }
  
  /*
  Called on conte up for a drawCmd point
  If drawCmd was correct, need to disable input here.
  Input: conteCmd is the command Conte is currently selecting
         pt is the last seen point on up
  Note: On a up event, Enemy.move gets called before enemy.up so if the enemy is still killable, the selection is wrong
  */
  void up(Command conteCmd, PVector pt){
    if(killable){
      logMissedTarget(conteCmd, pt);
      doWrongSelection("missed"); // Didn't swipe block
      lastPt = null; // make sure next point has to start from scratch
      killable = false; // not really needed here but might as well
    }
    // not killable doesn't mean the cmd was correct. If it swiped through the enemy, it won't be killable
    if(waitingForGreenToFade){
      app.disableInput();
    }
  }
  
  /*
  Called on conte cancel for a drawCmd point
  clears all info
  */
  void cancel(){
    doMenuScoreDeduction();
    lastPt = null;
    killable = false;
  }
  
  /*
  Deducts from score for using the menu
  Takes off 10 points for using at least once for a given enemy
  */
  void doMenuScoreDeduction(){
    if(!usedMenu){
      game.updateScore(-menuDeduction);
      usedMenu = true;
    }
  }
 
  
  /*
  Looks at stroke and checks if any point on its path at all intersects with block
  If it does, checks that stroke is long enough to count
  Output: true if stroke intersects with enemy and is long enough
  */
  boolean hitTest(){
    Stroke currStroke = app.getCurrStroke();
    if(currStroke != null){
      // there is a point that intersects and stroke is long enough
      //return(pathTest(currStroke) && lengthTest(currStroke));
      return(lengthTest(currStroke));
    }
    // no stroke that's weird
    return false;
  }
  
  /*
  Checks if at least on entry in path of stroke intersects with enemy
  Input: stroke we're testing
  Output: true on first found entry (checking from newest to oldest)
          false otherwise
  NOTE: it seems kind of dumb to check the whole path every time but you can draw it lower and wait for the block to fall
  */
  boolean pathTest(Stroke currStroke){
    ArrayList<PVector> path = currStroke.getPts();
    // iterate from newest to oldest
    for(int i = path.size() - 1; i >= 0; i--){
      PVector currPt = path.get(i);
      if(singleHit(currPt)){
        return true;
      }
    }
    return false; // nothing intersected
  }
  
  /*
  checks if stroke's path is long enough to count
  Input: currStroke is stroke we're testing
  Output: true is long enough
          false otherwise
  */
  boolean lengthTest(Stroke currStroke){
    int minLength = 20; // smallest number of pixels
    return(currStroke.getLen() >= minLength);
  }
  
  /*
  Returns true if pt is inside the enemy
  Input: pt is the point
  Output: true if it's inside the enemy, false othwerise
  */
  boolean singleHit(PVector pt){
    int hitMargin = 10; // add 10 pixel margin on block all around
    boolean result = left - hitMargin <= pt.x && pt.x <= right + hitMargin && top - hitMargin <= pt.y && pt.y <= bottom + hitMargin;
    return result;
  }
  
  /*---------- DRAW ----------*/
  
  /*
  Returns true if the enemy is completely off the screen, false otherwise
  Output: True if enemy is completely off the screen, false otherwise
  */
  boolean offScreen(){
    if(top >= height){
      logTaskEnd("offscreen");
    }
    return (top >= height);
  }
  
  /*
  Updates the position of the enemy.
  */
  void updatePosition(){
    if(!waitingForGreenToFade){
      float currFrameRate = frameRate;
      float pixelsPerFrame = pixelsPerSecond/currFrameRate;
      top += pixelsPerFrame;
      bottom += pixelsPerFrame;
      logTaskPosition();
    }
  }
  
  /*
  Sets up and starts a gradient
  Input: r,g,b are the gradient r,g,b colours
         endFunc is the string for the onEnd arg of Ani.to - ie the function to call on end
         fadeTime is the amount of time in seconds to fade
         minAlpha is the value currMaxAlpha fades to
  */
  void setupGradient(int r, int g, int b, String endFunc, float fadeTime,int minAlpha){
    gradR = r;
    gradG = g;
    gradB = b;
    currMaxAlpha = maxAlpha;
    drawGradient = true;
    Ani.to(this, fadeTime, "currMaxAlpha", minAlpha, Ani.EXPO_IN_OUT, endFunc); 
  }
  
  /*
  Draws the enemy in the current position
  */
  void draw(){
    // draw enemy
    noStroke();
    fill(br, bg, bb);
    rect(left, top, w, h, cornerBezel);
    
    if(drawGradient){
      drawGradient();
    }
    
    // draw image on enemy
    imageMode(CENTER);
    image(img, (left + w/2.0), top + (h/2.0));
  }
  
  /*
  Draws a red gradient on the outer edge of the enemy
  Assumes square enemy
  */
  void drawGradient(){
    float cx = left + w/2.0;
    float cy = top + h/2.0;
    int maxRad = int(w/2);
    float minRadFactor = 0.65; // how far from center to start gradient
    int minRad = int(minRadFactor*maxRad);
    int minAlpha = 0;
    noStroke();
    for(int rad = maxRad; rad >= minRad; rad--){
      int currAlpha = int(map(rad, maxRad, minRad, currMaxAlpha, minAlpha));
      // draw grey over where we're going to draw
      fill(br, bg, bb, 255);
      rect(cx - rad, cy - rad, 2*rad, 2*rad, cornerBezel);
      // draw red
      fill(gradR, gradG, gradB, currAlpha);
      rect(cx - rad, cy - rad, 2*rad, 2*rad, cornerBezel);
    }
  }
  
  /*---------- SETUP AND LOG ----------*/
  
  /*
  Calculate the number of pixels per second that this enemy needs to travel
  */
  void setupSpeed(float timeToBottom){
    this.timeToBottom = timeToBottom;
    float totalTravelDistance = height + h; // starts with bottom at zero, has to get to top at height
    this.pixelsPerSecond = totalTravelDistance/timeToBottom;
  }
  
  /*
  Sets up the initial location of the enemy
  */
  void setupLocation(){
    // find center x location
    int margin = 50; // leave a margin px border around the sides
    float minCx = margin + w/2.0;
    float maxCx = width - (w/2.0) - margin;
    cx = int(random(minCx, maxCx));
    
    // get rest of points from Cx
    left = cx - (w/2.0);
    right = left + w;
    top = -h;
    bottom = 0; // starts just above screen
  }
  
  /*
  Logs start of task
  */
  void logTaskStart(){
    String pixelsPerSecondStr = floatToStr(pixelsPerSecond);
    String JSONStr = logger.buildJSON("\"type\"", "\"start\"", 
                                      "\"command\"", "\"" + stringName + "\"",
                                      "\"currScore\"", str(game.getScore()),
                                      "\"stageNum\"", str(stageNum + 1),
                                      "\"blockNum\"", str(blockNum + 1),
                                      "\"num\"", str(enemyNum+1),
                                      "\"dropTime\"", str(int(timeToBottom)), 
                                      "\"pixelsPerSecond\"", pixelsPerSecondStr,
                                      "\"startX\"", str(cx),
                                      "\"width\"", str(w),
                                      "\"height\"", str(h)
                                      );
    logger.doLog(new JSONEvent("E", "task", true, JSONStr));
  }
  
  /*
  Logs end of task
  Input: reason task ended (selected/offscreen)
  */
  void logTaskEnd(String reason){
    menu.disable();
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"", 
                                  "\"num\"", str(enemyNum+1),
                                  "\"endReason\"", "\"" + reason + "\""
                                  );
    logger.doLog(new JSONEvent("E", "task", true, JSONStr));
  }
  
 /*
 Wrapper for logging selections
 Calls relevant logSwipeSelection or logNonSwipeSelection
 Input: conteCmd is the selected command
        correct is true if it's the right selection, false otherwise
        pts are the selection points (two swipe points for swipe, one point for one-time commands)
 */ 
  void logSelectionWrapper(Command conteCmd, boolean correct, PVector... pts){
    if(conteCmd.drawCmd){
      logSwipeSelection(conteCmd, correct, pts[0], pts[1]);
    } else {
       logTapSelection(conteCmd, correct, pts[0]);
    }
  }
  
  /*
  Log an incorrect swipe
  Input: conteCmd is the command that was selected
         pt1 and pt2 are the two swipe points
         correct is true if it's the correct command, false otherwise
  */
  void logSwipeSelection(Command conteCmd, boolean correct, PVector pt1, PVector pt2){
    String JSONStr = logger.buildJSON("\"type\"", "\"swipe\"",
                                      "\"selected\"", "\"" + conteCmd.name + "\"",
                                      "\"correct\"", "\"" + cmd.name +  "\"",
                                      "\"x1\"", str(int(pt1.x)), "\"y1\"", str(int(pt1.y)), 
                                      "\"x2\"", str(int(pt2.x)), "\"y2\"", str(int(pt2.y))
                                      );
    String correctStr = correct ? "correct" : "error";
    logger.doLog(new JSONEvent("K", correctStr, false, JSONStr));
  }
  
  /*
  Logs a non-swipe selection
  Input: conteCmd is the command that was selected
         pt is the selection location
         correct is true if it's the correct command, false otherwise
  */
  void logTapSelection(Command conteCmd, boolean correct, PVector pt){
    String JSONStr = logger.buildJSON("\"type\"", "\"tap\"",
                                      "\"selected\"", "\"" + conteCmd.name + "\"",
                                      "\"correct\"", "\"" + cmd.name +  "\"",
                                      "\"x\"", str(int(pt.x)), "\"y\"", str(int(pt.y))
                                      );
    String correctStr = correct ? "correct" : "error";
    logger.doLog(new JSONEvent("K", correctStr, false, JSONStr));
  }
  
  /*
  Logs missed targets (ie we draw something with conte and it doesn't swipe the target)
  CALLED WHETHER CORRECT CONTACT OR NOT!
  Only called when we draw with a draw point, not dependent on the type of point we SHOULD be drawing with
  */
  void logMissedTarget(Command conteCmd, PVector pt){
    String JSONStr = logger.buildJSON("\"type\"", "\"miss\"",
                                      "\"selected\"", "\"" + conteCmd.name + "\"",
                                      "\"correct\"", "\"" + cmd.name +  "\"",
                                      "\"x\"", str(int(pt.x)), "\"y\"", str(int(pt.y))
                                      );
   logger.doLog(new JSONEvent("K", "error", false, JSONStr));
  }
  
  /*
  Log new task position (ie position of falling block)
  */
  void logTaskPosition(){
    float cy = (top + bottom)/2.0;
    String JSONStr = logger.buildJSON("\"x\"", str(int(cx)), "\"y\"", floatToStr(cy));
    logger.doLog(new JSONEvent("K", "pos", false, JSONStr));
  }
  
  /*
  Converts float f to a 1 decimal string
  Input: f is the float
  Output: string version of f
  */
  String floatToStr(float f){
    return String.format("%.1f", f);
  }
}

/*
Enemy for retention test.
*/
class RetentionEnemy extends Enemy{
  
  RetentionEnemy(Command cmd, float timeToBottom, int enemyNum, int stageNum, int blockNum){
    super(cmd, timeToBottom, enemyNum, stageNum, blockNum);
  }
  
  /*------------ SETUP AND LOG -----------*
  
  /*
  Calculate the number of pixels per second that this enemy needs to travel
  */
  void setupSpeed(float timeToBottom){
    this.timeToBottom = 0; // really should be infinity but wont use it and don't wanna log a huge number.
    this.pixelsPerSecond = 0; // doesn't move
  }
  
  /*
  Sets up the initial location of the enemy
  Retention test always in the middle
  */
  void setupLocation(){
    cx = width/2;
    float cy = height/2;
    
    // get rest of points from Cx
    left = cx - (w/2.0);
    right = left + w;
    top = cy - (h/2.0);
    bottom = top + h; // starts just above screen
  }
  
  /*---------- SWIPE AND SELECT ----------*/
  
  /*
  For retention enemy, show no feedback on killed.
  */
  void doKilled(){
    logTaskEnd("selected");
    killed = true;
    //startTimer(); // TODO. do a 1 second timer
  }
  
  /*
  Called when an incorrect selection is made. 
  Updates the score accordingly, sets killed to true and logs task end.
  Input: reason can be "wrong" or "missed". Missed doesn't mean wrong. It just means target was missed
  */
  void doWrongSelection(String reason){
    logTaskEnd(reason);
    killed = true;
  }
}