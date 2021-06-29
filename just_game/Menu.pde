/*
Controls the menu activation and location

MenuBase is the base class that has things that are common to both
MenuRoll is when the roll to menu is used - state manager type must be StateManagerRoll
Menu3D is when the 3D menu is used - state manager type must be StateManager3D
*/

//MenuRoll menu;
MenuBase menu;

/*---------- MENU BASE ----------*/
abstract class MenuBase{
  // really only needed by menu roll but called somewhere so put it here
  boolean menuFlip = true; // true for white end, false for black
  boolean delayFinished = false; // last time menu was turned on, did delay finish
  
  boolean isOn = false; // is the menu on right now
  int timeTurnedOn; // time menu was turned on
  final int delay = 500; // number of milliseconds to wait after menu is turned on to actually display it
  int inactiveTime; // last time menu was deactivated
  boolean inRetentionMode = false; // menu can still be activated by not opened
  boolean enabled = true; // menu can't be activated (or opened)
  
  void draw(){}
  
  /*
  returns true if delay over, false otherwise
  also sets delay finished to true if it use
  */
  private boolean delayDone(){
    int currTime = millis();
    int timePassed = currTime - timeTurnedOn;
    return timePassed > delay;
  }
  
  /*
  All menu updates: check if delay done. If it is log menu open and tell game to deduct points
  */
  void update() {
    // want to capture FIRST time delay is finished when menu is on!
    if(isOn){
      if(!delayFinished){
        if(delayDone() && !inRetentionMode){
          delayFinished = true; // draw needs this to draw
          logMenu("O");
          app.doMenuScoreDeduction();
          game.disableScore();
        }
      }
    }
  }
  
  /*
  Set active means menu key is pushed
  */
  void setActive(){
    if(enabled){
      timeTurnedOn = millis();
      delayFinished = false;
      isOn = true;
      logMenu("A");
    }
  }
  
  /*
  setInactive means menu key is released
  */
  void setInactive(){
    if(enabled){
      game.enableScore();
      // set inactive time -- needed to detect downs that should have come before but come in after
      inactiveTime = millis();
      if(isOn){
        logMenu("D");
      }
      isOn = false;
    }
  }
  
  // only implemented by roll
  //void setMenuOn(PointComplete firstMenuPt, PointComplete secondMenuPt, int fromType){}
  
  // to calibrate yaw
  void calibrate(){}
  
  /*
  Returns true if menu has already been calibrated, false otherwise
  */
  boolean isCalibrated(){return false;}
  
  /*
  3d uses this
  */
  void toggleReal(){}
  
  /*
  Logs this menu action
  Input: eventType: A/D for activate/deactivate
  */
  void logMenu(String eventType){
    logger.doLog(new MenuTechniqueEvent(eventType));
  }
  
  /*
  fast tap menu needs down, move, up
  */
  void down(PVector pt){}
  
  void move(PVector pt){}
  
  void up(){}
  
  Contact getContact(){
    return null;
  }
  
  // fast tap always draws grid in background
  void drawBackgroundGrid(){}
  
  boolean missingUp(){return false;}
  
  int getInactiveTime(){
    return inactiveTime;
  }
  
  /* 
  number of menu levels in fast tap menu
  dummy here
  */
  float[] gridParams(){
    float[] result = {0};
    return result;
  };
  
  /*
  In retention Mode, menu can be activated but not opened.
  When disabled, it also can't be opened.
  */
  void retentionModeOn(){
    inRetentionMode = true;
  }
  
  void enable(){
    enabled = true;
  }
  
  void disable(){
    setInactive();
    enabled = false;
  }
}

/*---------- FAST TAP ----------*/
class MenuFastTap extends MenuBase{
  
  MenuDisplayFastTap menuDisplay; // display object
  Contact menuContact; // last seen contact chosen on menu
  boolean selectionMade = false; // will be true if something selected last time menu turned on
  PVector downPt = new PVector(-1,-1); // down location. Needed for tap event
  boolean missingUp = false; //saw a down with no matching up pair 
  
  MenuFastTap(){
    menuDisplay = new MenuDisplayFastTap();
  }
  
  /*
  Draws grid background
  */
  void drawBackgroundGrid(){
    menuDisplay.drawBackgroundGrid();
  }
  
  /*
  Display menu
  */
  void draw(){
    // on means key is pressed
    if(isOn){
      // menu is active and open (ie novice mode)
      if(delayFinished){
        menuDisplay.draw();
      }
      // not open, just active (ie expert mode)
      else {
        menuDisplay.drawFeedback();
      }
    }
  }
  
  /*
  Turns menu on FAST TAP
  */
  void setActive(){
    if(enabled){
      selectionMade = false;
      menuDisplay.resetSelection();
      super.setActive();
    }
  }
  
  /*
  Turns menu off
  */
  void setInactive(){
    super.setInactive();
  }
  
  /*
  Executes selected tap commands. Called by setInactive and up
  */
  void fastTapInactive(){
    // if tap command selected this time, run command
    if(selectionMade){
      if(menuContact != null){
        Command selectedCmd = commands.get(menuContact);
        if(!selectedCmd.drawCmd){
          // fire event. all nums are irrelevant except pts
          PVector[] ptArr = {downPt};
          app.down(0, ptArr, 0, 0);
          app.up(ptArr, 0, 0);
        }
      }
    }
  }
  
  /*
  When menu is on and conte down is seen, this is called
  Input: pt is the x,y coordinate that was seen
  */
  void down(PVector pt){
    downPt = pt;
    missingUp = true;
    selectionMade = true;
    Contact result = menuDisplay.getContact(pt); // classifier.classification
    menuContact = result;
    logger.doLog(new MenuSelectionTechniqueEvent(result)); // log the selection
  }
  
  /*
  When menu is on and conte up is seen, this is called
  */
  void up(){
    missingUp = false; // this is the matching up to the down
    
    // menu has been deactivated but this up was actually for the menu
    // need to execute tap commands still in this case
    if(!isOn){
      //fastTapInactive();
    }
  }
  
  /*
  returns value of missing up var which is true when seen down with now matching up
  Output: true is seen menu down with no matching up, false otherwise
  */
  boolean missingUp(){
    return missingUp;
  }
  
  /*
  returns last seen contact
  */
  Contact getContact(){
    return menuContact;
  }
  
  /*
  Output: {levels, marginW, marginH, cellW, cellH}
  */
  float[] gridParams(){
    return menuDisplay.gridParams();
  }
  
} // end MenuFastTap class

/*---------- MENU 3D ----------*/
class Menu3D extends MenuBase{
  
  MenuDisplay3D menuDisplay; // display object
  
  Menu3D(){
    if(mirrored){
      menuDisplay = new MenuDisplayMirror3D();
    } else {
      menuDisplay = new MenuDisplayOrig3D();
    }
    
    //menuDisplay = new WireMenu();
  }
  
  /*
  Display menu
  */
  void draw(){
    if(isOn && delayFinished){
      menuDisplay.draw();
    }
  }
  
  /* 
  Update menu on screen
  Currently checks if menu display has been calibrated and calibrates if not
  NOTE: menuDisplay will not be calibrated until a reading comes in from the imu
  */
  void update(){
    if(!menuDisplay.isCalibrated()){
      menuDisplay.calibrate();
    }
    super.update();
  }
  
  /*
  Gets menuDisplay to calibrate yaw
  */
  void calibrate(){
    int oldYaw = menuDisplay.getYawZero();
    menuDisplay.calibrate();
    int newYaw = menuDisplay.getYawZero();
    logCalibration(oldYaw, newYaw);
  }
  
  /*
  Toggles between actual mirror menu and the locked angles one
  */
  void toggleReal(){
    menuDisplay.toggleReal();
  }
  
  /*
  Logs calibration
  Input: oldYaw is old yaw zero before calibrated
         newYaw is new calibrated yaw zero (ie what is yaw when facing forward)
         DEGREES
  */
  private void logCalibration(int oldYaw, int newYaw){
    logger.doLog(new CalibrateTechniqueEvent(oldYaw, newYaw));
  }  
}

/*---------- MENU ROLL ----------*/
//class MenuRoll extends MenuBase{
//  MenuDisplay menuDisplay; // menu display object
  
//  int rollFromType = -1; // type we rolled up from. Needed for the redraw
//  long[] menuIds; // the id numbers of the two end points of the menu. PointComplete.sessionId of each point
//  PointComplete lastMenuPt1 = null; // last used points
//  PointComplete lastMenuPt2 = null;
  
//  float menuAngle = 0; // angle menu is rotated by in RADIANS
//  float menuX = 0; // center x of menu
//  float menuY = 0; // center y of menu

  
//  int i = 0; // DEBUG
  
//  MenuRoll(){
//    menuIds = new long[2];
//    menuDisplay = new MenuDisplay();
//  }
  
//  /*--------- DRAW ---------*/
//  /*
//  Draws the menu on the screen
//  */
  
//  void draw(){
//    // use negative of menuAngle since processing does them the other way
//    menuDisplay.draw(menuX, menuY, -menuAngle, menuFlip);
//  }
  
//  /*--------- UPDATE ---------*/
  
//  /*
//  Updates state of menu.
//  */
//  void update(){
//    if(isOn){
//      rotate();
//    } // if(isOn)
//  } // update
  
//  /*
//  Sets menu's deactivate flag so menu will be deactivated on next update
//  Used by pointCollection to alert menu of up event
//  */
//  void setInactive(){
//    deactivate();
//  }
  
//  /*
//  Deactivates the menu
//  Note: This is called by menu.update() which is called AFTER pointCollection.update()
//  Ups get updated by pointCollection.update so they've all been added to the mainQueue before this
//  ie it's same to just delete the mainQueue
//  */
//  void deactivate(){
//    // log
//      int menuType = Classifier.blackSide;
//      if(menuFlip){
//        menuType = Classifier.whiteSide;
//      }
//    logMenu("U", lastMenuPt1, lastMenuPt2, int(menuAngle), menuType);
    
//    isOn = false;
//    pointCollection.clearMainQueue();
//  }
  
//  /* 
//  Rotates the menu in the next frame depending on the location of the end points.
//  Since we now use a relative location for the frame of reference, we always know where the roll point is
//  with relation to the two points on the ends. So we just recompute the angle, based on the new location of
//  the original points complete and update everything
//  */
//  void rotate(){
//    // get new locations of menu end points
//    PointComplete menuPt1 = pointCollection.findRecentById(menuIds[0]);
//    PointComplete menuPt2 = pointCollection.findRecentById(menuIds[1]);
    
//    // sometimes we don't detect an up but we lose contact with the menu end points
//    if(menuPt1 != null && menuPt2 != null){
//      // find the two possible angles this shape could be
//      float[] possibleRotationAngles = getPossibleAngles(menuPt1, menuPt2);
//      // of those two, actualAngle is the one with a smaller difference from our current angle
//      // note this method only works if we assume that the user moves the menu by less than 90 degress in one frame
//      float actualAngle = findSmallerDiff(possibleRotationAngles);
      
//      // update menu fields
//      menuAngle = actualAngle;
//      float[] midPoint = findMidpoint(menuPt1, menuPt2);
//      menuX = midPoint[0];
//      menuY = midPoint[1];
//      lastMenuPt1 = menuPt1;
//      lastMenuPt2 = menuPt2;
//    } // end !=null          
//    // log
//    int menuType = Classifier.blackSide;
//    if(menuFlip){
//      menuType = Classifier.whiteSide;
//    }
//    logMenu("M", lastMenuPt1, lastMenuPt2, int(menuAngle), menuType);
//  }
  
//  /*
//  Finds the two possible angles this could be at - they should be 180 degrees apart
//  Input: menuPt1 and menuPt2 are the two menu points
//  Output: an array containing both possibilities in RADIANS.
//  */
//  float[] getPossibleAngles(PointComplete firstMenuPt, PointComplete secondMenuPt){
//    // figure out which point is on the left and which is on right
//    PointComplete rightPt = secondMenuPt;
//    PointComplete leftPt = firstMenuPt;    
//    if(firstMenuPt.x > secondMenuPt.x){
//      rightPt = firstMenuPt;
//      leftPt = secondMenuPt;
//    }
    
//    float angleFromHoriz = getAngleFromHoriz(rightPt, leftPt); // always positive.
    
//    // if right point is higher, this is in quadrant 1 or 3
//    if(rightPt.y < leftPt.y){
//      float q1Angle = angleFromHoriz;
//      float q3Angle = PI + angleFromHoriz;
//      float[] result = {q1Angle, q3Angle};
//      return result;
//    }
//    // if left point is higher, this is in quadrant 2 or 4
//    else{
//      float q2Angle = PI - angleFromHoriz;
//      float q4Angle = TWO_PI - angleFromHoriz;
//      float[] result = {q2Angle, q4Angle};
//      return result;
//    }
//  }
  
//  /*
//  Given the two possible angles this could be at, find the one with the smaller differences from our current angle
//  Input: possibleAngles is an array of length 2 with both options
//  Output: the one with a smaller difference from the current angle in RADIANS
//  Note this checks difference in both rotation directions 
//  */
//  float findSmallerDiff(float[] possibleAngles){
//      float angleOneRad = possibleAngles[0];
//      float angleTwoRad = possibleAngles[1];
//      float angleOneDeg = degrees(angleOneRad);
//      float angleTwoDeg = degrees(angleTwoRad);
//      float currAngle = degrees(menuAngle);
      
//      float diffOne = min(((angleOneDeg - currAngle) + 360) % 360, ((currAngle - angleOneDeg) + 360) % 360);
//      float diffTwo = min(((angleTwoDeg - currAngle) + 360) % 360, ((currAngle - angleTwoDeg) + 360) % 360);
      
//      if(diffOne < diffTwo){
//        return angleOneRad;
//      } else {
//        return angleTwoRad;
//      }
//  }
  
//  /*--------- ROLL UP ----------*/
  
//  /*
//  Sets all params for menu to be on and sets isOn flag
//  Input: firstMenuPt and secondMenuPt are the menu points
//  */
//  void setMenuOn(PointComplete firstMenuPt, PointComplete secondMenuPt, int fromType){
//        rollFromType = fromType;
//        menuIds[0] = firstMenuPt.sessionId;
//        menuIds[1] = secondMenuPt.sessionId;
//        lastMenuPt1 = firstMenuPt;
//        lastMenuPt2 = secondMenuPt;
    
//        float angle = computeOrientationAngle(firstMenuPt, secondMenuPt, fromType);
//        menuAngle = angle;
        
//        float[] midPoint = findMidpoint(firstMenuPt, secondMenuPt);
//        menuX = midPoint[0];
//        menuY = midPoint[1];
        
//        int menuType = firstMenuPt.classification;
//        menuFlip = (menuType == Classifier.whiteSide); // white side true, black side false
        
//        //println(degrees(angle));
//        isOn = true;
//        i++; // DEBUG
//        //println("Roll up from ", classifier.classificationToString(fromType), " ", i); // DEBUG
//        markRolledUp();
//        logMenu("D", firstMenuPt, secondMenuPt, int(menuAngle), menuType);
//  }
    
//  /*
//  Finds the type rolled up from and checks that none of the points it sees were previously used in a roll up
//  Input: endClass is the classification type of the end point using Classifier types
//  Outputs: Outputs the type rolled up from. Outputs -1 if cannot find or if points were already used
//  Note: If points were used, at least one of the endpoint types will be marked
//        If this set was not, nothing added to the queue after (and including) the non endtypes will be marked
//        So this is sufficient
//  */
//  int findFromTypeAndCheckNoPrevRoll(int endClass){
//    int numElems = pointCollection.mainQueue.size();
//    ListIterator<PointComplete> it = ((LinkedList)pointCollection.mainQueue).listIterator(numElems);
//    while(it.hasPrevious()){
//      PointComplete currPt = it.previous();
//      int currType = currPt.classification;
//      boolean usedBefore = currPt.usedForRollUp; // has this point already been used
//      int eventType = currPt.eventType;
      
//      // check if these have been used
//      if(usedBefore){
//        return -1; // one has been used - everything left to check is older than it so we're done
//      }
//      // this one hasn't been used and it's a down point
//      if(currType != Classifier.unclassified && currType != Classifier.pending && currType != endClass && 
//         eventType == PointHolder.downEvent){
//        return currType;
//      } // end if
//    } // end while
//    return -1; // default return value
//  } // end findFromType
  
  

  
//  /*
//  Marks each element of pointCollection.mainQueue as rolled up so that it won't get detected twice
//  NOTE: It's fine to mark all of them. If we need to detect a new one, there will be new non-end points
//  and we'll never look past those
//  */
//  void markRolledUp(){
//    int numElems = pointCollection.mainQueue.size();
//    for(PointComplete pt : pointCollection.mainQueue){
//      pt.usedForRollUp = true;
//    }
//  }
  
//  /*
//  finds the midpoint of the two points
//  Input: firstMenuPt and secondMenuPt are the two points as PointCompletes
//  Output: their midpoint as [x,y]
//  */
//  float[] findMidpoint(PointComplete firstMenuPt, PointComplete secondMenuPt){
//    float x = (firstMenuPt.x + secondMenuPt.x)/2.0;
//    float y = (firstMenuPt.y + secondMenuPt.y)/2.0;
//    float[] result = {x,y};
//    return result;
//  }
  
//  /*
//  Computes the menu orientation based on the point rolled up from
//  Input: firstMenuPt and secondMenuPt are the points on the menu end point
//         fromPt is the point rolled up from
//  Output: The angle this is at in RADIANS
//  */
//  float computeOrientationAngle(PointComplete firstMenuPt, PointComplete secondMenuPt, int fromType){
    
//    // figure out which point is on the left and which is on right
//    PointComplete rightPt = secondMenuPt;
//    PointComplete leftPt = firstMenuPt;    
//    if(firstMenuPt.x > secondMenuPt.x){
//      rightPt = firstMenuPt;
//      leftPt = secondMenuPt;
//    }
    
//    float angleFromHoriz = getAngleFromHoriz(rightPt, leftPt); // always positive.
//    FromPtLocation fromLocation = getFromLocation(fromType);
    
//    // if right point is higher, this is in quadrant 1 or 3
//    if(rightPt.y < leftPt.y){
//      return doQ1OrQ3(leftPt, rightPt, angleFromHoriz, fromLocation);
//    }
//    // if left point is higher, this is in quadrant 2 or 4
//    else{
//      return doQ2OrQ4(leftPt, rightPt, angleFromHoriz, fromLocation);
//    }
//  }
  
//  /*
//  The two points make a line. findRotationAngle finds the angle that line makes with the horizontal
//  Input: firstMenuPt and secondMenuPt are the two points as PointComplete
//  Output: Their angle with the horizontal in RADIANS.
//  NOTE: The angle will always be positive. ie assumes quadrant 1
//  */
//  float getAngleFromHoriz(PointComplete firstMenuPt, PointComplete secondMenuPt){
//    float a = abs(firstMenuPt.x - secondMenuPt.x);
//    float h = dist(firstMenuPt.x, firstMenuPt.y, secondMenuPt.x, secondMenuPt.y);
//    float radTheta = acos(a/h);
//    return radTheta;
//  }
  
//  /*
//  Finds the FromPtLocation of fromType
//  Input: The Classifier classification representing the type of the points rolled up from
//  OutPut: The FromPtLocation of this type
//  */
//  FromPtLocation getFromLocation(int fromType){
//    // points on the right hand side when green is up
//    List<Integer> rightPointsArr = Arrays.asList(Classifier.greenYellowBlackCorner, Classifier.yellowBlackEdge, 
//                                Classifier.pinkYellowBlackCorner, Classifier.greenPurpleWhiteCorner, Classifier.purpleWhiteEdge,
//                                Classifier.pinkPurpleWhiteCorner);
//    Set<Integer> rightPoints = new HashSet<Integer>(rightPointsArr);
    
//    // points on the left hand side when green is up
//    List<Integer> leftPointsArr = Arrays.asList(Classifier.greenYellowWhiteCorner, Classifier.yellowWhiteEdge, 
//                                Classifier.pinkYellowWhiteCorner, Classifier.greenPurpleBlackCorner, Classifier.purpleBlackEdge,
//                                Classifier.pinkPurpleBlackCorner);
//    Set<Integer> leftPoints = new HashSet<Integer>(leftPointsArr);
  
//    // points above the center when green is on top
//    List<Integer> topPointsArr = Arrays.asList(Classifier.greenBlackEdge, Classifier.greenWhiteEdge);
//    Set<Integer> topPoints = new HashSet<Integer>(topPointsArr); 
 
//    // points below the center when green is on top
//    List<Integer> bottomPointsArr = Arrays.asList(Classifier.pinkWhiteEdge, Classifier.pinkBlackEdge);
//    Set<Integer> bottomPoints = new HashSet<Integer>(bottomPointsArr);  
    
//    if(rightPoints.contains(fromType)){
//      return FromPtLocation.RIGHT;
//    } else if(leftPoints.contains(fromType)){
//      return FromPtLocation.LEFT;
//    } else if(topPoints.contains(fromType)){
//      return FromPtLocation.TOP;
//    } else{
//      return FromPtLocation.BOTTOM;
//    }
//  }
  
//  /*
//  Given that Conte is either in Q1 or Q3, determine which one it's in and compute the angle
//  Input: leftPt and rightPt are the two points on the end point
//         angleFromHoriz is the angle (from 0 to 90) conte is at from the horizontal IN RADIANS
//         fromLocation is type of point that fromType is (ie LEFT, RIGHT, TOP, BOTTOM)
//  Output: Angle in RADIANS
//  */
//  float doQ1OrQ3(PointComplete leftPt, PointComplete rightPt, float angleFromHoriz, FromPtLocation fromLocation){
//    int correctedYaw = (leftPt.yaw - 100 + 360) % 360;
//    float Q1Angle = angleFromHoriz;
//    float Q3Angle = PI + angleFromHoriz;
    
//    // diff is distance from calculated yaw to option in that quadrant. Include both because don't know if it's closer
//    // to calculate in the clockwise or counter clockwise direction.
//    float diffQ1 = min(((degrees(Q1Angle) - correctedYaw) + 360) % 360, ((correctedYaw - degrees(Q1Angle)) + 360) % 360);
//    float diffQ3 = min(((degrees(Q3Angle) - correctedYaw) + 360) % 360, ((correctedYaw - degrees(Q3Angle)) + 360) % 360);
//    println("diffQ1 ", diffQ1);
//    println("diffQ3 ", diffQ3);
//    if(diffQ1< diffQ3){
//      println("Q1");
//      println(degrees(Q1Angle));
//      println(correctedYaw);
//      return Q1Angle;
//    } else {
//      println("Q3");
//      println(degrees(Q3Angle));
//      println(correctedYaw);
//      return Q3Angle;
//    }
//  }
    
//    // split q1 and q3 right down the middle of q2q4
////    if(fixedYaw < (90 + 45) || fixedYaw > (360 - 45)){
////      angleOffset = 0;
////    } else {
////      angleOffset = PI;
////    }
    
////    if(angleFromHoriz < QUARTER_PI){
////      
////      // true iff fromLocation matches the location the roll was made from
////      boolean match = matchQ1Below45(leftPt, rightPt, fromLocation);
////
////      // match is always associated with what would be correct in Q1      
////      if(match){
////        angleOffset = 0;
////      } else {
////        angleOffset = PI;
////      }
////    }
////
////    else{
////      // true iff right on top, left on bottom, bottom from right, top from left
////      boolean match = matchQ1Above45(leftPt, rightPt, fromLocation);
////      
////      // match is always associated with what would be correct in Q1
////      if(match){
////        angleOffset = 0;
////      } else {
////        angleOffset = PI;
////      }
////    }

  
//  /*
//  Given that Conte is either in Q1 or Q3, determine which one it's in and compute the angle
//  Input: leftPt and rightPt are the two points on the end point
//         angleFromHoriz is the angle (from 0 to 90) conte is at from the horizontal IN RADIANS
//         fromLocation is type of point that fromType is (ie LEFT, RIGHT, TOP, BOTTOM)
//  Output: Angle in RADIANS
//  */
//  float doQ2OrQ4(PointComplete leftPt, PointComplete rightPt, float angleFromHoriz, FromPtLocation fromLocation){
//    int correctedYaw = (leftPt.yaw - 100 + 360) % 360;
//    float Q2Angle = PI - angleFromHoriz;
//    float Q4Angle = TWO_PI - angleFromHoriz;
    
//    // diff is distance from calculated yaw to option in that quadrant. Include both because don't know if it's closer
//    // to calculate in the clockwise or counter clockwise direction.
//    float diffQ2 = min(((degrees(Q2Angle) - correctedYaw) + 360) % 360, ((correctedYaw - degrees(Q2Angle)) + 360) % 360);
//    float diffQ4 = min(((degrees(Q4Angle) - correctedYaw) + 360) % 360, ((correctedYaw - degrees(Q4Angle)) + 360) % 360);
//    println("diffQ2 ", diffQ2);
//    println("diffQ4 ", diffQ4);
//    if(diffQ2< diffQ4){
//      println("Q2");
//      println(degrees(Q2Angle));
//      println(correctedYaw);
//      return Q2Angle;
//    } else {
//      println("Q4");
//      println(degrees(Q4Angle));
//      println(correctedYaw);
//      return Q4Angle;
//    }
//  }
    
    
////    if(45 < fixedYaw  && fixedYaw < (180 + 45)){
////      angleOffset = PI;
////    } else {
////      angleOffset = TWO_PI;
////    }
////    if(angleFromHoriz < QUARTER_PI){
////      // true iff fromLocation matches the location the roll was made from
////      boolean match = matchQ1Below45(leftPt, rightPt, fromLocation);
////
////      // match is always associated with what would be correct in Q1      
////      if(match){
////        angleOffset = TWO_PI;
////      } else {
////        angleOffset = PI;
////      }
////    }
////
////    else{
////      // true iff right on top, left on bottom, bottom from right, top from left
////      boolean match = matchQ1Above45(leftPt, rightPt, fromLocation);
////      
////      // match is always associated with what would be correct in Q1
////      if(match){
////        angleOffset = PI;
////      } else {
////        angleOffset = TWO_PI;
////      }
////    }
  
//  /*
//  returns true iff the configuration of the fromLocation and where the roll came from matches what it would be in Q1
//  This is for when the angle is less than 45 degs so we're looking for right on right, top on top etc.
//  Input: leftPt and rightPt are the left and right menu points
//         fromLocation is the location the roll would have come from if the rotation was 0 degrees
//  Returns: true if the physical location the rotation came from matches what it would be in Q1
//  */
//  boolean matchQ1Below45(PointComplete leftPt, PointComplete rightPt, FromPtLocation fromLocation){
//    FromPtLocation rollLocation; // where in global space did the roll come from
//    if(fromLocation == FromPtLocation.RIGHT || fromLocation == FromPtLocation.LEFT){
//      // was the first point to touch down on the left or right
//      rollLocation = determineFirstLeftRight(leftPt, rightPt);
//    } else {
//      // did the roll come from the top or bottom
//      rollLocation = determineRollTopBottom(leftPt, rightPt);
//    }
//    return (rollLocation == fromLocation);
//  }
  
//  /*
//  returns true iff the configuration of the fromLocation and where the roll came from matches what it would be in Q1
//  This is for when the angle is more than 45 degs so we're looking for right on btom, top on left etc.
//  Input: leftPt and rightPt are the left and right menu points
//         fromLocation is the location the roll would have come from if the rotation was 0 degrees
//  Returns: true if the physical location the rotation came from matches what it would be in Q1
//  */
//  boolean matchQ1Above45(PointComplete leftPt, PointComplete rightPt, FromPtLocation fromLocation){
//    FromPtLocation rollLocation;
//    if(fromLocation == FromPtLocation.RIGHT || fromLocation == FromPtLocation.LEFT){
//      // was the first point to touch down on the top or bottom
//      rollLocation = determineFirstTopBottom(leftPt, rightPt);
//    } else {
//      // did the roll come from the left or right
//      rollLocation = determineRollLeftRight(leftPt, rightPt);
//    }
    
//    boolean result = true;
//    switch(fromLocation){
//      case RIGHT:
//        result = (rollLocation == FromPtLocation.TOP);
//        break;
//      case LEFT:
//        result = (rollLocation == FromPtLocation.BOTTOM);
//        break;
//      case TOP:
//        result = (rollLocation == FromPtLocation.LEFT);
//        break;
//      case BOTTOM:
//        result = (rollLocation == FromPtLocation.RIGHT);
//        break;
//    }
//    return result;
//  }
  
  
//  /*
//  Returns LEFT if leftPt is closer to the roll point and RIGHT if rightPt is closer to the roll point
//  Input: leftPt and rightPt are the two points on the menu end point
//  Output: The FromPtLocation corresponding to which point is closer to the roll point
//  */
//  FromPtLocation determineFirstLeftRight(PointComplete leftPt, PointComplete rightPt){
//    PointComplete rollPt = stateManager.getCurrPt();
//    float leftDist = dist(rollPt.x, rollPt.y, leftPt.x, leftPt.y);
//    float rightDist = dist(rollPt.x, rollPt.y, rightPt.x, rightPt.y);
    
//    if(leftDist < rightDist){
//      return FromPtLocation.LEFT;
//    } else {
//      return FromPtLocation.RIGHT;
//    }
//  }
  
//  /*
//  Returns TOP if the points started above their current location, BOTTOM otherwise
//  Input: leftPt and rightPt are the two points on the menu end point
//  Output: The FromPtLocation corresponding to where these points touched down in relation to their current location
//  */
//  FromPtLocation determineRollTopBottom(PointComplete leftPt, PointComplete rightPt){
//    // pick the point that's closest to where it started from
//    //PointComplete testPt = closestToDown(leftPt, rightPt);
//    //PointComplete testPt = furthestFromDown(leftPt, rightPt);
//    PointComplete testPt = closestToRoll(leftPt, rightPt);
//    PointComplete rollPt = stateManager.getCurrPt();
    
//    // if downY is smaller, the roll came from above (remember we're in screen coordinates)
//    if(rollPt.yDown < testPt.y){
//      return FromPtLocation.TOP;
//    } else {
//      return FromPtLocation.BOTTOM;
//    }
//  }

//  /*
//  Returns TOP if the top point is closer to roll point, BOTTOM if the bottom point is closer to roll pint
//  Input: leftPt and rightPt are the two points on the menu end point
//  Output: The FromPtLocation corresponding to which point is closer to the roll point
//  */
//  FromPtLocation determineFirstTopBottom(PointComplete leftPt, PointComplete rightPt){    
//    // figure out which point is the top point
//    PointComplete topPt = rightPt;
//    PointComplete bottomPt = leftPt;
//    if(leftPt.y < rightPt.y){
//      topPt = leftPt;
//      bottomPt = rightPt;
//    } else {
//    }
    
//    // figure out which point is closer
//    PointComplete rollPt = stateManager.getCurrPt();
//    float topDist = dist(rollPt.x, rollPt.y, topPt.x, topPt.y);
//    float bottomDist = dist(rollPt.x, rollPt.y, bottomPt.x, bottomPt.y);
    
//    if(topDist < bottomDist){
//      return FromPtLocation.TOP;
//    } else {
//      return FromPtLocation.BOTTOM;
//    }
//  }
  
//  /*
//  Returns LEFT if the points started to the left their current location, BOTTOM otherwise
//  Input: leftPt and rightPt are the two points on the menu end point
//  Output: The FromPtLocation corresponding to where these points touched down in relation to their current location
//  */
//  FromPtLocation determineRollLeftRight(PointComplete leftPt, PointComplete rightPt){
//    // pick the point that's closest to where it started from
//    //PointComplete testPt = closestToDown(leftPt, rightPt);
//    // PointComplete testPt = furthestFromDown(leftPt, rightPt);
//    PointComplete testPt = closestToRoll(leftPt, rightPt);
//    PointComplete rollPt = stateManager.getCurrPt();
    
//    if(rollPt.xDown < testPt.x){
//      return FromPtLocation.LEFT;
//    } else {
//      return FromPtLocation.RIGHT;
//    }
//  }
  
//  /*
//  Returns the point whose current location is closest to the last seen location of the roll point
//  Input: leftPt and rightPt are the two PointCompletes we're comparing
//  Output: The input point that's closest to the roll point
//  */
//  PointComplete closestToRoll(PointComplete leftPt, PointComplete rightPt){
//    PointComplete rollPt = stateManager.getCurrPt();
//    float leftDist = dist(leftPt.x, leftPt.y, rollPt.xDown, rollPt.yDown);
//    float rightDist = dist(rightPt.x, rightPt.y, rollPt.xDown, rollPt.yDown);
    
//    if(leftDist < rightDist){
//      return leftPt;
//    } else {
//      return rightPt;
//    }
//  }
  
//  /*
//  Returns the point whose current location is farthest where it touched down
//  Input: leftPt and rightPt are the two PointCompletes we're comparing
//  Output: The input point that touched down farthest away
//  */
//  PointComplete closestToDown(PointComplete leftPt, PointComplete rightPt){
//    float rightDistFromDown = dist(rightPt.x, rightPt.y, rightPt.xDown, rightPt.yDown);
//    float leftDistFromDown = dist(leftPt.x, leftPt.y, leftPt.xDown, leftPt.yDown);
//    if(rightDistFromDown < leftDistFromDown){
//      return rightPt;
//    } else {
//      return leftPt;
//    }
//  }
  
//    /*
//  Returns the point whose current location is furthest from where it touched down
//  Input: leftPt and rightPt are the two PointCompletes we're comparing
//  Output: The input point that touched down first
//  */
//  PointComplete furthestFromDown(PointComplete leftPt, PointComplete rightPt){
//    float rightDistFromDown = dist(rightPt.x, rightPt.y, rightPt.xDown, rightPt.yDown);
//    float leftDistFromDown = dist(leftPt.x, leftPt.y, leftPt.xDown, leftPt.yDown);
//    if(rightDistFromDown > leftDistFromDown){
//      return rightPt;
//    } else {
//      return leftPt;
//    }
//  }
  
//  /*--------- LOGGING ------------*/
  
//  /*
//  Logs this menu action
//  Input: eventType: U/M/D for Up/Move/Down
//         firstMenuPt and secondMenuPt are the menu contact points
//         degs is the rotation of the menu on screen
//         menuType is the int representing either the black side or the white side
//  */
//  void logMenu(String eventType, PointComplete firstMenuPt, PointComplete secondMenuPt, int degs, int menuType){
//    Contact menuContact = classToContact.get(menuType);
//    logger.doLog(new MenuTechniqueEvent(eventType, firstMenuPt.sessionId, int(firstMenuPt.x), int(firstMenuPt.y), 
//                                        secondMenuPt.sessionId, int(secondMenuPt.x), int(secondMenuPt.y), 
//                                        degs, menuContact));
//  }
  
//} // END CLASS