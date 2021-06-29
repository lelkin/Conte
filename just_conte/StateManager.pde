/*
Manages Conte's state
StateManagerBase is base class
StateManagerRoll is the old menu roll - Menu type must be MenuRoll
StateManager3D is the new one - Menu type must be Menu3D
*/

/*
IMPORTANT NOTE: While conte is down currPt.classification is used as the classification even though it might be different
from the most recent classification. This is done so that it doesn't jump
*/

// global StateManager object.
//StateManagerRoll stateManager;
StateManager3D stateManager;

/*---------- ----------*/
class StateManagerBase{
  // fields
  StateType currStateType;
  long timeStamp; // time that we made this classification
  PointComplete currPt; // the point with that classification. Note for menu mode this will be the point we rolled from
  long downTime = 0; // time down was detected
  long downThresh = 20; // time after down that it's valid to detect an up
  
  Queue<PointComplete> updateQueue; // PointCollection pushes new points to here for move, down, and up events
  
  // accel values used in currPt - need to be separate since will hardcode for menus 
  int accelX = 0;
  int accelY = 0;
  int accelZ = 0;

  void update(){}
  
  StateManagerBase(){
    currStateType = StateType.AIR;
    timeStamp = 0;
    currPt = null;
    
    updateQueue = new LinkedList<PointComplete>(); // init queue
  }
  
  /*---------- TRANSITIONS ----------*/
  
  /*
  Does up to selected transition
  Input: downPt is new down point that is causing the transition
  */
  void upToSelected(PointComplete downPt){
    currStateType = StateType.SELECTED;
    timeStamp = millis();
    currPt = downPt;
    accelX = currPt.accelX;
    accelY = currPt.accelY;
    accelZ = currPt.accelZ;
    downTime = millis();
    // firsto one is down, everything else is a move
    sendDownEvent();
    sendMoveEvent();
  }
  
  /*
  Valid transitions from SELECTED:
  SELECTED -> UP // have to lift after selection
  Checks if we've transitioned from SELECTED and updates state accordingly
  */
  void checkTransitionFromSelected(){
    // change state to UP
    if(pointCollection.noDownPts()){
      //classifier.activate();
      currStateType = StateType.AIR;
      timeStamp = millis();
      sendUpEvent();
      currPt = null;
    } else {
      sendMoveEvent(); // it's still selected
    }
  }
  
  /*
  Sends down event to app. Sends with our new known classification but the oldest point on the updateQueue
  */
  void sendDownEvent(){      
    // pull oldest elem off the updateQueue
    PointComplete event = updateQueue.poll();
    if(event != null){
      oscSender.down(currPt.classification, event);
      //println("down ", classifier.classificationToString(currPt.classification), " ", currPt.yaw);
    } // event != null
  }
  
  /*
  Sends entire updateQueue to app as move event. app already knows the classification so doesn't need to send that
  */
  void sendMoveEvent(){      
    PointComplete event = updateQueue.poll();
    while(event != null){
      oscSender.move(currPt.classification, event);
      event = updateQueue.poll();
    } // end while
  }
  
  /*
  Sends up event to app. app already knows the classification so doesn't need to send that
  This is called on SELECTED -> UP transitions and on WAITINGFORROLL -> UP transitions
  There might be multiple things in the updateQueue - send all but the last one as move events and just send the last as up.
  */
  void sendUpEvent(){
    PointComplete event = updateQueue.poll();
    while(event != null){
      PointComplete nextEvent = updateQueue.poll();
      
      // next is null means event is last one
      if(nextEvent == null){
        oscSender.up(currPt.classification, event);
      }
      // next isn't null means event is not last one 
      else {
        oscSender.move(currPt.classification, event);
      }
      event = nextEvent;
    } // while
  } // sendUpEvent
  
    /*---------- UPDATE QUEUE ----------*/
  
  /*
  Allows other parts of the program to add events to updateQueue.
  */
  void addToUpdateQueue(PointComplete currPt){
    updateQueue.add(currPt);
  } 
  
  /*
  Clears updateQueue without sending any events
  Useful when we want to throw everything out (ie at the start of a connection or after we see a menu)
  */
  void clearUpdateQueue(){
    while(!updateQueue.isEmpty()){
      updateQueue.poll();
    }
  }
  
  /*---------- DRAW state on screen ----------*/
  
  /*
  Draws text at the top of the screen containing the current state and classification if there is a relevant one
  */
  void drawState(){
    String stateStr = "";
    stateStr += currStateType;
    
    if(currPt != null){
      String classificationStr = classifier.classificationToString(currPt.classification);
      stateStr += " ";
      stateStr += classificationStr;
    }
    
    //fill(255,255,255);
    fill(0); 
    textAlign(CENTER, CENTER);
    textSize(32);
    text(stateStr, width/2, 50);
  }
  
  /*---------- GET INFO ----------*/
  
  /*
  returns current point
  */
  PointComplete getCurrPt(){
    return currPt;
  }
  
  /*
  Returns accelX, accleY, accelZ as an array
  */
  public int[] getAccelOnDown(){
    int[] result = {accelX, accelY, accelZ};
    return result;
  }
  
  /*
  Returns true if we're in a state where it's possible to transition to up
  (ie currPt != null) and the time since down is greater than downThresh
  */
  public boolean upPossible(){
    long currTime = millis();
    return (((currTime - downTime) > downThresh) && (currPt != null));
  }

}

/*---------- STATE MANAGER NOT ROLL ----------*/

class StateManager3D extends StateManagerBase{
  StateManager3D(){
  }
  
  /*
  called every frame
  */
  void update(){
    switch(currStateType){
      case AIR:
        checkTransitionFromUp();
        break;
      case SELECTED:
        checkTransitionFromSelected();
        break;
    }
  }
  
  /*
  UP->SELECTED
  */
  void checkTransitionFromUp(){
    PointComplete downPt = pointCollection.getNewDownPt(timeStamp); // all time stamp returns null if can't find one, will not return unclassified or pending point
    if(downPt != null){
      super.upToSelected(downPt);
      //classifier.deactivate();
    } else { // still in air, send air event
      oscSender.air();
    }
  }
  
}

///*---------- STATE MANAGER ROLL ----------*/
// Still good roll code but comment out since parts only exist if using MenuRoll

//class StateManagerRoll extends StateManagerBase{  
//  // changed to 0 to disable menu
//  final long timerLength = 1000; // number of millis we wait when a user touches down with a point for them to roll up
  
//  StateManagerRoll(){
//  }
  
//  /*
//  Updates Conte's state based on everything we saw this frame
//  */
//  void update(){
//    switch(currStateType){      
//      case UP:
//        checkTransitionFromUp();
//        break;
//      case MENU:
//        checkTransitionFromMenu();
//        break;
//      case SELECTED:
//        checkTransitionFromSelected();
//        break;
//      case WAITINGFORROLL:
//        checkTransitionWaitingForRoll();
//        break;
//    }
//  }
  
//  /* Valid transitions from UP:
//  UP -> WAITINGFORROLL // if valid roll point is down
//  UP -> SELECTED // if non-roll point down
//  Checks if we've transitioned from UP and updates state accordingly
//  */
//  void checkTransitionFromUp(){
//    PointComplete downPt = pointCollection.getNewDownPt(timeStamp); // all time stamp returns null if can't find one, will not return unclassified or pending point
//    if(downPt != null){
//      if(isValidRollType(downPt)){
//        currStateType = StateType.WAITINGFORROLL;
//        startTimer();
//        currPt = downPt;
//        accelX = currPt.accelX;
//        accelY = currPt.accelY;
//        accelZ = currPt.accelZ;
//        downTime = millis();
//        // first one is down, everything else is a move  
//        sendDownEvent();
//        sendMoveEvent();        
//      } 
//      // this includes black and white end - can decide not to draw them on other end
//      else {
//        super.upToSelected(downPt);
//      } // else
//    } // downPt != null
//  }
  
//  /*
//  Starts the timer for waiting for roll
//  */
//  void startTimer(){
//    timeStamp = millis();
//  }
  
//  /*
//  Checks if pt is a point we can roll to the menu from
//  Input: pt is the point we're interested int
//  Output: true if can roll to menu from it, false otherwise
//  */
//  boolean isValidRollType(PointComplete pt){
//    boolean validWhiteType = validFromType(pt.classification, Classifier.whiteSide);
//    boolean validBlackType = validFromType(pt.classification, Classifier.blackSide);
//    return (validWhiteType || validBlackType);
//  }
  
//  /*
//  Valid transitions from MENU:
//  MENU -> UP // have to lift after menu
//  Checks if we've transitioned from MENU and updates state accordingly
//  For state purposes, it's not enough to see that the menu is off, there must also be NO points on the screen
//  Menu now also gets turned off here
//  */
//  void checkTransitionFromMenu(){
//    if(pointCollection.noDownPts()){
//      menu.setInactive();
//      currStateType = StateType.UP;
//      currPt = null;
//      timeStamp = millis();
//      clearUpdateQueue(); 
//    }
//  }
  
//  /*
//  Valid transitions from WAITINGFORROLL:
//  WAITINGFORROLL -> MENU // roll to menu point
//  WAITINGFORROLL -> SELECTED // wait long enough that we're selected
//  WAITINGFORROLL -> UP // lift up
//  Checks if we've transitioned from WAITINGFORROLL and updates state accordingly
//  If menu is on, turn on menu. If no points down, say it's an up. If there are still points down and the timer is done,
//  say it's selected. If none of the above, we're still waiting
//  */
//  void checkTransitionWaitingForRoll(){
//    // change to MENU
//    checkRollUp(); // turns menu on and can't really move that
//    if(menu.isOn){
//      currStateType = StateType.MENU; // menu gets updated first
//      updateMenuAccel();
//      timeStamp = millis();
//      sendCancelEvent();
//    } 
//    // change to UP
//    else if (pointCollection.noDownPts()){
//      currStateType = StateType.UP;
//      currPt = null;
//      timeStamp = millis();
//      sendUpEvent();
//    } 
//    // change to SELECTED
//    else if(timerIsDone()){
//      currStateType = StateType.SELECTED;
//      timeStamp = millis();
//      sendMoveEvent();
//    } else {
//      sendMoveEvent(); // we're just waiting
//    }
//  }
  
//  /*
//  Updates accelX, accelY, accelZ to the precomputed values for the currently used menu point
//  Since menu is rolled to, won't get correct verticle accel values if use the ones we see from the menu point
//  Only called when menu is on
//  */
//  void updateMenuAccel(){
//    // white
//    int wX = 0;
//    int wY = -260;
//    int wZ = -10;
    
//    // black
//    int bX = 0;
//    int bY = 254;
//    int bZ = -3;
    
//    // true for white, false for black
//    if(menu.menuFlip){
//      accelX = wX;
//      accelY = wY;
//      accelZ = wZ;
//    } else {
//      accelX = bX;
//      accelY = bY;
//      accelZ = bZ;
//    }
//  }
  
//  /*
//  Checks the waiting to roll timer
//  Returns: true if the timer is done, false otherwise
//  */
//  boolean timerIsDone(){
//    long currTime = millis();
//    long timeSinceStarted = currTime - timeStamp;
//    return(timeSinceStarted >= timerLength);
//  }
  
  
//  /*---------- SEND EVENTS ----------*/
//  /*
//  Sends cancel event to app.
//  Sends all but last event to app as move event, then sends last as cancel event
//  */
//  void sendCancelEvent(){
//    PointComplete event = updateQueue.poll();
//    // do it this way if at least one event on updateQueue
//    if(event!=null){
//      while(event != null){
//        PointComplete nextEvent = updateQueue.poll();
        
//        // next null means event is last one
//        if(nextEvent == null){
//          oscSender.cancel(event.path, event.sessionId);
//        } else {
//          oscSender.move(event.path, event.sessionId, event.eventType);
//        }
//        event = nextEvent;
//      } // end while
//    }// end event != null
//    // I don't think this will ever happen but just in case
//    // if no event on updateQueue just send empty cancel - will log cancel at 0,0
//    // will have to recover last known location from previous move events in logs
//    else {
//      oscSender.cancel();
//    }
//  }
  
//  /*----------- GET INFO -----------*/
  
//  /*
//  Called by menu when checking for roll. Retunrs the classification of currPt - ie the type of point we rolled up from
//  Output: Classifier classification of currPt
//  */
//  private int getRollType(){
//    return currPt.classification;
//  }
  
//  /*---------- MENU STATE ----------*/
//  /*
//  Checks if a roll up occured
//  If it did, automatically makes changes to menu object
//  */
//   void checkRollUp(){
//     PointComplete mostRecent = pointCollection.getMostRecent();
//     if(mostRecent != null){
//       if(mostRecent.classification == Classifier.blackSide || mostRecent.classification == Classifier.whiteSide){
//         checkRollTo(mostRecent);
//       }
//     }
//   }
   
//  /*
//  Given that mostRecent is the most recently seen point, checks if this is a roll to that point
//  Input: PointComplete mostRecent - newest point seen by SMT
//  */
//  void checkRollTo(PointComplete firstMenuPt){
    
//    // find type of point rolled up from - returns type rolled from
//    int fromType = getRollType();
//    // int fromType = findFromTypeAndCheckNoPrevRoll(firstMenuPt.classification); // returns -1 if not found which will not be valid
    
//    if(validFromType(fromType, firstMenuPt.classification)){ // checks if the fromType is a neighbouring type of the end point

//      // firstMenuPt is one point on the menu end, find the other one
//      PointComplete secondMenuPt = findTwoMenuPts(firstMenuPt);
      
//      // Any time we detect both points on a black or white end, and we found a valid from type, it's a roll up
//      // now we just need to termine the orientation
//      if(secondMenuPt != null){
//        menu.setMenuOn(firstMenuPt, secondMenuPt, fromType);
//      }
//    }
//  }
  
//  /*
//  Checks if fromType is a valid type to roll up to endType
//  Input: fromType is the Classifier classificaton rolled from, endType is the one rolled to
//  Output: true if valid, false otherwise
//  */
//  boolean validFromType(int fromType, int endType){
//    // points adjacent to black side - ie points to roll to black side from
//    List<Integer> blackFromPtsArr = Arrays.asList(Classifier.greenPurpleBlackCorner, Classifier.greenBlackEdge, 
//                          Classifier.greenYellowBlackCorner, Classifier.yellowBlackEdge, Classifier.pinkYellowBlackCorner, 
//                          Classifier.pinkBlackEdge, Classifier.pinkPurpleBlackCorner, Classifier.purpleBlackEdge); 
//    Set<Integer> blackFromPts = new HashSet<Integer>(blackFromPtsArr);
     
//     // points adjacent to white side - ie points to roll to white side from   
//    List<Integer> whiteFromPtsArr = Arrays.asList(Classifier.greenPurpleWhiteCorner, Classifier.greenWhiteEdge, 
//                          Classifier.greenYellowWhiteCorner, Classifier.yellowWhiteEdge, Classifier.pinkYellowWhiteCorner, 
//                          Classifier.pinkWhiteEdge, Classifier.pinkPurpleWhiteCorner, Classifier.purpleWhiteEdge);
//    Set<Integer> whiteFromPts = new HashSet<Integer>(whiteFromPtsArr);
    
//    if(endType == Classifier.blackSide){
//      return blackFromPts.contains(fromType);
//    } else {
//      return whiteFromPts.contains(fromType);
//    }
//  } // end validFromTypes
  
//  /*
//  Given one point on the menu end, finds the other
//  Input: pt is one point on the menu end
//  Output: PointComplete far enough away from pt to be the other menu end
//          null if cannot find
//  */
//  PointComplete findTwoMenuPts(PointComplete pt){
//    int endDistThresh = 120; // min required distance
//    int numElems = pointCollection.mainQueue.size();
//    ListIterator<PointComplete> it = ((LinkedList)pointCollection.mainQueue).listIterator(numElems);
//    PointComplete secondMenuPt = null; // want to return null if can't find another one
    
//    while(it.hasPrevious()){
//      PointComplete currPt = it.previous();
      
//      // don't want to go too far back. if we're on a different classification, we didn't find it
//      if(currPt.classification != pt.classification){
//        break;
//      } else {
//        float d = dist(currPt.x, currPt.y, pt.x, pt.y);
//          if(d >= endDistThresh){
//            secondMenuPt = currPt;
//            break;
//          }
//      }
//    }
//    return secondMenuPt;
//  }
//}