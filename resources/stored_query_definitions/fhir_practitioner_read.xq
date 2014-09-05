import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace fadpt = "https://github.com/openhie/openinfoman/adapter/fhir";
import module namespace functx = 'http://www.functx.com';

declare namespace csd =  "urn:ihe:iti:csd:2013";
declare namespace fhir = "http://hl7.org/fhir";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 
 
let $search_name := "urn:ihe:iti:csd:2014:stored-function:provider-search"

let $careServicesSubRequest :=  
  <csd:careServicesRequest>
    <csd:function urn="{$search_name}" resource="{$careServicesRequest/@resource}">
      <csd:requestParams>
         {
	  let $id := $careServicesRequest/fhir:_id/text()
	  return if (functx:all-whitespace($id)) then () else <csd:id>{$id}</csd:id> 
	 }
         {
	  let $cn := $careServicesRequest/fhir:name/fhir:text/text()
	  return if (functx:all-whitespace($cn)) then () else <csd:commonName>{$cn}</csd:commonName>
	 }
	 {
	  let $org := string($careServicesRequest/fhir:organization/@value)
	  return if (functx:all-whitespace($org)) then () else  <csd:organizations><csd:organization>{$org}</csd:organization></csd:organizations> 
	 }

	 {
	  let $loc := string($careServicesRequest/fhir:location/@value)
	  return if (functx:all-whitespace($loc)) then () else <csd:facilities><csd:facility>{$loc}</csd:facility></csd:facilities> 
	 }

         {
	  let $t_start := $careServicesRequest/page/text()
	  return if (functx:is-a-number($t_start))
	    then
	      let $start := max((xs:int($t_start),1))
	      let $t_count := $careServicesRequest/fhir:_count/text()
	      let $count := if(functx:is-a-number($t_count)) then  max((xs:int($t_count),1)) else 50
	      let $startIndex := ($start - 1)*$count + 1
	      return <csd:start>{xs:string($startIndex)}</csd:start>
	    else () 
	 }
         {
	   let $count := $careServicesRequest/fhir:_count/text()
	   return 
	      if(functx:is-a-number($count)) 
	      then <csd:max>{max(($count,1))} </csd:max>
	      else ()
	 }
	 {
	  let $since := $careServicesRequest/fhir:_since/text()
	  return if (functx:all-whitespace($since)) then () else <csd:record updated="{$since}"/> 
	 }
      </csd:requestParams>
    </csd:function>
  </csd:careServicesRequest>

 
let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, /. , $careServicesSubRequest)

   (:note this is a CSD:csd element, not a document :)
return $contents/csd:providerDirectory/csd:provider




