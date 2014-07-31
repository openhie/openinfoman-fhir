(:~
: This is the Care Services Discovery stored query registry
: @version 1.1
: @see https://github.com/openhie/openinfoman
:
:)
module namespace fadpt = "https://github.com/openhie/openinfoman/adapter/fhir";



(:Import other namespaces.  Set default namespace  to os :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";

declare namespace csd = "urn:ihe:iti:csd:2013";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace fhir = "http://hl7.org/fhir";


declare function fadpt:is_fhir_function($search_name) {
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $ext := $function//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter' and @type='fhir']
  return (count($ext) > 0) 
};


declare function fadpt:has_feed($search_name,$doc_name) {
  (fadpt:is_fhir_function($search_name) and csd_dm:is_registered($csd_webconf:db ,$doc_name))
};

declare function fadpt:get_base_url($search_name) {
  fadpt:get_base_url($search_name,$csd_webconf:baseurl)
};
declare function fadpt:get_base_url($search_name,$base_url) {
  concat($base_url,'CSD/adapter/fhir/' ,$search_name)
};



declare function fadpt:create_feed_from_entities($entities,$requestParams) {
  let $search_name := string($requestParams/@function)
  let $doc_name := string($requestParams/@resource)
  let $base_url := string($requestParams/@base_url)
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $entity := string($function/csd:extension[ @urn='urn:openhie.org:openinfoman:adapter:fhir' and position() = 1]/@type)
  let $link := concat(fadpt:get_base_url($search_name,$base_url),'/' , $doc_name ,'/',$entity )
  let $title := "CSD entity as FHIR {$entity} "
  return 
  <atom:feed>
    <atom:title>{$title}</atom:title>
    <atom:link href="{$link}" rel="self"/>
    <atom:updated>{current-dateTime()}</atom:updated>
    <atom:content>
     {
       for $entity in $entities
       return <atom:entry>{$entity}</atom:entry>
     }
     </atom:content>
  </atom:feed>

};



(:
   Function to turn a CSD Facility entity into a FHIR Location
:)

declare function fadpt:represent_facility_as_location($doc,$facility)
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
};



(:
   Function to turn a CSD Provider entity into a FHIR Practitioner
:)

declare function fadpt:represent_provider_as_practitioner($doc,$provider) 
{
  (: See http://www.hl7.org/implement/standards/fhir/practitioner.html :)
  <fhir:Practitioner >
    <fhir:identifier>{string($provider/@oid)}</fhir:identifier>
    {
	let $name := ($provider/csd:demographic/csd:name)[1]
	let $cn := ($name/csd:commonName)[1]/text()
	let $sn := ($name/csd:surname)[1]/text()
	let $gn := ($name/csd:forename)[1]/text()
	let $hon := ($name/csd:honorific)[1]/text()
	return
	  <fhir:name>
	    <fhir:text value="{$cn}"/>
	    <fhir:family value="{$sn}"/>
	    <fhir:given value="{$gn}"/>
	    <fhir:prefix value="{$hon}"/>	  
	  </fhir:name>
    }
    {
      (
       for $contact in  $provider/csd:demographic/csd:contactPoint/csd:codedType
       return  <fhir:telecom>{$contact/text()}</fhir:telecom>
       ,
       (: Note: address is a bit weird.. which address? FHIR only allows for one. In CSD a provider 
          can have a practice address as well as be assocaited to multiple facilities, each with their own address:)
       let $address :=  ($provider/csd:demographic/csd:address[@type='Practice'])[1]
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
	(: Note: what code set should we use in our output? :) 
	let $gender := ($provider/csd:demographic/csd:gender)[1]
	return 
	  if (exists($gender))  then  <fhir:gender>{$gender/text()}</fhir:gender>
	  else ()
	,
	let $dob := ($provider/csd:demographic/csd:dateOfBirth)[1]
	return 
	  if (exists($dob))  then  <fhir:birthDate>{$dob/text()}</fhir:birthDate>
	  else ()
	,
	(:  Note: note supported under standard CSD   <photo><!-- 0..* Attachment Image of the person --></photo>  :)
	for $org in ($provider/csd:organizations/csd:organization)
	   (: Note: base for URL for reference should maybe be handled by stored function extension metadata   :)
	return <fhir:organization><fhir:reference>Organization/{string($org/@oid)}</fhir:reference></fhir:organization>
	,
	(: Note: perhaps this should be for services -- see remark below on <fhir:period/> :)
	for $role in ($provider/csd:codedType)
	return <fhir:role><fhir:coding><fhir:system>{string($role/@codingScheme)}</fhir:system><fhir:code>{string($role/@code)}</fhir:code></fhir:coding></fhir:role>
	,
	for $specialty in ($provider/csd:specialty)
	return <fhir:specialty><fhir:coding><fhir:system>{string($specialty/@codingScheme)}</fhir:system><fhir:code>{string($specialty/@code)}</fhir:code></fhir:coding></fhir:specialty>
	,
	(: Note: note supported <period><!-- 0..1 Period      The period during which the practitioner is authorized to perform in these role(s) § --></period> 
           unless we interpret the <fhir:role/> element as a service
	:)
	for $fac in ($provider/csd:facilities/csd:facility)
	   (: Note: base for URL for reference should maybe be handled by stored function extension metadata   :)
	return <fhir:location><fhir:reference>Location/{string($fac/@oid)}</fhir:reference></fhir:location>
	,  
	for $qual in ($provider/csd:credential)
	return 
	  <fhir:qualification>
	    <fhir:code><fhir:coding><fhir:system>{string($qual/@codingScheme)}</fhir:system><fhir:code>{string($qual/@code)}</fhir:code></fhir:coding></fhir:code>
	    <fhir:period>
	       {if (exists($qual/csd:credenitalIssueDate)) then   <fhir:start>{$qual/csd:credenitalIssueDate}</fhir:start> else ()}
	       {if (exists($qual/csd:credentialRenewalDate)) then  <fhir:end>{$qual/csd:credentialRenewalDate}</fhir:end> else ()}
	    </fhir:period>
	    {
	      (:Note: I don't think this is quite correct.  It wants it to be an organization ID :)
	      if (exists($qual/csd:issuingAuthority)) then <fhir:issuer>{$qual/csd:issuingAuthority}</fhir:issuer> else () 
	    }
	  </fhir:qualification>
       ,
       for $lang in $provider/csd:language
       return  <fhir:communication><fhir:coding><fhir:system>{string($lang/@codingScheme)}</fhir:system><fhir:code>{string($lang/@code)}</fhir:code></fhir:coding></fhir:communication>
     )
    }
	 
      
  </fhir:Practitioner>
};






