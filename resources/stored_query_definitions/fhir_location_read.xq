import module namespace fadpt = "https://github.com/openhie/openinfoman/adapter/fhir";
declare namespace csd =  "urn:ihe:iti:csd:2013";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 



let $id := $careServicesRequest/id/text()
let $facilities := 
  if ($id) 
    then
      /csd:CSD/csd:facilityDirectory/csd:facility[@urn = $id]
    else
      /csd:CSD/csd:facilityDirectory/csd:facility

let $entities :=        
   for $facility in $facilities
       return fadpt:represent_facility_as_location(/.,$facility) 


return fadpt:create_feed_from_entities($entities,$careServicesRequest)

