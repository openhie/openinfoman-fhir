import module namespace fadpt = "https://github.com/openhie/openinfoman/adapter/fhir";
declare namespace csd =  "urn:ihe:iti:csd:2013";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 



let $id := $careServicesRequest/id/text()
let $providers :=
  if ($id) 
    then
      /csd:CSD/csd:providerDirectory/csd:provider[@oid = $id]
    else
      /csd:CSD/csd:providerDirectory/csd:provider


let $entities :=        
  for $provider in $providers
  return 
    fadpt:represent_provider_as_practitioner(/.,$provider) 

return fadpt:create_feed_from_entities($entities,$careServicesRequest)


