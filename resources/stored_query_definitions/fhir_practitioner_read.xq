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


let $represent_provider_as_practitioner := function($doc,$provider) 
{
  (: See http://www.hl7.org/implement/standards/fhir/practitioner.html :)
  <fhir:Practitioner >
    <fhir:identifier>{string($provider/@oid)}</fhir:identifier>
    <fhir:name>{($provider/csd:demographic/csd:name/csd:commonName)[1]/text()}</fhir:name>
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
}



let $providers := /csd:CSD/csd:providerDirectory/csd:provider

return 
  <atom:feed>
    <atom:title>CSD Provider as FHIR Practitioner</atom:title>
    <atom:id>urn:uuid:b248b1b2-1686-4b94-9936-37d7a5f94b51</atom:id> 
    <atom:link href="http://www.hl7.org/fhir/patient-examples.xml" rel="self"/>
    <atom:updated>2012-05-29T23:45:32Z</atom:updated>
    <atom:content>
     {
       for $provider in $providers
       return 
       <atom:entry>
         {$represent_provider_as_practitioner(/.,$provider) }
       </atom:entry>
     }
     </atom:content>
  </atom:feed>