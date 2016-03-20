import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace functx = 'http://www.functx.com';

declare namespace csd =  "urn:ihe:iti:csd:2013";
declare namespace fhir = "http://hl7.org/fhir";
declare variable $careServicesRequest as item() external;

let $org_id := $careServicesRequest/fhir:_id/text()
let $search_name := string($careServicesRequest/@function)
let $resource := string($careServicesRequest/@resource)

let $function := csr_proc:get_function_definition($search_name)
let $entity :=   string(($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:valueset' ])[1]/@type)


let $t_base_url := 
  if (exists($careServicesRequest/@xml:base))
  then string($careServicesRequest/@xml:base)
  else string($careServicesRequest/@base_url)


let $base_url :=
  concat($t_base_url, "CSD/csr/", $resource, "/careServicesRequest/" , $search_name , "/adapter/fhir/" , $entity , "/valueset" )

let $expand := 
    (exists($careServicesRequest/fhir:_query)
    and matches(functx:trim(($careServicesRequest/fhir:_query)[1]/text()),'expand','i')
    )
      


let $org := (/csd:CSD/csd:organizationDirectory/csd:organization[@entityID = $org_id])[1]
let $child_orgs := /csd:CSD/csd:organizationDirectory/csd:organization[ ./csd:parent[@entityID = $org_id]]
let $child_facs := /csd:CSD/csd:facilityDirectory/csd:facility[ ./csd:organizations/csd:organization[@entityID = $org_id]]
let $org_name := ($org/csd:primaryName)[1]/text()


return
  if (exists($org) ) 
  then
    <fhir:ValueSet>
      <fhir:text>
	<fhir:status value="generated"/>
	<div xmlns="http://www.w3.org/1999/xhtml">
	  <h2>Value Set {$org_id}</h2>
	  <h3>Valueset {$entity}: {$org/csd:primaryName/text()}</h3>
	  {
	    let $parent := (/csd:CSD/csd:organizationDirectory/csd:organization[@entityID = $org/csd:parent/@entityID ])[1]
	    return 
	       if (exists($parent))
	       then
	         <span class='vs_parent'>
		   <p>Parent Oraganization (Imports this value set): </p>
		   <a href="{$base_url}?_id={$parent/@entityID}">{string($parent/@entityID)}</a>{$parent/csd:primaryName}
		 </span>
	       else()
	  }
	  {
	    if (count($child_orgs) > 0)
	    then
	      <span class='vs_child'>
	       <p>
  	         Child Organizatons (Imported Value Sets):
	       </p>
	       <ul>
	         {
		   for $child_org in $child_orgs
		   return <li><a href="{$base_url}?_id={$child_org/@entityID}">{string($child_org/@entityID)}</a>{$child_org/csd:primaryName}</li>
		 }
	       </ul>
	      </span>
	    else ()
	    
	  }
	  {
	    if (count($child_facs) > 0)
	    then 
	      <span class='vs_facs'>
	        <p>
	          Facility codes directly defined by this code set:
		</p>
	        <ul>
		  {
		     for $child_fac in $child_facs
		     return <li>Value: {string($child_fac/@entityID)} is {$child_fac/csd:primaryName/text()} </li>
		  }
		</ul>
	      </span>
	    else ()

	  }
	</div>
      </fhir:text>
      <fhir:identifier value="{$base_url}?_id={$org_id}"/>
      <fhir:version value="0"/>
      <fhir:name>Organization: {$org_name}</fhir:name>
      <fhir:status value="active"/>      
      <fhir:date>{string($org/csd:record/@lastModified)}</fhir:date>
      <fhir:define>

        <fhir:system value="{$base_url}?_id={$org_id}"/>
        <fhir:version value="0"/>
	<fhir:caseSensitive value="true"/>

	{
	  for $child_fac in $child_facs
	  let $fac_name := ($child_fac/csd:primaryName[1])/text()
	  let $definition := out:format("%s in %s", $fac_name,$org_name)
	  let $value := string($child_fac/@entityID)
	  where (not (functx:all-whitespace($value)) and not (functx:all-whitespace($fac_name)))
	  return 
	    <fhir:concept>
	      <fhir:code value="{$value}"/>
	      <fhir:display value="{$fac_name}"/>
	      <fhir:definition value="{$definition}"/>
	    </fhir:concept>
	}
      </fhir:define>
      {
	if(not($expand) ) 
	then
  	  <fhir:compose>
            {
	      for $child_org in $child_orgs
	      let $child_id := string($child_org/@entityID)
	      where not (functx:all-whitespace($child_id))
	      return <fhir:import value="{$base_url}?_id={$child_id}"/>
	    }
	  </fhir:compose>    
	 else  ()

        }
    </fhir:ValueSet>
  else $careServicesRequest