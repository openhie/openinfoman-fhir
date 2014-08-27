import module namespace fadpt = "https://github.com/openhie/openinfoman/adapter/fhir";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
declare namespace csd =  "urn:ihe:iti:csd:2013";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 


let $search_name := "urn:ihe:iti:csd:2014:stored-function:provider-search"
let $doc_name := $careServicesRequest/@resource
let $format := 
  if ($careServicesRequest/_format) 
  then  string($careServicesRequest/_format) 
  else 'application/xml+fhir'

let $careServicesSubRequest :=  
  <csd:careServicesRequest>
    <csd:function urn="{$search_name}" resource="{$doc_name}">
     <requestParams>{$careServicesRequest/*}</requestParams>
    </csd:function>
  </csd:careServicesRequest>

 
let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, $doc, $careServicesSubRequest)
   (:note this is a CSD:csd element, not a document :)


return
  if ($format = ('application/json+fhir' ,  'application/json' ,'json'))
  then 
    let $entities := 
      for $provider in $contents/csd:providerDirectory/csd:provider
      return fadpt:represent_provider_as_practitioner_JSON($doc,$provider) 
    return fadpt:create_feed_from_entities_JSON($entities,$careServicesRequest)
  else
     let $entities := 
       for $provider in $contents/csd:providerDirectory/csd:provider
       return fadpt:represent_provider_as_practitioner($doc,$provider) 
     return fadpt:create_feed_from_entities($entities,$careServicesRequest)




