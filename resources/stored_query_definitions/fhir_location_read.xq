import module namespace csd_bl = "https://github.com/openhie/openinfoman/csd_bl";
declare namespace csd =  "urn:ihe:iti:csd:2013";
declare namespace fhir = "http://hl7.org/fhir";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 


let $represent_facility_as_location := function($doc,$facility)
{
  (: See http://www.hl7.org/implement/standards/fhir/location.html :)
  <fhir:Location >
    <fhir:identifier>{string($facility/@oid)}</fhir:identifier>
    <fhir:name>{($facility/csd:primaryName)[1]/text()}</fhir:name>    
    {
      (
       (: Note: nothing readily apparent for description :)
       (:Note:  FHIR allows only one facility type:)
       for $type in  ($facility/csd:codedType)[1] 
       return  <fhir:type><fhir:coding><fhir:system>{string($type/@codingScheme)}</fhir:system><fhir:code>{string($type/@code)}</fhir:code></fhir:coding></fhir:type>
       ,
       for $contact in  $facility/csd:contactPoint/csd:codedType
       return  <fhir:telecom>{$contact/text()}</fhir:telecom>
       ,
       (: Note: address is a bit weird.. which address? FHIR only allows for one. In CSD a provider 
          can have a practice address as well as be assocaited to multiple facilities, each with their own address:)
       let $address :=  ($facility/csd:address[@type='Practice'])[1]
       return 
	 if (exists($address))
	 then
	   <fhir:address>
	     {for $al in $address/csd:addressLine 
	       return concat(string($al/@component) , ": ", $al/text(), "&#10;")
	     }
           </fhir:address>
	 else ()
	,
        (: Note: nothing immediate for Physical type :)
	if (exists($facility/csd:geocode)) then
	  <fhir:position>
	    <fhir:longitude>{$facility/csd:geocode/csd:longitude}</fhir:longitude>
	    <fhir:latitude>{$facility/csd:geocode/csd:latitude}</fhir:latitude>
	    <fhir:altitude>{$facility/csd:geocode/csd:altitude}</fhir:altitude>
	  </fhir:position>
	else ()
	,
	(:  Note: FHIR only permits one managinh organization but CSD has many :)
	for $org in ($facility/csd:organizations/csd:organization)[1]
	   (: Note: base for URL for reference should maybe be handled by stored function extension metadata   :)
	   return <fhir:managingOrganization><fhir:reference>Organization/{string($org/@oid)}</fhir:reference></fhir:managingOrganization>
	,
	(:May need to map codes :)
        <fhir:status>{string($facility/csd:record/@status)}</fhir:status>
	(:Note nothing immediately obvious for FHIR partOf or for FHIR mode :)
     )
    }
      
  </fhir:Location>
}



let $facilities := /csd:CSD/csd:facilityDirectory/csd:facility

return 
  <atom:feed>
    <atom:title>CSD Facility as FHIR Location</atom:title>
    <atom:id>urn:uuid:b248b1b2-1686-4b94-9936-37d7a5f94b51</atom:id> 
    <atom:link href="http://www.hl7.org/fhir/patient-examples.xml" rel="self"/>
    <atom:updated>2012-05-29T23:45:32Z</atom:updated>
    <atom:content>
     {
       for $facility in $facilities
       return 
       <atom:entry>
         {$represent_facility_as_location(/.,$facility) }
       </atom:entry>
     }
     </atom:content>
  </atom:feed>