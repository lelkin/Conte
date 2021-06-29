/*
Has all info needed to draw point. Will be stored for multiple frames in pointCollection's mainQueue.
*/
class PointComplete{
  static final int diam = 10; // diam of point when drawing
  static final int sWeight = 2; // stroke weight used when drawing path
  static final int numReadings = 3; // number of classifcations we wait for until we vote - first one breaks tie 
  long sessionId; // session Id of the touch
  float x; // current x position
  float y; // current y position
  PVector[] path; // just the relevant part of the path
  int eventType; // downEvent, moveEvent, upEvent. Use PointHolder's static vars
  long timeStamp; // time in millis that this event came in at
  color c; // colour to draw in
  int classification; // classification types from Classifier class
  int classificationArrIndex = 0; // number of non-pending elems currently in classificationArr
  int[] classificationArr = {Classifier.pending, Classifier.pending, Classifier.pending}; // first is oldest
  // accel values used to compute classification - assigned when classification assigned. Zero as place-holder
  int accelX = 0;
  int accelY = 0;
  int accelZ = 0;
  long classificationTimeStamp; // time in millis that the classification came in at.
  int frame; // frameCount that this is being updated on
  boolean usedForRollUp; // has this point been in mainQueue when a roll up was detected
  
  // needed from menu
  long timeDown; // time when point was first seen
  float xDown; // original x location of point
  float yDown; // original y location of point
  
  // degrees. assigned when classifcation assigned
  int yaw;
  int pitch;
  int roll;
  
  /* 
  CONSTRUCTOR for down, move, and up
  */
  PointComplete(PointHolder pointHolder, PointTracker pointTracker){
    // after a point is merged, for all subsequent events the pointHolder will have the wrong id 
    // but the pointTracker will have the right one
    this.sessionId = pointTracker.sessionId;
    this.x = pointHolder.x;
    this.y = pointHolder.y;
    this.eventType = pointHolder.eventType;
    this.timeStamp = pointHolder.timeStamp; // note point holder is a new one every frame
    this.c = pointTracker.c;
    this.classification = Classifier.pending;
    this.frame = frameCount;
    this.classificationTimeStamp = 0;
    this.usedForRollUp = false;
    this.timeDown = pointTracker.timeDown;
    this.xDown = pointTracker.xDown;
    this.yDown = pointTracker.yDown;
    
    // don't copy whole path, just copy relevant part
    this.path = getPath(pointHolder.path, pointTracker.lastNumPoints);
  }
  
  /*
  Gets the new part of the path - used for normal down, move, and up (although probably really just move)
  Input: wholePath is the entire path that the pointHolder has
         lastNumPoints is the previously seen number of points along that point's path
  Return: a PVector array containing just the new points along the path
  */
  PVector[] getPath(PVector[] wholePath, int lastNumPoints){
    int wholePathLen = wholePath.length;
    int newPathLen = (wholePathLen - lastNumPoints) + 1; // last elem of old path is first elem of new path
    PVector[] newPath = new PVector[newPathLen];
    for(int i = 0; i < newPathLen; i++){
      PVector wholePathElem = wholePath[i + lastNumPoints - 1];
      PVector newPathElem = new PVector(wholePathElem.x, wholePathElem.y);
      newPath[i] = newPathElem;
    }
    return newPath;
  }
  
  /*
  CONSTRUCTOR for merged
  Input: pointComplete is the old up point
         pointHolder is from the new down event
  */
  PointComplete(PointComplete pointComplete, PointHolder pointHolder){
    this.sessionId = pointComplete.sessionId; // use old session id
    this.x = pointHolder.x; // coords
    this.y = pointHolder.y;
    this.eventType = PointHolder.movedEvent; // a merge is treated like a move
    this.timeStamp = pointHolder.timeStamp; // note point holder is a new one every frame
    this.c = pointComplete.c;
    this.classification = Classifier.pending;
    this.frame = frameCount;
    this.classificationTimeStamp = 0;
    this.usedForRollUp = false;
    this.timeDown = pointComplete.timeDown;
    this.xDown = pointComplete.xDown;
    this.yDown = pointComplete.yDown;
    
    // don't copy whole path, just copy relevant part
    this.path = getMergedPath(pointComplete.path, pointHolder.x, pointHolder.y);
  }
  
  /*
  Adds a PVector at (x,y) to pointCompletePath and returns the whole thing as a new path
  Input: pointCompletePath is the old path to add to
         x,y are the coords of the new point to add
  Output: An array of PVectors containing all of pointCompletePath followed by the new point
  */
  PVector[] getMergedPath(PVector[] pointCompletePath, float x, float y){
    int numPoints = pointCompletePath.length + 1;
    PVector[] newPath = new PVector[numPoints];
    for(int i = 0; i < pointCompletePath.length; i++){
      PVector oldPoint = pointCompletePath[i];
      PVector newPoint = new PVector(oldPoint.x, oldPoint.y);
      newPath[i] = newPoint;
    }
    PVector newPoint = new PVector(x,y);
    newPath[numPoints-1] = newPoint;
    return newPath;
  }
  
  /* CLASSIFICATION */
  
  /*
  Assign classification based on classifcations in classificationArr
  Only called when classification Arr is full
  Voting scheme: majority wins. tie broken by elem at index 0 (which was the first seen after touch down)
  */
  void voteClassification(){
    boolean foundMajority = false; // there is a majority win in the vote 
    // this works because it's 3. if change the number of elems do something more general    
    for(int i = 0; i < numReadings - 1; i++){
      for(int j = i+1; j < numReadings; j++){
        // there are only 3 things so if two are the same there's a majority
        if(classificationArr[i] == classificationArr[j]){
          classification = classificationArr[i];
          foundMajority = true;
          break;
        }
      }
    }
    
    // check if there was a majority vote
    if(!foundMajority){
      classification = classificationArr[0]; // first one is oldest
    }
  }
  
  /* DRAW */
  /*
  Draws point
  If eventType is PointHolder.downEvent, just draws point
  If eventType is PointHolder.movedEvent, draws path
  If EventType is PointHolder.upEvent, just draws point
  Always draws in colour c 
  */
  void drawPoint(){
    fill(c);  
    switch(eventType){
      case PointHolder.downEvent:
        noStroke();
        ellipse(x,y,50,50);
        
        // TEST draw coords
        fill(255,255,255);
        textAlign(CENTER, CENTER);
        textSize(16);
        text("DOWN x " + str(x) + " y " + str(y) + " time " + str(timeStamp), x, y);
        break;
      case PointHolder.movedEvent:
        strokeWeight(sWeight);
        stroke(c);
        drawPath();
        break;
      case PointHolder.upEvent:
        noStroke();
//        ellipse(x,y,50,50);
//        
//        // TEST draw coords
//        fill(255,255,255);
//        textAlign(CENTER, CENTER);
//        textSize(16);
//        text("UP x " + str(x) + " y " + str(y) + " time " + str(timeStamp), x, y);
        break;
    }
  }
  
  /*
  Only called on move event. Draws lines between all adjacent points in the path
  */
  
  void drawPath(){
    for(int i = 0; i < path.length - 1; i++){
      PVector point1 = path[i];
      PVector point2 = path[i+1];
      line(point1.x, point1.y, point2.x, point2.y);
    }
  }
}