import java.io.PrintStream;
import java.io.OutputStream;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.model.dstu2.resource.Communication;
import ca.uhn.fhir.model.dstu2.resource.Bundle;
import ca.uhn.fhir.parser.IParser;
import ca.uhn.fhir.parser.StrictErrorHandler;
import ca.uhn.fhir.parser.DataFormatException;
//import ca.uhn.fhir.validation.FhirValidator;
//import ca.uhn.fhir.validation.ValidationResult;

public class hapi_transformer {
    public String transform(String resourceBody,String start,String type) {

        PrintStream orig = System.out;
        System.setOut(System.err);
        // Create a context

        FhirContext ctx = FhirContext.forDstu2();

        ctx.setParserErrorHandler(new StrictErrorHandler());

        //FhirValidator val = ctx.newValidator();

        // Create a XML parser
        IParser xmlParser = ctx.newXmlParser();
        // Create a JSON parser
        IParser jsonParser = ctx.newJsonParser();
    
        String encode = "";


        if ( type.equals("Communication") ) {
            Communication comm;
            if ( start.equals( "xml" ) ) {
                try {
                    comm = xmlParser.parseResource(Communication.class, resourceBody );
                    //ValidationResult result = val.validateWithResult( comm );
                    //if ( !result.isSuccessful() ) {
                        //System.exit(1);
                    //}
                 	  jsonParser.setPrettyPrint(true);
                    encode = jsonParser.encodeResourceToString(comm);
                } catch ( DataFormatException dfe ) {
                    System.exit(1);
                }
            } else {
                try {
                    comm = jsonParser.parseResource(Communication.class, resourceBody );
                    //ValidationResult result = val.validateWithResult( comm );
                    //if ( !result.isSuccessful() ) {
                    //System.exit(1);
                    //}
                    xmlParser.setPrettyPrint(true);
                    encode = xmlParser.encodeResourceToString(comm);
                } catch ( DataFormatException dfe ) {
                    System.out.println( dfe.getMessage() );
                    System.exit(1);
                }
            }
        } else if ( type.equals("Bundle") ) {
            Bundle bundle;
            if ( start.equals( "xml" ) ) {
                try {
                    bundle = xmlParser.parseResource(Bundle.class, resourceBody );
                    jsonParser.setPrettyPrint(true);
                    encode = jsonParser.encodeResourceToString(bundle);
                } catch ( DataFormatException dfe ) {
                    System.exit(1);
                }
            } else {
                try {
                    bundle = jsonParser.parseResource(Bundle.class, resourceBody );
                    xmlParser.setPrettyPrint(true);
                    encode = xmlParser.encodeResourceToString(bundle);
                } catch ( DataFormatException dfe ) {
                    System.out.println( dfe.getMessage() );
                    System.exit(1);
                }
            }
         }
        return encode;
        
    }
}
