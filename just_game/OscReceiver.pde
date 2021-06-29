/*
Receives Osc events and puts data in threadsafe queue for app and menu to pull off
*/

import oscP5.*;
import netP5.*;
import java.util.concurrent.*;

OscReceiver oscReceiver; // global OscReceiver object

class OscReceiver{
  OscP5 oscP5; // library
  
  OscReceiver(PApplet parent){
    oscP5 = new OscP5(parent, myPort);
  }
  
  /*
  handle oscevents
  Called always and only by global oscEvent function on incoming osc messages
  */
  void oscEvent(OscMessage theOscMessage){
    oscApp.addMessage(theOscMessage);
  }
}

/*---------- OSC must be global function ----------*/
void oscEvent(OscMessage theOscMessage) {
  oscReceiver.oscEvent(theOscMessage);
}