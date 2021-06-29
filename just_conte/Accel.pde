/*
Collects IMU data
 Sets up udp connection with esp8285 and receives imu readings
 */
import processing.net.*; // tcp
import java.io.File; // reading in images from files
import hypermedia.net.*; // udp

Accel accelerometer;

class Accel {
  // udp
  PApplet parent; // main program to pass to Server constructor
  UDP udp;  // udp object
  final int localPort = 6000; // port messages come in on
  ConcurrentLinkedQueue<BeanData> imuDataQueue; // threadsafe queue for incoming imu data to be transferred to accelQueue

    // queue to store last few seen points
  static final int maxQueueSize = 20; // max number of points that can be stored on the accelQueue
  Queue<BeanData> accelQueue; 

  // tracking frequency of incoming data
  float freq = 0;
  int lastTime = 0;
  float freqTotal = 0;
  int numValues = 0; // number of frequency readings in freqTotal
  int maxDelay = 2000; // how much time waited until send delay osc message

  Accel(PApplet parent) {
    this.parent = parent;
    accelQueue = new LinkedList<BeanData>(); // init queue
    setupUDP();
  }

  /*---------- Acceleration and Angles ----------*/

  /* 
   Gets incoming bean data, calculates angle, classifies data, adds bean data to accelQueue
   Also notifies oscSender if data hasn't been received in a while (defined as maxDelay)
   */
  void getData() {
    actualGetData();
    checkUDPDelay();
  }
  
  /*
  Pulls data off of threadsafe imuDataQueue and calls updateData which adds it to accelQueue
  */
  void actualGetData(){
    // pull data from threadsafe queue
    while (!imuDataQueue.isEmpty ()) {
      // get oldest reading that came in from imu
      BeanData currData = imuDataQueue.poll();

      // classify reading
      int classification = classifier.classifyData(currData.roll, currData.pitch, currData.yaw);
      //println("classify ", classifier.classificationToString(classification));

      // log reading
      logData(currData.roll, currData.pitch, currData.yaw, currData.x, currData.y, currData.z, classification);

      // update data with reading
      updateData(currData, classification);
    }
  }
  
  /*
  Checks if the last time data was received was more than max delay away. If yes, notifies oscSender
  */
  void checkUDPDelay(){
    int currTime = millis();
    if(currTime - lastTime > maxDelay){
      oscSender.UDPDelayed();
    }
  }

  void logData(int roll, int pitch, int yaw, int x, int y, int z, int classification) {
    logger.doLog(new AccelInputEvent(x, y, z, roll, pitch, yaw));
  }

  /*
  Updates the current instance of BeanData with its classification and stores it on accelQueue
   Input: currData is the current data object
   classification is the classification of the imu. It is an int representing a contact point
   see Classifier class for details
   */
  void updateData(BeanData currData, int classification) {
    currData.setClassification(classification);

    // update accelQueue
    if (accelQueue.size() >= maxQueueSize) {
      accelQueue.remove();
    }
    accelQueue.add(currData);
  }

  /*---------- ACCESING ACCELQUEUE ----------*/

  /*
  Input: i is the index of the element we want from the end of the queue (ie newest elem in the queue is 0)
  Output: The ith most recent elem in the queue with i = 0 being the last one and so on 
  If accelQueue does not have at least i+1 elems, returns null
   */
  BeanData getMostRecent(int i) {
    int numElems = accelQueue.size();
    ListIterator<BeanData> it = ((LinkedList)accelQueue).listIterator(numElems); // puts iterator immediately after final elem    
    // move cursor back i-1 times so at end of loop it's one ahead of the index we want
    for(int j = 0; j < i; j++){
      if(it.hasPrevious()){
        it.previous();
      }
    }
    // if can move it back one more return the element at index i - else return null    
    if (it.hasPrevious()) {
      BeanData lastElem = it.previous();
      return lastElem;
    }
    return null;
  }
  
    /*
  Gets the most recent classification for that is not unclassified.
  Returns: Most recent classified BeanData object
           Null if none found
  */
  BeanData getMostRecentClassification(){
    // pull most recent item off accelQueue that is classified
    int numElems = accelerometer.accelQueue.size();
    ListIterator<BeanData> it = ((LinkedList)accelerometer.accelQueue).listIterator(numElems); // puts iterator immediately after final elem    
    // move cursor back until find classified elem
    while(it.hasPrevious()){
      BeanData curr = it.previous();
      if(curr.classification != Classifier.unclassified){
        return curr;
      }
    }
    return null;
  }

  /*
  Checks if the most recent event is an up event and returns its timestamp if it is
   Returns: time of most recent up event, using upMagThresh, and returns its time if it is
   otherwise returns 0
   */
  long hasUnprocessedUp() {
    int numElems = accelQueue.size();
    ListIterator<BeanData> it = ((LinkedList)accelQueue).listIterator(numElems);
    if (it.hasPrevious()) {
      BeanData lastAdded = it.previous();
      if (lastAdded.isUp()) {
        //println("UP ", frameCount);
        long lastAddedTime = lastAdded.timeStamp;
        return lastAddedTime;
      }
    }
    return 0;
  }

  /*---------- UDP ----------*/

  void setupUDP() {
    // setup queue
    imuDataQueue = new ConcurrentLinkedQueue<BeanData>();

    udp = new UDP(parent, localPort);
    //udp.log( true );     // printout the connection activity
    udp.listen( true );

    // tracking frequency
    lastTime = millis(); // this will get updated again when server actually connects
  }

  /*
  Receives input from imu over udp. Decodes input. Creates new BeanData object and puts it on imuDataQueue
   Also tracks frequency of incoming data
   */
  void receive( byte[] data ) {
    // decode data
    // processing interprets the bytes as 2s complement so 255 becomes -1, 128 becomes -128
    // also keep in mind that 127 stays as 127 so 127+256 % 256 is 127.
    // ie add 256 then mod by 256 gets these to all positive ints like I meant them
    int[] adjustedData = new int[10];
    for (int i = 0; i < 10; i++) {
      adjustedData[i] = (data[i] + 256) % 256;
    }
    
    // ANGLES
    int yaw = (adjustedData[0] << 1) | ((adjustedData[3] & 0x02) >> 1);
    int pitch = adjustedData[1] - 90;
    int roll = ((adjustedData[2] << 1) | (adjustedData[3] & 0x01)) - 180;
    //println("Yaw: ", yaw, " Pitch: ", pitch, " Roll: ", roll);
    
    // ACCEL
    int x = (((adjustedData[4] << 4) | adjustedData[5])-800)*2;
    int y = (((adjustedData[6] << 4) | adjustedData[7])-800)*2;
    int z = (((adjustedData[8] << 4) | adjustedData[9])-800)*2;
    
    //println(" x ", x, " y ", y, " z ", z, " ", frameCount);
   
    // add to imuDataQueue
    BeanData currData = new ImuData(roll, pitch, yaw, x, y, z);
    imuDataQueue.add(currData);
    
    // freq
    updateFreq();
  }

  /*---------- Misc ----------*/
  /*
  keeps track of frequency of incoming data  
  */
  void updateFreq() {
    int t = millis() - lastTime;
    //println(t, 1000/ float(t));
    lastTime = millis();
    //numValues++;
    //freqTotal+=(1000/float(t));
    ////println(freqTotal/numValues);
  }
}