//import weka.classifiers.Classifier;
import weka.core.Attribute;
import weka.core.DenseInstance;
import weka.core.Instance;
import weka.core.Instances;

// Classifies points based on accelerometer data

Classifier classifier;

class Classifier{
  // contact points
  // when multiple sides are listed, the physically largest goes first
  static final int blackSide = 0;
  static final int whiteSide = 1;
  static final int yellowSide = 2;
  static final int purpleSide = 3;
  static final int pinkSide = 4;
  static final int greenSide = 5;
  static final int pinkYellowWhiteCorner = 6;
  static final int greenYellowWhiteCorner = 7;
  static final int greenPurpleWhiteCorner = 8;
  static final int pinkPurpleWhiteCorner = 9;
  static final int pinkYellowBlackCorner = 10;
  static final int greenYellowBlackCorner = 11;
  static final int greenPurpleBlackCorner = 12;
  static final int pinkPurpleBlackCorner = 13;
  static final int yellowBlackEdge = 14;
  static final int purpleBlackEdge = 15;
  static final int yellowWhiteEdge = 16;
  static final int purpleWhiteEdge = 17;
  static final int pinkPurpleEdge = 18;
  static final int pinkYellowEdge = 19;    
  static final int greenYellowEdge = 20;
  static final int greenPurpleEdge = 21;
  static final int greenBlackEdge = 22;
  static final int pinkBlackEdge = 23;
  static final int greenWhiteEdge = 24;
  static final int pinkWhiteEdge = 25;
  static final int unclassified = 26; // been calculated but is inconclusive
  static final int pending = 27; // has no been calculated yet
  
  // points that we can draw from
  // should probably change this to be a property of the classification type...maybe
  final List<Integer> drawPointsArr = Arrays.asList(Classifier.greenPurpleBlackCorner, 
                          Classifier.greenYellowBlackCorner, Classifier.yellowBlackEdge, Classifier.pinkYellowBlackCorner, 
                          Classifier.pinkPurpleBlackCorner, Classifier.purpleBlackEdge, Classifier.greenPurpleWhiteCorner, 
                          Classifier.greenYellowWhiteCorner, Classifier.yellowWhiteEdge, Classifier.pinkYellowWhiteCorner, 
                          Classifier.pinkPurpleWhiteCorner, Classifier.purpleWhiteEdge); 
  final Set<Integer> drawPoints = new HashSet<Integer>(drawPointsArr);
  
  // Weka
  Instances data;
  weka.classifiers.Classifier cls = null;
    
  Classifier(){
    setupWeka();
  }
  
  /*
  Sets up the Weka instances object and the classifier
  */
  void setupWeka(){
    
    // Instances
    Contact[] allContacts = Contact.values();
    ArrayList<String> classVal = new ArrayList<String>();
    for (Contact c : allContacts){
      classVal.add(c.name());
    }
  
    ArrayList<Attribute> attributeList = new ArrayList<Attribute>();  
    Attribute Roll = new Attribute("Roll");
    Attribute Pitch = new Attribute("Pitch");
    Attribute Yaw = new Attribute("Yaw");
    attributeList.add(Roll);
    attributeList.add(Pitch);
    attributeList.add(Yaw);
    attributeList.add(new Attribute("@@class@@", classVal));
  
    data = new Instances("TestInstances",attributeList,0);
    data.setClassIndex(data.numAttributes() - 1);
    
    try{
    // Classifier
    cls = (weka.classifiers.Classifier) weka.core.SerializationHelper.read(dataPath("lisa_wifi_with_outliers_first_second_third.model"));
    } catch(Exception e){
      println("EXCEPTION");
      println(e.getMessage());
    }
  }
  
  /* Classifies contact point based on accelAndAngles
  Input: roll, pitch, and yaw are as they came in from accelerometer
  Output: int corresponding to classification. See above for values
  */
  int classifyData(int roll, int pitch, int yaw){
    // create instance
    Instance inst = new DenseInstance(data.numAttributes());
    inst.setDataset(data);
    inst.setValue(0, roll);
    inst.setValue(1, pitch);
    inst.setValue(2, yaw);
    
    try{
      double result = cls.classifyInstance(inst);
      String resultStr = data.classAttribute().value((int)result);
      Contact resultContact = Contact.valueOf(resultStr);
      return contactToClass.get(resultContact);
    } catch(Exception e){
      println("EXCEPTION");
      println(e.getMessage());
    }
    return unclassified;
  }
  
  /*
  Returns the string version of the classification
  Input: Int corresponding to classification
  Output: String version
  eg: classificationToString(2) = "yellow side"
  */
  String classificationToString(int classification){
    switch(classification){
      case blackSide:
        return "black side";
      case whiteSide:
        return "white side";
      case yellowSide:
        return "yellow side";
      case purpleSide:
        return "purple side";
      case pinkSide:
        return "pink side";
      case greenSide:
        return "green side";
      case pinkYellowWhiteCorner:
        return "pink yellow white corner";
      case greenYellowWhiteCorner:
        return "green yellow white corner";
      case greenPurpleWhiteCorner:
        return "green purple white corner";      
      case pinkPurpleWhiteCorner:
        return "pink purple white corner";
      case pinkYellowBlackCorner:
        return "pink yellow black corner";
      case greenYellowBlackCorner:
        return "green yellow black corner";
      case greenPurpleBlackCorner:
        return "green purple black corner";
      case pinkPurpleBlackCorner:
        return "pink purple black corner";
      case yellowBlackEdge:
        return "yellow black edge";
      case purpleBlackEdge:
        return "purple black edge";
      case yellowWhiteEdge:
        return "yellow white edge";
      case purpleWhiteEdge:
        return "purple white edge";
      case pinkPurpleEdge:
        return "pink purple edge";
      case pinkYellowEdge:
        return "pink yellow edge";
      case greenYellowEdge:
        return "green yellow edge";
      case greenPurpleEdge:
        return "green purple edge";
      case greenBlackEdge:
        return "green black edge";
      case pinkBlackEdge:
        return "pink black edge";
      case greenWhiteEdge:
        return "green white edge";
      case pinkWhiteEdge:
        return "pink white edge";
      case unclassified:
        return "unclassified";
      case pending:
        return "pending";
    }
    return "";
  }
}