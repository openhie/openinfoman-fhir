module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace osf = "https://github.com/openhie/openinfoman/adapter/opensearch";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace csd = "urn:ihe:iti:csd:2013";
declare namespace   xforms = "http://www.w3.org/2002/xforms";
declare namespace os =  "http://a9.com/-/spec/opensearch/1.1/";





declare
  %rest:path("/CSD/adapter/fhir/{$search_name}")
  %output:media-type("xhtml")
  function page:show_endpoints($search_name) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $extensions :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter' and  @type='fhir']
  return 
    if (count($extensions) = 0 )
      (:not a read practitioner query. should 404 or whatever is required by FHIR :)
    then ('Not a FHIR Compatible stored function')
    else 
      let 
	$contents :=
	  <div>
	    <h2>FHIR Documents</h2>
            <ul>
              {
  		for $doc_name in csd_dm:registered_documents($csd_webconf:db)      
		return
  		<li>
		  <a href="{$csd_webconf:baseurl}CSD/adapter/fhir/{$search_name}/{$doc_name}">{string($doc_name)}</a>
		</li>
	      }
	    </ul>
	  </div>
       return $contents

 
};



declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}")
  %output:media-type("xhtml")
  function page:show_endpoints($search_name,$doc_name) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $extensions :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter' and  @type='fhir']
  let $reads :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman-fihr:read' ]
  return 
    if (count($extensions) = 0 or count($reads) = 0) 
      (:not a read practitioner query. should 404 or whatever is required by FHIR :)
    then ('Not a FHIR Compatible stored function')
    else 
      let $contents := 
      <div>
        <h2>Read</h2>
	<ul>
	  {
	    for $read in $reads
	    let $entity := string($read/@type)
	    let $url := concat($csd_webconf:baseurl, "CSD/adapter/fhir/",$search_name, "/", $doc_name, "/", $entity)
	    return <li><a href="{$url}">Read {$entity}</a></li>
	  }
	</ul>
      </div>
      return $contents
};


declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entity}") 
  %output:media-type("text/xml")
  function page:read_entity($search_name,$doc_name,$entity) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $extensions :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter' and  @type='fhir']
  let $reads :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman-fihr:read' and  @type=$entity]
  return
  if (count($extensions) = 0 or count($reads) = 0) 
    (:not a read practitioner query. should 404 or whatever is required by FHIR :)
  then () 
  else 
    let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
    let $careServicesRequest := 
    <csd:careServicesRequest >
      <csd:function uuid="{$search_name}"/>
    </csd:careServicesRequest>
    let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest)
    return $contents
};