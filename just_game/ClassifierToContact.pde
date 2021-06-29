/*
Maps the classifier ints to Contacts
and creates a Contact to classifier map (the reverse)
*/

public class ClassifierContactMap extends HashMap<Integer, Contact> {}
public class ContactClassifierMap extends HashMap<Contact, Integer>{}

ClassifierContactMap classToContact;
ContactClassifierMap contactToClass;

void setupClassifierToContact() {
  
  classToContact = new ClassifierContactMap(); 
  
  // large side and edges (menu top)  
  classToContact.put(Classifier.greenYellowEdge, Contact.LE1);
  classToContact.put(Classifier.greenSide, Contact.LS1);
  classToContact.put(Classifier.greenPurpleEdge, Contact.LE2);

  // large side and edges (menu bottom)
  classToContact.put(Classifier.pinkYellowEdge, Contact.LE4);
  classToContact.put(Classifier.pinkSide, Contact.LS2);
  classToContact.put(Classifier.pinkPurpleEdge, Contact.LE3);

  // medium sides
  classToContact.put(Classifier.yellowSide, Contact.MS1);
  classToContact.put(Classifier.purpleSide, Contact.MS2);

  // white end
  classToContact.put(Classifier.whiteSide, Contact.W);

  // corners
  classToContact.put(Classifier.greenYellowWhiteCorner, Contact.WC1);
  classToContact.put(Classifier.greenPurpleWhiteCorner, Contact.WC2);  
  classToContact.put(Classifier.pinkYellowWhiteCorner, Contact.WC4);
  classToContact.put(Classifier.pinkPurpleWhiteCorner, Contact.WC3);  

  // short edges
  classToContact.put(Classifier.yellowWhiteEdge, Contact.WSE1); 
  classToContact.put(Classifier.purpleWhiteEdge, Contact.WSE2);

  // medium edges
  classToContact.put(Classifier.greenWhiteEdge, Contact.WME1);
  classToContact.put(Classifier.pinkWhiteEdge, Contact.WME2);

  // black end
  classToContact.put(Classifier.blackSide, Contact.B);

  // corners
  classToContact.put(Classifier.greenPurpleBlackCorner, Contact.BC2);
  classToContact.put(Classifier.greenYellowBlackCorner, Contact.BC1);  
  classToContact.put(Classifier.pinkPurpleBlackCorner, Contact.BC3);
  classToContact.put(Classifier.pinkYellowBlackCorner, Contact.BC4);  

  // short edges
  classToContact.put(Classifier.purpleBlackEdge, Contact.BSE2); 
  classToContact.put(Classifier.yellowBlackEdge, Contact.BSE1);

  // medium edges
  classToContact.put(Classifier.greenBlackEdge, Contact.BME1);
  classToContact.put(Classifier.pinkBlackEdge, Contact.BME2);  
  
}

void setupContactToClassifier() {  
  contactToClass = new ContactClassifierMap(); 
  for(Map.Entry entry : classToContact.entrySet()){
    contactToClass.put((Contact)entry.getValue(), (Integer)entry.getKey());
  }
}

/*
Calls both
*/
void linkClassifierToContact(){
  setupClassifierToContact();
  setupContactToClassifier();
}
