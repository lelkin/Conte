/*
Class to draw stuff in the game. GameApp is a terrible name since this isn't the main driver for the game
but using it to be consistent with DrawApp
*/

GameApp app;

class GameApp extends BaseApp{
  boolean feedbackEnabled = true; // show conte feedback (icons and strokes)
  boolean inputEnabled = true; // recognize downs moves and ups (disabled during feedback)
  
  GameApp(PApplet parent){
    super(parent, new GameEventWriter());
    bgd = 255;
  }
  
  /*
  Calls DrawApp.down
  Notifies enemy of contact down
  Input: See DrawApp.down input
  */
  void down(int classification, PVector[] pts, long id, int eventType){
    if(inputEnabled){
      super.enableInput(); // gets re-enabled on down so that not trying to do moves and ups if enabled in middle of stroke
    }
    super.down(classification, pts, id, eventType);
    
    // check that this classification is active
    Contact contact = classToContact.get(classification);
    // if big commands then all active. otherwise only white end active.
    // if contact is not active do nothing.
    if(contact != null && isActive(contact)){
      if(currCmd != null && currCmd.drawCmd){
        notifyEnemyDown(pts);
      }
    }
  }
  
  /*
  Notifies the current enemy of a down event
  Done one all types of commands
  Input: Array of most recently seen points
  */
  void notifyEnemyDown(PVector[] pts){
    PVector pt = pts[pts.length - 1];
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.down(pt);
    }
  }
  
  /*
  Calls DrawApp.move
  if currCmd is a drawCmd, notifies currEnemy of a move
  Input: see DrawApp.move input
  */
  void move(PVector[] pts, long id, int eventType){
    // get command from above
    // if in play do below
    // else do nothing
    super.move(pts, id, eventType);
  }
  
  /*
  Update the current stroke (super does this) and calls notifyEnemyMove with the last elem of pts
  Input: pts is the array of points to add to the stroke
         id is the id number of the point
  */
  void updateStroke(PVector[] pts, long id){
    super.updateStroke(pts, id);
    notifyEnemyMove(pts[pts.length - 1]);
  }
  
  /*
  Updates the current stroke when it's a multipoint - input is single PVector instead of array
  and calls notifyEnemyMove with this point
  Input: pt is the single point to update with
         id is the id number of the point
  */
  void updateMultiStroke(PVector pt, long id){
    super.updateMultiStroke(pt, id);
    notifyEnemyMove(pt);
  }
  
  /*
  Notifies enemy of move event
  Only done on draw commands
  Input: Most recently seen point
  */
  void notifyEnemyMove(PVector pt){
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.move(pt, currCmd);
    }
  }
  
  /*
  Calls DrawApp.up
  Notifies enemy of up event for draw commands
  Input: see DrawApp.up input
  */
  void up(PVector[] pts, long id, int eventType){
    super.up(pts, id, eventType);
  }
  
  /*
  Called by super.up after all points on the stroke have been updated
  Just calls notifyEnemyUp()
  Input: pt is the last seen point on up
  */
  void cleanUpDrawCmd(PVector pt){
    super.currStroke.logStrokeEnd();
    notifyEnemyUp(pt);
  }
  
  /*
  Notifies current enemy of an up event
  Only done on draw commands
  */
  void notifyEnemyUp(PVector pt){
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.up(currCmd, pt);
    }
  }
  
  /*
  Used for "one-time" commands
  We don't actually want to execute the command, just setup the feedback
  Input: pts is the location we're executing this command from
  */
  void executeCommand(PVector pts){
    setupFeedback(pts); // sets up the icon for this command
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.notifySelected(currCmd, pts); // notify enemy that this command has been selected
    }
  }
  
  /*
  Contact that was just lifted counts as incorrect - called when inactive or null contact used
  Inactive occurs when just not active
  Null occurs in fast tap when inner most rectangle is selected or nothing is selected
  Input: currContact is the contact that was selected (can be null)
         pt is the location of the touch
  */
  void countAsWrong(Contact currContact, PVector pt){
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      logInactiveOrNull(currContact, pt, currEnemy);
      currEnemy.doWrongSelection("wrong");
    }
  }
  
  /*
  Called by countAsWrong. Logs this selection
  */
  void logInactiveOrNull(Contact currContact, PVector pt, Enemy currEnemy){
    Command conteCmd = commands.get(currContact);
    Command enemyCmd =  currEnemy.cmd;
    String conteCmdName = conteCmd == null ? "null" : conteCmd.name; // can't use .name field if cmd is null
    String JSONStr = logger.buildJSON("\"type\"", "\"inactiveOrNull\"",
                                  "\"selected\"", "\"" + conteCmdName + "\"",
                                  "\"correct\"", "\"" + enemyCmd.name +  "\"",
                                  "\"x\"", str(int(pt.x)), "\"y\"", str(int(pt.y))
                                  );
    logger.doLog(new JSONEvent("K", "error", false, JSONStr));
  }
  
  /*
  Called when stroke cancelled
  Calls BaseApp.cancel
  Notifies current enemy of a cancellation for a draw command
  */
  void cancel(PVector[] pts, long id){
    if(currCmd != null){
      notifyEnemyCancel();
    }
    super.cancel(pts, id);
  }
  
  /*
  Backup cancel in case on points available
  */
  void cancel(){
    if(currCmd != null){
      notifyEnemyCancel();
    }
    super.cancel();
  }
  
  /*
  Notifies current enemy of a cancelled point
  Only called for draw commands
  */
  void notifyEnemyCancel(){
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.cancel();
    }    
  }
  
  /*
  Notifies current enemy that the menu has been opened
  Enemy decides whether it's a score deduction or now
  */
  void doMenuScoreDeduction(){
    Enemy currEnemy = game.getCurrEnemy();
    if(currEnemy != null){
      currEnemy.doMenuScoreDeduction();
    }
  }
  
  void draw(){
    menu.update();
    if(menu.isOn){
      menu.draw();
    } else {
      if(feedbackEnabled){
        super.draw();
      }
    }
  }
  
  /*---------- MISC ----------*/
  
  /*
  disables feedback. Used by retention test. and between trials
  */
  void disableFeedback(){
    feedbackEnabled = false;
  }
  
  /*
  enable input
  */
  void enableInput(){
    inputEnabled = true;
  }
  
  /*
  disable input
  */
  void disableInput(){
    inputEnabled = false;
    super.disableInput();
  }
  
  /*
  Called when receive a message from just_conte that it hasn't received anything from conte in too long
  If game is started, stops game and shows stage, block, enemy, and score on screen
  Logs this info as well
  */
  void delayed(){
    if(game.started){
      game.stop();
      logDelay();
    }
  }
  
  /*
  Logs the delay
  */
  void logDelay(){
    String JSONStr = logger.buildJSON("\"type\"", "\"delay\"", "\"stageNum\"", str(game.stageNum + 1),
                                      "\"blockNum\"", str(game.currStage.blockNum + 1),
                                      "\"trialNum\"", str(game.currStage.currBlock.currShuffledIndex+1),
                                      "\"score\"", str(game.score));
    logger.doLog(new JSONEvent("E", "experiment", true, JSONStr));
  }
}

/*
extend to use fast tap menu instead of normal menu
*/
class FastTapApp extends GameApp{
  final int menuBufferTime = 150; // number of millis after menu deactive that we still interpret a down as menu
  boolean missingAppUp = false; // saw down but didn't see up
  
  FastTapApp(PApplet parent){
    super(parent);
    changeContacts();
  }
  
  /*
  Need to set numPts for WME1 to 1 so that it draws even if participants use the corner
  (which is the most likely thing)
  */
  void changeContacts(){
    Contact.WME1.numPts = 1;
  }
  
  /*
  Does down. For fast tap
  */
  void down(int classification, PVector[] pts, long id, int eventType){
    // if menu is on down on menu
    if(menu.isOn){
      menu.down(pts[pts.length-1]);
    } 
    // menu is off but this really was a down for the menu
    else if (shouldBeMenu()){
      menu.down(pts[pts.length-1]);
    }
    // actual down in game
    else {
      Contact menuContact = menu.getContact();
      // if null was selected then do nothing
      if(menuContact != null){
        missingAppUp = true;
        int menuClassification = contactToClass.get(menuContact);
        super.down(menuClassification, pts, id, eventType);
      } else {
        missingAppUp = true;
        int menuClassification = -1;
        super.down(menuClassification, pts, id, eventType);
      }
    }
  }
  
  void move(PVector[] pts, long id, int eventType){
    // menu is ACTUALLY off
    if(!menu.isOn && !menu.missingUp()){
      super.move(pts, id, eventType);
    }
  }
  
  void up(PVector[] pts, long id, int eventType){
    // there's only an app up event if there was an app down event.
    if(missingAppUp){
      super.up(pts, id, eventType);
      missingAppUp = false; 
    }
    else if(!menu.isOn){
      // menu isn't on but didn't see up to last menu down. this is the menu up
      if(menu.missingUp()){
        menu.up();
      } 
    } 
    // menu is on. this is just a menu up
    else {
      menu.up();
    }
  }
  
  /*---------- HELPERS FOR DOWN MOVE UP FAST TAP ----------*/
  
  /*
  Called on down, returns true if occured close enough to menu deactive time that should be a menu down
  */
  boolean shouldBeMenu(){
    int currTime = millis();
    return (currTime - menu.getInactiveTime() < menuBufferTime);
  }
}