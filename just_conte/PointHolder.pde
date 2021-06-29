/*
Type of element that is put on ConcurrentLinkedQueue<PointHolder> pointHolderQueue;
Used to temporarily hold point info before it is put on main queue.
Used to copy all information from SMT events that might be needed out of the info from the incoming touch
*/
class PointHolder{
  // event types
  static final int downEvent = 0;
  static final int movedEvent = 1;
  static final int upEvent = 2;
  static final int airEvent = 3; // used for conte in air
  
  // actual fields
  long sessionId; // session Id of the touch
  float x; // current x position
  float y; // current y position
  PVector[] path; // the entire path COPIED from the touch
  int eventType; // downEvent, moveEvent, upEvent
  long timeStamp; // time in millis that this event came in at
  
  /* Constructor */
  PointHolder(TuioCursor touch, int eventType){
    sessionId = touch.getSessionID();
    PVector coords = screens.fromSensor(touch.getX(), touch.getY()); // actual canvas coordinates
    x = coords.x;
    y = coords.y;
    path = copyPath(touch);
    this.eventType = eventType;
    this.timeStamp = millis();
  }
  
  /*
  Copies the path in the touch. Used by constructor.
  */
  PVector[] copyPath(TuioCursor touch){
    ArrayList<TuioPoint> path = touch.getPath();
    int pathLen = path.size();
    PVector[] pathCopy = new PVector[pathLen];
    for(int i = 0; i < pathLen; i++){
      TuioPoint elem = path.get(i);
      PVector pathVector = screens.fromSensor(touch.getX(), touch.getY());
      pathCopy[i] = pathVector;
    }
    return pathCopy;
  }
  
  /* MISC */
  /*
  Returns a string representing the event type as seen by the static var names
  */
  String eventTypeToString(int eventType){
    switch(eventType){
      case 0:
        return "D";
      case 1:
        return "M";
      case 2:
        return "U";
    }
    return "";
  }
  
  /*
  Sends info about the touch that created this point holder to the logger
  */
  void logEvent(){
    logger.doLog(new TouchInputEvent(sessionId, eventTypeToString(eventType), x, y));
  }
}