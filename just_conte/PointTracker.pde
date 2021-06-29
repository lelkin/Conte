/* Used in PointCollections heap.
Stores tracked info for points (ie info that is based off the id and is not temporally ordered)
When a touch event comes in and is pulled from the concurrentQueue, its id is used to look up
its point tracker. The point trackers and current points are stored in a heap maintained by pointCollection.
The information in the PointTrackers is needed for the Point that is stored in the main queue.
*/
class PointTracker{
  color c; // colour of point
  int lastNumPoints; // size of this point's path last time we saw it
  float x; // current location of this point
  float y; // current location of this point
  long sessionId; // the id number of the point. Also the key to the entry
  
  // needed for menu
  long timeDown; // time when point was first seen
  float xDown; // original x location of point
  float yDown; // original y location of point
  
  /*
  Constructor used for new point
  */
  PointTracker(PointHolder currHolder){
    c = color(int(random(0,256)), int(random(0,256)), int(random(0,256)));
    lastNumPoints = 1; // all points start off with one point in path on a down event
    this.x = currHolder.x; // these will get updated later
    this.y = currHolder.y;
    this.sessionId = currHolder.sessionId;
    this.timeDown = currHolder.timeStamp;
    this.xDown = currHolder.x; // these will not get updated later
    this.yDown = currHolder.y;
  }
  
  /*
  Constructor used for merging points
  Input: currComplete is the PointComplete that was created from the up Point
         currHolder is the PointHolder from the new down event
  */
  PointTracker(PointComplete upComplete, PointHolder currHolder){
    this.c = upComplete.c;
    /*
    Actually starts off with 2 points but only one is from the new holder so as far as getting points from subsequent
    paths is concerned, we've only seen one point
    */
    lastNumPoints = 1; 
    this.x = currHolder.x;
    this.y = currHolder.y;
    this.sessionId = upComplete.sessionId; // use old id
    
    this.timeDown = upComplete.timeDown;
    this.xDown = upComplete.xDown; // these will not get updated later
    this.yDown = upComplete.yDown;
  }
  
  /*
  Called on move event. Need to change lastNumPoints to the number of points in holder's path
  */
  void updateLastNumPoints(PointHolder pointHolder){
    PVector[] path = pointHolder.path;
    lastNumPoints = path.length;
    x = pointHolder.x;
    y = pointHolder.y;
  }
}
