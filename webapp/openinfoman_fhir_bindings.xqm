module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace osf = "https://github.com/openhie/openinfoman/adapter/opensearch";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace fhir = "https://github.com/openhie/openinfoman/adapter/fhir";

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
    if (not(fhir:is_fhir_function($search_name)))
      (:not a read fhir entity query. should 404 or whatever is required by FHIR :)
    then ('Not a FHIR Compatible stored functions' )
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
  let $reads :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ]
  return 
    if (not(fhir:is_fhir_function($search_name)) or count($reads) = 0 )
      (:not a read practitioner query. should 404 or whatever is required by FHIR :)
    then ('Not a FHIR Compatible stored function'    )
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
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entity}/{$id}") 
  %output:media-type("text/xml")
  function page:read_entity_id_1($search_name,$doc_name,$entity,$id) 
{
  page:read_entity_id_2($search_name,$doc_name,$entity,$id) 
};


declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entity}") 
  %rest:query-param("_id","{$id}")
  %output:media-type("text/xml")
  function page:read_entity_id_2($search_name,$doc_name,$entity,$id) 
{
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $reads :=   $function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ]
  return
    if (not(fhir:is_fhir_function($search_name)) or count($reads) = 0 )
    (:not a read practitioner query. should 404 or whatever is required by FHIR :)
  then () 
  else 
    let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
    let $careServicesRequest := 
      <csd:careServicesRequest >
	<csd:function uuid="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
	  <csd:requestParams >
	   {
	     if ($id) 
	     then <id>{$id}</id>
	     else ()
	   }
	  </csd:requestParams>
	</csd:function>
      </csd:careServicesRequest>
    let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest)
    return $contents
};


