/*
Base  class for incoming data from bean
Always use either AccelData or ImuData subclass
*/
abstract class BeanData{
  // accel
  int x;
  int y;
  int z;
  float mag; // magnitude of acceleration. used for up
  
  // orientation
  int roll;
  int pitch;
  int yaw;
  
  int classification; // uses Classifier classification types
  long timeStamp; // time the point came in
  
  /*
  Constructor
  */
  BeanData(){
    timeStamp = millis();
  }
  
  /*
  Returns: true if this BeanData represents and up movement
  */
  abstract boolean isUp();
  
  /*
  Rotates the 3 standard basis axes by Ax and Ay and returns an array of all 3 rotated axes
  Input: Ax and Ay are the angles conte is rotated by on down
         Ax and Ay are in RADIANS
  Output: The rotated standard basis axes: {rotatedX, rotatedY, rotatedZ}
  */
  abstract PVector[] rotateAxes(int Ax, int Ay);
  
  /*
  Input: theta is the angle to rotate by in DEGREES
         axes is an array of PVectors holding the axes to rotate
  Output: rotated axes
  */
  abstract PVector[] rotateAxesX3D(int theta, PVector[] axes);
  
  /*
  Input: theta is the angle to rotate by in DEGREES
         axes is an array of PVectors holding the axes to rotate
  Output: rotated axes
  */
  abstract PVector[] rotateAxesY3D(int theta, PVector[] axes);
  
  /*
  Calculates the component of the current acceleration that's in the up direction
  Input: The rotated axes
  Output: PVector with global x,y,z accel (z comp is upcomp, mag is total mag) GRAVITY ALREADY REMOVED
  */
  PVector getUpComp(PVector[] axes){
    PVector xAxis = axes[0];
    PVector yAxis = axes[1];
    PVector zAxis = axes[2];
    
    PVector newX = new PVector(x*xAxis.x, x*xAxis.y, x*xAxis.z);
    PVector newY = new PVector(y*yAxis.x, y*yAxis.y, y*yAxis.z);
    PVector newZ = new PVector(z*zAxis.x, z*zAxis.y, z*zAxis.z);
    
    PVector result = new PVector(newX.x + newY.x + newZ.x,
                                 newX.y + newY.y + newZ.y,
                                 newX.z + newY.z + newZ.z);
                                 
    // subtract gravity
    PVector gravity = new PVector(0,0,100); // it's 1 g down but we've multiplied by 100
    result.sub(gravity);
    
    return result;
  }
  
  /*
  Sets classification for this object
  Input: Classifier classification type as int
  */
  void setClassification(int classification){
    this.classification = classification;
  }
}

/*
Incoming accelerometer data
*/
class AccelData extends BeanData{
    /*
    Input: accel is [x,y,z] acceleration in each direction
    AxAy is [Ax, Ay] rotation (in degrees) in each direction
    */
    AccelData(int[] accel, float[] AxAy){    
    x = accel[0];
    y = accel[1];
    z = accel[2];
    
    roll = int(AxAy[0]);
    pitch = int(AxAy[1]);
    yaw = 0;
    
    mag = sqrt((x*x) + (y*y) + (z*z));
  }
  
  boolean isUp(){
    // check not already in up state and isn't too soon after down
    if(stateManager.upPossible()){
      int[] accelOnDown = stateManager.getAccelOnDown();
      int[] downAxAy = getDownAxAy(accelOnDown); // {Ax, Ay} in degrees
      int downAx = downAxAy[0];
      int downAy = downAxAy[1];
      PVector[] rotatedAxes = rotateAxes(downAx, downAy);
      PVector globalAccel = getUpComp(rotatedAxes);
      float upComp = globalAccel.z;
      float diff = (abs(abs(upComp) - abs(256)));
      //println("UP");
      return (diff > 80 && abs(upComp/mag) > 0.75);
    } else {
      return false;
    }
  }
    
  PVector[] rotateAxes(int Ax, int Ay){
    PVector[] axes = {new PVector(1,0,0), new PVector(0,1,0), new PVector(0,0,1)};
    axes = rotateAxesX3D(Ay, axes);
    axes = rotateAxesY3D(Ax, axes);
    return axes;
  }
  
  PVector[] rotateAxesX3D(int theta, PVector[] axes){
    float sinTheta = sin(radians(theta));
    float cosTheta = cos(radians(theta));
      
    for(int i = 0; i < axes.length; i++){
      PVector axis = axes[i];
      float y = axis.y;
      float z = axis.z;     
      axis.y = y * cosTheta + z * sinTheta;
      axis.z = z * cosTheta - y * sinTheta;
    }
    return axes;
  }
  
  PVector[] rotateAxesY3D(int theta, PVector[] axes) {
    float sinTheta = sin(radians(theta));
    float cosTheta = cos(radians(theta));
    
    for (int i = 0; i<axes.length; i++) {
        PVector axis = axes[i];
        float x = axis.x;
        float z = axis.z;
        axis.x = x * cosTheta + z * sinTheta;
        axis.z = z * cosTheta - x * sinTheta;
    }
    return axes;
  }
  
  /*
  Calculates the angle conte was at on down - note these are calculated differently than the angles used for classification
  Input: {x,y,z} acceleration from when conte touched down
  Returns: {Ax, Ay} in DEGREES
  */
  int[] getDownAxAy(int[] accelOnDown){
    int downx = accelOnDown[0];
    int downy = accelOnDown[1];
    int downz = accelOnDown[2];
    
    // Ax
    float xArg = float(downx)/sqrt((downy*downy) + (downz*downz));
    //float radAx = atan(xArg);
    float downAx = atan2(float(downx), sqrt((downy*downy) + (downz*downz)));
    
    // Ay
    float yArg = float(downy)/sqrt((downx*downx) + (downz*downz));
    //float radAy = atan(yArg);
    float downAy = atan2(float(downy), sqrt((downx*downx) + (downz*downz)));

    
    if(z > 0){
      downAx *= -1;
      downAy *= -1;
    }
    
    int[] result = {int(degrees(downAx)), int(degrees(downAy))};
    return result;
  }  
}

/*
Incoming IMU data
*/
class ImuData extends BeanData{
  /*
  Input: roll, pitch, yaw, are in degrees from IMU
         x,y,z are acceleration in each direction as +-1600, divide by 200 to get +- how many gs
  */
  
  ImuData(int roll, int pitch, int yaw, int x, int y, int z){
    this.roll = roll;
    this.pitch = pitch;
    this.yaw = yaw;
    
    // all really +-8g but values are doubled because that's how imu did it.
    // Also multiplied by 100 so using ints instead of floats
    this.x = x;
    this.y = y;
    this.z = z;
    
    mag = sqrt((x*x) + (y*y) + (z*z));
  }
  
  boolean isUp(){
    float upPercent = 0.90; // percent upComp must be of accel mag to count as up
    int upThresh = 10; // magnitude required in up direction to say it's up
        
    if(stateManager.upPossible()){
      PVector[] rotatedAxes = rotateAxes(roll, -pitch);
      PVector globalAccel = getUpComp(rotatedAxes); // accel with actual x,y,z comps ie z points up and down in global space
      float upComp = globalAccel.z;
      mag = globalAccel.mag();
      if(abs(upComp) > upThresh && (abs(upComp)/mag > upPercent)){
        return true;
      } else {
        return false;
      }
    } // if statemanager
    else {
      return false;
    }
  }
  
  PVector[] rotateAxes(int Ax, int Ay){
    PVector[] axes = {new PVector(1,0,0), new PVector(0,1,0), new PVector(0,0,1)};
    axes = rotateAxesX3D(Ax, axes);
    axes = rotateAxesY3D(Ay, axes);
    return axes;
  }
  
  PVector[] rotateAxesX3D(int theta, PVector[] axes){
    float sinTheta = sin(radians(theta));
    float cosTheta = cos(radians(theta));
      
    for(int i = 0; i < axes.length; i++){
      PVector axis = axes[i];
      float axy = axis.y;
      float axz = axis.z;     
      axis.y = axy * cosTheta - axz * sinTheta;
      axis.z = axz * cosTheta + axy * sinTheta;
    }
    return axes;
  }
  
  PVector[] rotateAxesY3D(int theta, PVector[] axes) {
    float sinTheta = sin(radians(theta));
    float cosTheta = cos(radians(theta));
    
    for (int i = 0; i<axes.length; i++) {
        PVector axis = axes[i];
        float axx = axis.x;
        float axz = axis.z;
        axis.x = axx * cosTheta - axz * sinTheta;
        axis.z = axz * cosTheta + axx * sinTheta;
    }
    return axes;
  }
    
}