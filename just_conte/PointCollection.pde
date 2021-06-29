import java.util.*;

PointCollection pointCollection;

/*
All known information about points
*/
class PointCollection{
  // tracks all points that are in contact with surface.
  // Used to get information that is needed for main queue
  final int maxNumPoints = 50; // max number of points allowed in mainQueue
  int lastDownClass = -1; // last down classification seen used for drawClassText
  HashMap<Long, PointTracker> trackerMap; // key is session id
  Queue<PointComplete> mainQueue; // holds point info for last numPoints points.
  Queue<PointComplete> upQueue; // holds PointCompletes for upEvents that we're not yet sure were really upEvents
  long upTimeThresh = 300; // longest number of millis we wait after losing a point before saying it was definitely an up event.
  
  PointCollection(){    
    trackerMap = new HashMap<Long, PointTracker>();
    mainQueue = new LinkedList<PointComplete>();
    upQueue = new LinkedList<PointComplete>();
  }
  
  /********* UPDATE **********/
  
  /*
  Takes all PointHolders off of conte.pointHolderQueue
  Adds new elem to trackerMap if PointHolder is a down event
  Looks up PointTracker in trackerMap.
  Creates new PontComplete using PointHolder and PointTracker
  Adds this PointComplete to mainQueue 
  */
  void update(){
    updateUps(); // remove old up events
    
    PointHolder currHolder = conte.pointHolderQueue.poll();
    while(currHolder!=null){
      // log currHolder
      currHolder.logEvent();
      // get new PointComplete object and update trackerMap
      PointComplete currComplete = getNewComplete(currHolder); // returns null on upEvent
      if(currComplete != null){
        updateMainQueue(currComplete); // add currComplete to mainQueue
      }
      
      // get next elem
      currHolder = conte.pointHolderQueue.poll();
    }

  }
  
  
  /*
  Iterates checks if there's been an unprocessing upEvent and adds all PointCompletes in upList
  to mainQueue if there was. Returns true if found an up
  Output: true if found an up, false otherwise
  */
  void updateUps(){
    long lastUpTime = accelerometer.hasUnprocessedUp(); // We saw an up event, everything in upQueue was actually an up
    long currTime = millis();
    // loop through upQueue from front to find up events older than lastUpTime
    while(!upQueue.isEmpty()){
      PointComplete currComplete = upQueue.element();
      if((currComplete.timeStamp <= lastUpTime) || (currTime - currComplete.timeStamp >= upTimeThresh)){
        upQueue.remove();
        updateMainQueue(currComplete);
        //MOVED TO STATEMANAGER
        //menu.setInactive(); // need to tell menu to deactivate since we saw an up
      } 
      // if this point isn't "too old", neither are any points that follow it.
      else{
        break;
      } // end else
    } // end while
  }
  
  /*
  Adds new point to mainQueue
  Input: currComplete is point to add
  Note: Will remove old items from mainQueue if this makes it too large
  */
  void updateMainQueue(PointComplete currComplete){
    if(mainQueue.size() >= maxNumPoints){
      mainQueue.remove();
    }
    mainQueue.add(currComplete);
    stateManager.addToUpdateQueue(currComplete);
  }
  
  /*
  Creates PointComplete to add to mainQueue, adds to or updates trackerMap and adds to upQueue
  Input: currHolder is the PointHolder containing the new event info
  Returns: The PoinComplete to add to mainQueue or null in the case of an up event
  */
  PointComplete getNewComplete(PointHolder currHolder){
    int currEventType = currHolder.eventType;
    long currId = currHolder.sessionId;
    PointComplete currComplete = null;
    
    // down
    if(currEventType == PointHolder.downEvent){
      PointComplete mergedPoint = mergeNewPoint(currHolder); // should return null if no point to merge
      // was not merged, this is actually a new point
      if(mergedPoint == null){
        PointTracker currTracker = addPointTracker(currHolder);
        currComplete = new PointComplete(currHolder, currTracker);
      } 
      // We did merge this with an old point
      else {
        currComplete = mergedPoint;
      }
    }
    // moved
    else if(currEventType == PointHolder.movedEvent){
      PointTracker currTracker = trackerMap.get(currId);
      currComplete = new PointComplete(currHolder, currTracker);
      currTracker.updateLastNumPoints(currHolder);
    }
    // up
    else if(currEventType == PointHolder.upEvent){
      PointTracker currTracker = trackerMap.get(currId);
      PointComplete upComplete = new PointComplete(currHolder, currTracker);
      trackerMap.remove(currId);
      upQueue.add(upComplete); // We don't add the point to mainQueue, we add it upQueue instead
    }
    return currComplete;
  }
  
  /*
  Checks everything in upQueue to see if currHolder can be merged with any of them
  Merge Strategy: If they're less than 100 px from each other merge
                  If there's only one up point, delete it no matter what but merge it if it's within 200 px of the new point
                  Should probably change this to if on a single point classification (ie corner)
  Input: currHolder is the PointHolder 
  Returns: PointComplete to add to mainQueue
           null if not mergeable
  Note: Adds a new PointTracker to trackerMap if the point is merged
  */
  PointComplete mergeNewPoint(PointHolder currHolder){
    PointComplete currStatePt = stateManager.currPt;
    if(currStatePt == null){
      return null;
    }
    int currClass = currStatePt.classification;
    
    // if the point is a single contact point, merge within 300 px
    if(classifier.drawPoints.contains(currClass)){
      int drawPointMergeThresh = 300;
      PointComplete result = mergeBasedOnDist(currHolder, drawPointMergeThresh);
      return result;
    }
    
    // this isn't a draw point, only merge within 100 px
    else{
      int nonDrawPointMergeThresh = 100;
      PointComplete result = mergeBasedOnDist(currHolder, nonDrawPointMergeThresh);
      return result;
    }
  }
  
  /*
  Merges currHolder to a point in upQueue if their distance is < thresh
  Input: currHolder is the new point to merge.
         thresh is the max distance between currHolder and an up point
  Output: The resulting PointComplete from merging them
          Outputs null if didn't find an up point close enough
  */
  PointComplete mergeBasedOnDist(PointHolder currHolder, int thresh) {
    ListIterator<PointComplete> it = ((LinkedList)upQueue).listIterator(0);
    while(it.hasNext()){
      PointComplete upComplete = it.next();
      if(dist(upComplete.x, upComplete.y, currHolder.x, currHolder.y) <= thresh){
        it.remove(); // removes upComplete from the queue
        return mergeNewPointHelper(upComplete, currHolder);
      }
    }
    return null;
  }
  
  /*
  Makes a new point tracker by merging the old PointComplete with the new PointHolder,
  adds the new point tracker to the tracker map, makes a new pointcomplete and returns it
  Input: upComplete is the old PointComplete, currHolder is the new Point Holder
  Output: The new PointComplete that is a combination of the old info and new info
  */
  PointComplete mergeNewPointHelper(PointComplete upComplete, PointHolder currHolder){
    PointTracker mergedTracker = new PointTracker(upComplete, currHolder); // new PointTracker
    
    // add new point tracker to trackerMap
    // id of point of the tracker map will be of new point, but internally it'll be the old point
    long currId = currHolder.sessionId;
    trackerMap.put(currId, mergedTracker);
    
    // create new PointComplete from currHolder and the new tracker
    PointComplete newPointComplete = new PointComplete(upComplete, currHolder);
    return newPointComplete;
  }
  
  /*
  Creates new Point Tracker, adds it to trackerHeap and returns the tracker.
  */
  PointTracker addPointTracker(PointHolder currHolder){
    long currId = currHolder.sessionId;
    float currX = currHolder.x;
    float currY = currHolder.y;
    PointTracker newTracker = new PointTracker(currHolder);
    trackerMap.put(currId, newTracker);
    return newTracker;
  }
  
  /*
  Goes through all PointCompletes on mainQueue. For any that are pending, looks through
  BeanData on accelQueue and updates the PointComplete's classifcationArr with the first
  three BeanData readings with a timestamp after the pointcomplete's, if they exist.
  If they do exist, then assign's pointComplete's classification as the majority
  classification or the earliest one if there is no majority.
  Note: Assumption is that if there are not three BeanData readings that came in after
  the pointComplete then there will be in the next frame so only update ones
  that have three in one frame 
  */
  void mergeClassification(){
    int numElems = mainQueue.size();
    ListIterator<PointComplete> it = ((LinkedList)mainQueue).listIterator(numElems);
    while(it.hasPrevious()){
      PointComplete currComplete = it.previous(); // previous point
      if(currComplete.classification == Classifier.pending){
        // reset index - could have been changed in previous frame but didn't get to 3 since
        // no vote was done
        currComplete.classificationArrIndex = 0;
        updateClassification(currComplete);
      }
     // if not pending, nothing that came before it will be pending either 
      else {
        break;
      }
    }
  }
  
  /*
  Loops through accelQueue to find first one with timeStamp after currComplete's timeStamp.
  If they exist, updates currComplete's classificationArr with the first three accelQueue elemens
  after its timeStamp then has the currComplete vote on the classification and assign an overall
  classification for itself. Also updates currComplete's accel data, imu data and classification timeStamp 
  with the first accelQueue elem after the timestamp. If there are not three accelQueue elems 
  that work, does not vote and does not assign overall class.
  Input: currComplete is the PointComplete to update
  */
  void updateClassification(PointComplete currComplete){
    // iterate through accelQueue starting from the Oldest elem (ie from the front)
    ListIterator<BeanData> it = ((LinkedList)accelerometer.accelQueue).listIterator(0);
    while(it.hasNext()){
      BeanData currBeanData = it.next();
      if(currComplete.timeStamp <= currBeanData.timeStamp){
        // some special stuff gets updates with info from first after down
        if(currComplete.classificationArrIndex == 0){
          currComplete.accelX = currBeanData.x;
          currComplete.accelY = currBeanData.y;
          currComplete.accelZ = currBeanData.z;
          currComplete.classificationTimeStamp = currBeanData.timeStamp;
          currComplete.yaw = currBeanData.yaw;
          currComplete.pitch = currBeanData.pitch;
          currComplete.roll = currBeanData.roll;
        }        
        // assign, increment, check for completion
        currComplete.classificationArr[currComplete.classificationArrIndex] = currBeanData.classification;
        currComplete.classificationArrIndex++;
        if(currComplete.classificationArrIndex == PointComplete.numReadings){
          currComplete.voteClassification();
          //println(classifier.classificationToString(currComplete.classification), " ", millis());
          break; 
        }
      }
    }
  }
  
  /********** DRAW **********/
  
  /*
  Iterates through mainQueue and draws all points
  */  
  void drawQueue(){
    for(PointComplete currComplete : mainQueue){
      currComplete.drawPoint();
    }
  }
  
  /********** GET INFO **********/
  
  /*
  Returns array containing all PointTrackers currently in trackerMap
  */
  PointTracker[] getTrackerArray(){
    int numElems = trackerMap.size();
    PointTracker[] result = new PointTracker[numElems];
    int i = 0;
    for(Map.Entry it : trackerMap.entrySet()){
      PointTracker currTracker = (PointTracker)it.getValue();
      result[i] = currTracker;
      i++;
    }
    return result;
  }
  
  /*
  Output: The last elemenent mainQueue ie the most recent point
  If mainQueue is empty, returns null
  */
  PointComplete getMostRecent(){
    int numElems = mainQueue.size();
    ListIterator<PointComplete> it = ((LinkedList)mainQueue).listIterator(numElems);
    if(it.hasPrevious()){
      return it.previous();
    }
    return null;
  }
  
  /*
  Finds the most recent entry of a PointComplete with sessionId id.
  Input: id the sessionId of the point we're looking for
  Output: The most recent PointComplete with that id.
          null if not found
  */
  PointComplete findRecentById(long id){
    int numElems = mainQueue.size();
    ListIterator<PointComplete> it = ((LinkedList)mainQueue).listIterator(numElems);
    while(it.hasPrevious()){
      PointComplete currComplete = it.previous();
      long currId = currComplete.sessionId;
      if(currId == id){
        return currComplete;
      }
    }
    return null;
  }
  
  /*
  Clears the mainQueue. Called by menu when it deactivates
  */
  void clearMainQueue(){
    mainQueue = new LinkedList<PointComplete>();
  }
  
  /* 
  Checks if there are no down points and no pending ups
  Returns: true if trackerMap is and upQueue are both empty
           false otherwise
  */
  boolean noDownPts() {
    return (trackerMap.isEmpty() && upQueue.isEmpty());
  }
  
  /*
  Gets the most recently classified down point after minTime
  Input: The down point must have occured after minTime
  Returns: The PointComplete for this point
  */
  PointComplete getNewDownPt(long minTime){    
    // find most recent down event
    int numElems = mainQueue.size();
    ListIterator<PointComplete> it = ((LinkedList)mainQueue).listIterator(numElems); // go through backwards
    
    while(it.hasPrevious()){
      PointComplete pt = it.previous();
      
      // before min time means we're too far back in the queue. stop.
      if(pt.timeStamp < minTime){
        break;
      }
      
      // check point properties
      int eventType = pt.eventType;
      // this is the most recent down event
      if(eventType == PointHolder.downEvent || eventType == PointHolder.movedEvent){
        int classification = pt.classification;
        if(classification != Classifier.pending && classification != Classifier.unclassified){
          return pt;
        }
        // last down was pending or unclassified 
        //else {
        //  break;
        //} // else
      } // if down event
    } // while
    return null;
  } // getNewDownPt
}