/*
Sends out events over OSC.
Using remoteIP and remotePort as defined in just_conte globals
Implements same methods as App so that StateManager can still send them
And they're just sent out here
*/

import oscP5.*;
import netP5.*;

OSCSender oscSender;

class OSCSender{
  NetAddress myRemoteLocation; // app location ie where to send OSC messages
  int lastSendTime; // last time message sent
  final int sendWait = 50; // how long to wait between move sends
  
  OSCSender(){
    myRemoteLocation = new NetAddress(remoteIP, remotePort);
    lastSendTime = millis();
  }
  
  /*----------- COMMUNICATION ----------- */
  
  /*
  All called by stateManager.
  */
  
  /*
  Sent on Conte down event
  Input: classification is the classification on down
         event is the Pointcomplete for the individual touch event that caused this conte event
  */
  void down(int classification, PointComplete event){
    lastSendTime = millis();
    sendTouchMessage("/down", classification, event);
  }
  
  /*
  Sent on Conte up event
  Input: classification is the classification on down
       event is the Pointcomplete for the individual touch event that caused this conte event
  */
  void move(int classification, PointComplete event){
    int currTime = millis();
    if(currTime - lastSendTime > sendWait){
      sendTouchMessage("/move", classification, event);
    }
  }
  
  /*
  Sent on Conte up event
  Input: classification is the classification on down
       event is the Pointcomplete for the individual touch event that caused this conte event
  */
  void up(int classification, PointComplete event){
    lastSendTime = millis();
    sendTouchMessage("/up", classification, event);
  }
  
  /*
  Sent when Conte is not contacting the screen
  Still need orientation and accel data for in-air gestures and/or menu
  For now, just send things the existing menu needs, will update after.
  */
  void air(){
    BeanData event = accelerometer.getMostRecentClassification(); // most recent classified. null if none
    if(event != null){
      sendAirMessage(event);
    } else {
    }
  }
  
  /*
  Called when nothing has been received from Conte in a certain amount of time.
  Note: Does not mean the receiving app should be terminated, it can decide that for itself.
  */
  void UDPDelayed(){
    println("delayed", frameCount);
    //OscMessage message = new OscMessage("/delay");
    //OscP5.flush(message, myRemoteLocation);
  }
  
  /*---------- HELPERS ----------*/
  
  /*
  Send OSC message when Conte is touching -- all have same format.
  Input: contType is the conte event type (down, move, up, air) which will be the header for the message
         classification is the classification on down
         event is the PointComplete for the touch event that caused this message to be sent
  */
  void sendTouchMessage(String conteType, int classification, PointComplete event){
    long id = event.sessionId;
    PVector scaledCoords = screens.toSensor(event.x, event.y);
    float x = scaledCoords.x;
    float y = scaledCoords.y;
    // in degrees
    int yaw = event.yaw;
    int pitch = event.pitch;
    int roll = event.roll;
    int ax = event.accelX;
    int ay = event.accelY;
    int az = event.accelZ;
    int ptType = event.eventType;
    int ptClass = event.classification; // classification of individual point
    PVector[] notScaledPtsArr = event.path;
    PVector[] ptsArr = new PVector[notScaledPtsArr.length]; // scaled all points
    for(int i = 0; i < ptsArr.length; i++){
      PVector notScaled = notScaledPtsArr[i];
      PVector scaled = screens.toSensor(notScaled.x, notScaled.y);
      ptsArr[i] = scaled;
    }
    
    formatAndSend(conteType, id, classification, x, y, yaw, pitch, roll, ax, ay, az, ptType, ptClass, ptsArr); 
  }
 
  /*
  Send OSC message when Conte is in air.
  Input: event is most recent classified imu data
  id is 0
  Position is -1, -1
  Path length is 0
  conteType and ptType are both "air" (which is 3)
  classification and ptClass are same (from event)
  */
  void sendAirMessage(BeanData event){
    String conteType = "/air";
    long id = -1;
    int classification = event.classification;
    float x = -1;
    float y = -1;
    // in degrees
    int yaw = event.yaw;
    int pitch = event.pitch;
    int roll = event.roll;
    int ax = event.x;
    int ay = event.y;
    int az = event.z;
    int ptType = PointHolder.airEvent;
    int ptClass = event.classification; // classification of individual point
    PVector[] ptsArr = {new PVector(0,0)};
    formatAndSend(conteType, id, classification, x, y, yaw, pitch, roll, ax, ay, az, ptType, ptClass, ptsArr);
  }
  
  /*
  Creates and sends OSCMessage with all params in message. ConteType is message addr
  */
  void formatAndSend(String conteType, long id, int classification, float x, float y, int yaw, int pitch, int roll,
                     int ax, int ay, int az, int ptType, int ptClass, PVector[] ptsArr){
    OscMessage message = new OscMessage(conteType);
    message.add(int(id));
    message.add(classification);
    message.add(x);
    message.add(y);
    message.add(yaw);
    message.add(pitch);
    message.add(roll);
    message.add(ax);
    message.add(ay);
    message.add(az);
    message.add(ptType);
    message.add(ptClass);
    addPtArr(message, ptsArr);
    
    // send the OscMessage to the remote location
    OscP5.flush(message, myRemoteLocation);
  }
  
  /*
  Adds pts to message in the format x0, y0, x1, y1, ...
  each as seperate elems
  Input: pts is the array of PVectors to add
  Note: changes message
  */
  void addPtArr(OscMessage message, PVector[] pts){
    message.add(pts.length);
    for(int i = 0; i < pts.length; i++){
      PVector curr = pts[i];
      message.add(curr.x);
      message.add(curr.y);
    }
  }
}