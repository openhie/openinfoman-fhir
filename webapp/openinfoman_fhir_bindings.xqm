module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace fhir = "https://github.com/openhie/openinfoman/adapter/fhir";
import module namespace request = "http://exquery.org/ns/request";


declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace csd = "urn:ihe:iti:csd:2013";
declare namespace   xforms = "http://www.w3.org/2002/xforms";






declare
  %rest:path("/CSD/adapter/fhir/{$search_name}")
  %output:method("xhtml")
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
       return csd_webconf:wrapper($contents)

 
};



declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}")
  %output:method("xhtml")
  function page:show_endpoints($search_name,$doc_name) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $read :=  ($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ])[1]
  let $entity := string($read/@type)
  let $base_url := concat($csd_webconf:baseurl, "CSD/adapter/fhir/",$search_name, "/", $doc_name, "/", $entity)
  return 
    if (not(fhir:is_fhir_function($search_name)) or not($read)  )
      (:not a read practitioner query. should 404 or whatever is required by FHIR :)
    then ('Not a FHIR Compatible stored function'    )
    else 
      let $headers :=
	(
	<link rel="stylesheet" type="text/css" media="screen"   href="{$csd_webconf:baseurl}static/bootstrap-datetimepicker/css/bootstrap-datetimepicker.min.css"/>
	,<script src="{$csd_webconf:baseurl}static/bootstrap-datetimepicker/js/bootstrap-datetimepicker.js"/>
	,<script type="text/javascript">
          $( document ).ready(function() {{ 
	    $('#datetimepicker_xml').datetimepicker({{format: 'yyyy-mm-ddThh:ii:ss+00:00',startDate:'2013-10-01'}});
	    $('#datetimepicker_json').datetimepicker({{format: 'yyyy-mm-ddThh:ii:ss+00:00',startDate:'2013-10-01'}});
           }});
	 </script>
	 )

      let $contents := 
      <div>
        <h2>{$entity} in {$doc_name}</h2>
	<p>Resource Endpoint: <pre>{$base_url}</pre></p>
	<ul>
	  <li> 
	    Search
	    <a href="{$base_url}/_search"> XML</a> 
	    / <a href="{$base_url}/_search?_format=json">JSON</a>
	  </li>
	  <li> 
	    History
	    <a href="{$base_url}/_history"> XML</a> 
	    / <a href="{$base_url}/_history?_format=json">JSON</a>
	    <br/>
	    Query by last modified time (XML)
	    <form method='get' action="{$base_url}/_history">
	      <input  size="35" id="datetimepicker_xml"    name='_since' type="text" value=""/>   
	      <input type='submit' />
	    </form> 
	    <br/>
	    Query by last modified time (JSON)
	    <form method='get' action="{$base_url}/_history">
	      <input  size="35" id="datetimepicker_json"    name='_since' type="text" value=""/>   
	      <input type='hidden' name='_format' value='json'/>
	      <input type='submit' />
	    </form> 

	  </li>
	</ul>
      </div>
      return csd_webconf:wrapper($contents,$headers)
};

declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entityType}/{$id}") 
  %rest:query-param("_format","{$format}","application/xml+fhir")
  function page:read_entity($search_name,$doc_name,$entityType,$format,$id) 
{

  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $fEntityType :=   string(($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ])[1]/@type)
  return
    if (not(fhir:is_fhir_function($search_name)) or not($fEntityType = $entityType))
    (:not a valid read query. should 404 or whatever is required by FHIR :)
  then ()
  else 
    let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
    let $careServicesRequest := 
      <csd:careServicesRequest >
	<csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
	  <csd:requestParams >
	    <id>{$id}</id>
	  </csd:requestParams>
	</csd:function>
      </csd:careServicesRequest>
    let $entities := (csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest))[1] (:make sure there is only one:)
    let $resource := fhir:format_entities($doc,$entities,$entityType,$format)
    return
      if ($format = ('application/json+fhir' ,  'application/json' ,'json'))
      then
        (
        <rest:response>
	  <output:serialization-parameters>
	    <output:media-type value='application/json'/>
	  </output:serialization-parameters>
	</rest:response>
	,$resource
        )
      else
	$resource
};



declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entityType}/_search") 
  %rest:query-param("_format","{$format}","application/xml+fhir")
  function page:search_entity2($search_name,$doc_name,$entityType,$format)
{
  page:search_entity($search_name,$doc_name,$entityType,$format)
};

declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entityType}") 
  %rest:query-param("_format","{$format}","application/xml+fhir")
  function page:search_entity($search_name,$doc_name,$entityType,$format)
{
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $fEntityType :=   string(($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ])[1]/@type)
  return
    if (not(fhir:is_fhir_function($search_name)) or not($fEntityType = $entityType))
    (:not a valid read query. should 404 or whatever is required by FHIR :)
  then ()
  else 
    let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
    let $requestParams := 	
      <csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
	<csd:requestParams > 	  
	  {page:search_global_parameters() }
	  {
	    switch ($entityType)
	    case "Practitioner" return () (: page:search_practitioner_parameters():)
	    case "Location" return () (: page:search_location_parameters() :)
	    case "Organization" return () (: page:search_organization_parameters() :)
	    default return ()	  
	  }
	</csd:requestParams>
      </csd:function>	  

    let $careServicesRequest :=   <csd:careServicesRequest >{$requestParams}</csd:careServicesRequest>
    let $entities := (csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest))
    let $resources := fhir:format_entities($doc,$entities,$entityType,$format)
    return
      if ($format = ('application/json+fhir' ,  'application/json' ,'json'))
      then fhir:create_feed_from_entities_JSON($resources,$requestParams) 
      else fhir:create_feed_from_entities($resources,$requestParams) 
};



declare
  %rest:path("/CSD/adapter/fhir/{$search_name}/{$doc_name}/{$entityType}/_history") 
  %rest:query-param("_format","{$format}","application/xml+fhir")
  function page:history_entity($search_name,$doc_name,$entityType,$format)
{
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $fEntityType :=   string(($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:fhir:read' ])[1]/@type)
  return
    if (not(fhir:is_fhir_function($search_name)) or not($fEntityType = $entityType))
    (:not a valid read query. should 404 or whatever is required by FHIR :)
  then ()
  else 
    let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
    let $requestParams := 	
      <csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
	<csd:requestParams > 	  
	  {page:history_global_parameters() }
	</csd:requestParams>
      </csd:function>	  

    let $careServicesRequest :=   <csd:careServicesRequest >{$requestParams}</csd:careServicesRequest>
    let $entities := (csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest))
    let $resources := fhir:format_entities($doc,$entities,$entityType,$format)
    return
      if ($format = ('application/json+fhir' ,  'application/json' ,'json'))
      then fhir:create_feed_from_entities_JSON($resources,$requestParams) 
      else fhir:create_feed_from_entities($resources,$requestParams) 
};




declare function page:search_global_parameters() 
{
  let $params := request:parameter-names()
  return 
    (
      if ("_id" = $params)
      then <fhir:_id>{request:parameter("_id")}</fhir:_id>
      else ()
      ,
      if ("_count" = $params)
      then <fhir:_count>{request:parameter("_count")}</fhir:_count>
      else ()
      ,
      if ("page" = $params)
      then <page>{request:parameter("_pageOffset")}</page>
      else ()
    )
};

declare function page:history_global_parameters() 
{
  let $params := request:parameter-names()
  return 
    (
      if ("_since" = $params)
      then <fhir:_since>{request:parameter("_since")}</fhir:_since>
      else ()
      ,
      if ("_count" = $params)
      then <fhir:_count>{request:parameter("_count")}</fhir:_count>
      else ()
      ,
      if ("page" = $params)
      then <page>{request:parameter("_pageOffset")}</page>
      else ()
    )
};