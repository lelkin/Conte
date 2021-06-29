/*
Interface between OSC and old app code
Creates concurrent queues for OSC incoming messages to go on
Pulls messages off queues each frame and calls app methods like statemanager used to do
*/

OscAppInterface oscApp;

class OscAppInterface{
  private ConcurrentLinkedQueue<OscMessage> concurrentMessages; // concurrent queue for messages
  private LinkedList<OscMessage> menuMessages; // not concurrent linked list for messages - they get moved here every frame for menu
  private final int maxAirSize = 20; // max number of air messages that can sit in airMessages
  
  OscAppInterface(PApplet parent){
    // init receiver
    oscReceiver = new OscReceiver(parent);
    // init app
    if(gameType.equals("FastTap")){
      app = new FastTapApp(parent);
    } else if(gameType.equals("Conte")){
      app = new GameApp(parent);
    }
    
    // init threadsafe queues
    concurrentMessages = new ConcurrentLinkedQueue<OscMessage>();
    menuMessages = new LinkedList<OscMessage>();
  }
  
  /*
  called every frame
  pulls stuff off queues, makes appropriate calls to app, then draws app
  */
  void update(){
    // iterate through messages
    while(!concurrentMessages.isEmpty()){
      OscMessage currOscMessage = concurrentMessages.poll();
      AppMessage currAppMessage = new AppMessage(currOscMessage);
      String conteType = currAppMessage.conteType;
      
      // if it's a touch message make appropriate app call
      if(conteType.equals("/down")){
        Contact contact = classToContact.get(currAppMessage.classification);
        app.down(currAppMessage.classification, currAppMessage.pts, currAppMessage.id, currAppMessage.ptType);
      } else if(conteType.equals("/move")){
        app.move(currAppMessage.pts, currAppMessage.id, currAppMessage.ptType);
      } else if(conteType.equals("/up")){
        app.up(currAppMessage.pts, currAppMessage.id, currAppMessage.ptType);
      }
      
      // add to menu messages always
      // first get rid of extra menu messages
      while(menuMessages.size() >= maxAirSize){
        menuMessages.removeFirst();
      }
      // add curr to end
      menuMessages.add(currOscMessage);
    }
    
    // draw app
    app.draw();
  }
  
  /*
  Adds message to oscMessages queue
  Input: message is the message to add
  */
  void addMessage(OscMessage message){
    // if it's a delay message handle it differently
    if(message.addrPattern().equals("/delay")){
      app.delayed();
    } else {
      concurrentMessages.add(message);
    }
  }
  
  /*
  removes all messages from menuMessages (used to be called airMessages)
  used to ensure queue doesn't get to big
  currently not in use
  */
  void clearAirMessage(){
    menuMessages.clear();
  }
  
  /*
  Gets the most recent classification from airMessages that is not Classifier.unclassified
  Returns: Classifier.classification of most recent elem
           Classifier.unclassified if empty
  */
  int mostRecentAirClassification(){
    // pull most recent item off accelQueue that is classified
    int numElems = menuMessages.size();
    Iterator<OscMessage> it = menuMessages.descendingIterator();
    // move cursor back until find classified elem
    while(it.hasNext()){ // it's a descending iterator so next is really previous
      OscMessage curr = it.next();
      int currClass = classFromAirMessage(curr);
      if(currClass != Classifier.unclassified){
        return currClass;
      }
    }
    return Classifier.unclassified;
  }
  
  /*
  Gets the most recent OSC message off menuMessages and returns the corresponding AppMessage
  Output: AppMessage corresponding to most recent osc message
          returns null if empty
  */
  AppMessage mostRecentMessage(){
    if(menuMessages.isEmpty()){
      return null;
    }
    OscMessage lastMessage = menuMessages.getLast();
    AppMessage curr = new AppMessage(lastMessage);
    return curr;
  }
  
  /*
  Gets the Classifier.classification from an OscMessage
  Input: message is the OscMessage to parse
  Output: Classification as int (see Classifier class)
  */
  int classFromAirMessage(OscMessage message){
    int classification = message.get(1).intValue();
    return classification;
  }
}