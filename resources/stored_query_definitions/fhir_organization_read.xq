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
 
let $search_name := "urn:ihe:iti:csd:2014:stored-function:organization-search"

let $careServicesSubRequest :=  
  <csd:careServicesRequest>
    <csd:function urn="{$search_name}" resource="{$careServicesRequest/@resource}" base_url="{$careServicesRequest/@base_url}">
      <csd:requestParams>
         {
	  let $id := $careServicesRequest/fhir:_id/text()
	  return if (functx:all-whitespace($id)) then () else <csd:id entityID="{$id}"/>
	 }
         {
	  let $cn := $careServicesRequest/fhir:name/text()
	  return if (functx:all-whitespace($cn)) then () else <csd:primaryName>{$cn}</csd:primaryName> 
	 }
	 {
	  let $org := string($careServicesRequest/fhir:partOf/@value)
	  return if (functx:all-whitespace($org)) then () else  <csd:parent>{$org}</csd:parent> 
	 }

         {
	  let $t_start := $careServicesRequest/page/text()
	  return if (functx:is-a-number($t_start))
	    then
	      let $start := max((xs:int($t_start),1))
	      let $t_count := $careServicesRequest/fhir:_count/text()
	      let $count := if(functx:is-a-number($t_count)) then  max((xs:int($t_count),1)) else 50
	      let $startIndex := ($start - 1)*$count + 1
	      return <csd:start>{$startIndex}</csd:start>
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
	  return if ($since) then <csd:record updated="{$since}"/> else () 
	 }
      </csd:requestParams>
    </csd:function>
  </csd:careServicesRequest>

 
let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, /. , $careServicesSubRequest)

   (:note this is a CSD:csd element, not a document :)
return $contents/csd:organizationDirectory/csd:organization




