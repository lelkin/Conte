/*
Used by app to track info about points with multiple physical contact points
*/

class MultiPoint{  
  int numPoints; // number of contact points
  HashMap<Long, PVector> pointMap; // key is id, PVector is the last seen location of that point
  ArrayList<Long> upList; // list of up ids - we only remove the points from pointMap if we see another move or down
  Contact currContact; // which contact point it is
  
  /*
  Input: numPoints is the number of physical contact points this point has
         currContact is the contact point
  */
  MultiPoint(Contact currContact){
    this.currContact = currContact;
    pointMap = new HashMap<Long, PVector>();
    this.numPoints = currContact.numPts;
    upList = new ArrayList<Long>();
  }
  
  /*
  Updates id elem in pointMap
  Input: id is the id number of the point
         pts is the array containing its most recently seen movement
         eventType is a PointHolder.eventType - it's down, move, or up
  Outputs: A PVector with the average of all points in pointMap
  Modifies: pointMap if eventType is down, adds point to pointMap
            if eventType is move, just updates value
            if eventType is up, adds id to upList 
  */
  PVector update(long id, PVector[] pts, int eventType){
    PVector result = null;
    switch(eventType){
      case(AppMessage.downEvent):
        result = down(id, pts);
        break;
      case(AppMessage.movedEvent):
        result = move(id, pts);
        break;
      case(AppMessage.upEvent):
        result = up(id, pts);
        break;
    }
    if(result != null){
      logMultiPoint(eventType, id, result);
    }
    return result;
  }
  
  /*
  Called on a contact point down which is different than a conte down
  Adds last elem of pts to pointMap.
  If pointMap has at least numPts points, gets their average as a PVector and returns it
  If not, returns null
  Input: id is the id of the point
         pts is the array of its most recently seen locations
  Output: PVector which is the average of all point locations if enough points
          otherwise, null
  */
  //PVector down(long id, PVector[] pts){
  //  println("MULTIPONIT DOWN");
  //  clearUp();
  //  PVector lastPt = pts[pts.length-1];
  //  pointMap.put(id, lastPt);
  //  if(pointMap.size() >= numPoints){
  //    PVector avg = pointMapAvg();
  //    return avg;
  //  } else {
  //    return null;
  //  }
  //}
  
  PVector down(long id, PVector[] pts){
    clearUp();
    return move(id, pts);
  }
  
  /*
  Called on a contact point move (different from a conte move)
  Updates pointMap(id) to last elem of pts
  If pointMap has at least numPts points, gets their average as a PVector and returns it
  If not, returns null
  Input: id is the id of the point
         pts is the array of its most recently seen locations
  Output: PVector which is the average of all point locations if enough points
          otherwise, null  
  */
  //PVector move(long id, PVector[] pts){
  //  return down(id, pts); // currently they do the same thing
  //}
  
  PVector move(long id, PVector[] pts){
    PVector lastPt = pts[pts.length-1];
    pointMap.put(id, lastPt);
    if(pointMap.size() >= numPoints){
      PVector avg = pointMapAvg();
      return avg;
    } else {
      return null;
    }
  }
  
  /*
  Called on a conact point up, which is different than a conte up
  Updates pointMap(id) and adds id to upList
  Returns average of all points in pointMap as a PVector
  Input: id is the id of the point
         pt is the array containing its most recently seen locations
  Output: PVector which is the average of all point locations in pointMap
  Note: move and down remove all points whose ids are in upArr.
        this is done this way so that we get the correct location on up
        ie a conte up event will be preceeded by multiple contact point up events
        Want the correct location on up so keep those points in the point map
        If we see another move or down, we're probably not about to get an actual
        Conte up event
  */
  PVector up(long id, PVector[] pts){
    // update point in pointMap
    PVector lastPt = pts[pts.length-1];
    pointMap.put(id, lastPt);
    
    // update upList
    upList.add(id);
    
    // return average of all points
    PVector avg = pointMapAvg();
    return avg;
  }
  

  /*
  Finds and returns the average of all points in pointMap as a PVector
  Output: Average of all pts in pointMap as a PVector
  */
  PVector pointMapAvg(){
    float totalX = 0;
    float totalY = 0;
    for(Object object : pointMap.values()){
      PVector pt = (PVector)object;
      totalX += pt.x;
      totalY += pt.y;
    }    
    float xAvg = totalX/pointMap.size();
    float yAvg = totalY/pointMap.size();
    PVector result = new PVector(xAvg, yAvg);
    return result;
  }
  
  /*
  Remove all points in upList from pointMap
  Inits upList to new ArrayList
  */
  void clearUp(){
    for(long id : upList){
      pointMap.remove(id);
    }
    
    // reset
    upList = new ArrayList<Long>();
  }
  
  /*---------- LOG ----------*/
  
  /*
  Logs multipoint event
  Input: eventType is PointHolder.downEvent, PointHolder.movedEvent, pointHolder.upEvent
         id is the id of the touch point
         result is the avg of all current pts - result cannot be null when logging
  */
  void logMultiPoint(int eventType, long id, PVector result){
    // get string representation of touch type
    String touchType = "";
    switch(eventType){
      case AppMessage.downEvent:
        touchType = "D";
        break;
      case AppMessage.movedEvent:
        touchType = "M";
        break;
      case AppMessage.upEvent:
        touchType = "U";
        break;
    }
    logger.doLog(new MultiPointInputEvent(id, touchType, result.x, result.y, currContact));
  }
}