/*
A bunch of maps and classes that map Command to draw functionality
*/

/*
Setup all maps in here
*/
void setupCommandToDraw(){
  setupCommandDrawMap();
  setupCommandColourMap();
  setupCommandToolMap();
}

/*---------- COMMAND DRAW MAP ----------*/

/* 
Map the name field of command to CommandType
*/
public class CommandDrawMap extends HashMap<String, CommandType> {}

CommandDrawMap commandDrawMap;

void setupCommandDrawMap(){
  commandDrawMap = new CommandDrawMap();
  
  // colours
  commandDrawMap.put("red", CommandType.CHANGECOLOUR);
  commandDrawMap.put("orange", CommandType.CHANGECOLOUR);
  commandDrawMap.put("yellow", CommandType.CHANGECOLOUR);
  commandDrawMap.put("green", CommandType.CHANGECOLOUR);
  commandDrawMap.put("blue", CommandType.CHANGECOLOUR);
  commandDrawMap.put("violet", CommandType.CHANGECOLOUR);
  commandDrawMap.put("black", CommandType.CHANGECOLOUR);
  commandDrawMap.put("white", CommandType.CHANGECOLOUR);
  
  // modify stack
  commandDrawMap.put("clear", CommandType.MODIFYSTACK);
  commandDrawMap.put("undo", CommandType.MODIFYSTACK);
  commandDrawMap.put("redo", CommandType.MODIFYSTACK);
  
  // copy paste
  commandDrawMap.put("copy", CommandType.COPYPASTE);
  commandDrawMap.put("paste", CommandType.COPYPASTE);
}

/*---------- COMMAND COLOUR MAP ----------*/

/* 
Map the name field of command to an array {r,g,b} for the colour
*/
public class CommandColourMap extends HashMap<String, int[]> {}

CommandColourMap commandColourMap;

void setupCommandColourMap(){
  commandColourMap = new CommandColourMap();
  
  int[] red = {255,0,0};
  int[] orange = {255,165,0};
  int[] yellow = {255,255,0};
  int[] green = {0,255,0};
  int[] blue = {0,0,255};
  int[] violet = {238,130,238};
  int[] black = {0,0,0};
  int[] white = {255,255,255};
  commandColourMap.put("red", red);
  commandColourMap.put("orange", orange);
  commandColourMap.put("yellow", yellow);
  commandColourMap.put("green", green);
  commandColourMap.put("blue", blue);
  commandColourMap.put("violet", violet);
  commandColourMap.put("black", black);
  commandColourMap.put("white", white);  
}

/*---------- COMMAND TOOL MAP ----------*/

/*
Container class to hold tool and size info - used in CommandToolMap
*/
class ToolAndSize{
  Tool tool;
  int strokeW;
  
  ToolAndSize(Tool tool, int strokeW){
    this.tool = tool;
    this.strokeW = strokeW;
  }
}

public class CommandToolMap extends HashMap<String, ToolAndSize>{}

CommandToolMap commandToolMap;

void setupCommandToolMap(){
  commandToolMap = new CommandToolMap();
  
  // pen
  commandToolMap.put("pen1", new ToolAndSize(Tool.PEN, 1));
  commandToolMap.put("pen2", new ToolAndSize(Tool.PEN, 3));
  commandToolMap.put("pen3", new ToolAndSize(Tool.PEN, 10));
  commandToolMap.put("pen4", new ToolAndSize(Tool.PEN, 20));
  
  // paint
  commandToolMap.put("brush1", new ToolAndSize(Tool.PAINT, 5));
  commandToolMap.put("brush2", new ToolAndSize(Tool.PAINT, 10));
  commandToolMap.put("brush3", new ToolAndSize(Tool.PAINT, 15));
  commandToolMap.put("brush4", new ToolAndSize(Tool.PAINT, 20));
  
  // eraser
  commandToolMap.put("eraser1", new ToolAndSize(Tool.ERASER, 5));
  commandToolMap.put("eraser2", new ToolAndSize(Tool.ERASER, 10));
  commandToolMap.put("eraser3", new ToolAndSize(Tool.ERASER, 20));
  
  // clear
  commandToolMap.put("clear", new ToolAndSize(Tool.CLEAR, 1)); // size here doesn't matter
}

/*---------- ICONS FOR FEEDBACK ----------*/

class Icon{
  PImage img; // image for icon
  float x; // location x
  float y; // location y
  float alpha; // transparency
  
  Icon(PImage img, float x, float y){
    this.img = img;
    this.x = x;
    this.y = y;
    alpha = 255; // start off fully opaque
  }
  
  /*
  Draws the icon in its current location with its current alpha
  */
  void draw(){
    tint(255, alpha); // the first 255 means it won't change the colour of the image
    image(img, x, y);
    // reset to full opacity for other images that draw
    tint(255, 255);
  }
}
