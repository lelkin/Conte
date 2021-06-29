public class ContactCommandMap extends HashMap<Contact, Command> {}


ContactCommandMap commands;

// assign commands to contacts
void setupCommands() {
  
  commands = new ContactCommandMap(); 
  
  // large side and edges (menu top)  
  commands.put(Contact.LE1, new Command("red", false));
  commands.put(Contact.LS1, new Command("orange", false));
  commands.put(Contact.LE2, new Command("yellow", false));

  // large side and edges (menu bottom)
  commands.put(Contact.LE3, new Command("green", false));
  commands.put(Contact.LS2, new Command("blue", false));
  commands.put(Contact.LE4, new Command("violet", false));

  // medium sides
  commands.put(Contact.MS1, new Command("black", false));
  commands.put(Contact.MS2, new Command("white", false));

  // white end
  commands.put(Contact.W, new Command("open", false));

  // corners
  commands.put(Contact.WC1, new Command("pen1", true));
  commands.put(Contact.WC2, new Command("pen2", true));
  commands.put(Contact.WC3, new Command("pen3", true));
  commands.put(Contact.WC4, new Command("pen4", true));    


  // short edges
  commands.put(Contact.WSE1, new Command("eraser1", true)); 
  commands.put(Contact.WSE2, new Command("eraser3", true));

  // medium edges
  commands.put(Contact.WME1, new Command("eraser2", true));
  commands.put(Contact.WME2, new Command("clear", false));

  // black end
  commands.put(Contact.B, new Command("save", false));

  // corners
  commands.put(Contact.BC1, new Command("brush2", true)); 
  commands.put(Contact.BC2, new Command("brush1", true)); 
  commands.put(Contact.BC3, new Command("brush4", true)); 
  commands.put(Contact.BC4, new Command("brush3", true)); 

  // short edges
  commands.put(Contact.BSE1, new Command("redo", false));
  commands.put(Contact.BSE2, new Command("undo", false)); 


  // medium edges
  commands.put(Contact.BME1, new Command("paste", false));
  commands.put(Contact.BME2, new Command("copy", false));    
}

class Command {

  // 64 x 64 px icon image
  PImage img;

  // Command name
  String name;
  
  // true if command draws, false if it's just used to select
  boolean drawCmd;

  // iconFileName is without png suffix
  Command(String iconFilename, boolean drawCmd) {

    name = iconFilename;
    println("loading icon for " + name);
    img = loadImage(iconFilename + ".png");
    this.drawCmd = drawCmd;
  }

  // draw command icon centred at location
  void draw(float x, float y) {
    if (img != null) {
      imageMode(CENTER);
      image(img, x, y);
      imageMode(CORNER);
    } else {
      rectMode(CENTER);
      noFill();
      stroke(#FF0000);
      rect(x, y, 64, 64);
      fill(#FF0000);
      textAlign(CENTER);
      text(name, x, y);
      rectMode(CORNER);
    }
  }
}