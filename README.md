openinfoman-fhir
================

OpenInfoMan FHIR Adapater to represent CSD entities as FHIR resources:
* CSD Provider as FHIR practitioner
* CSD Faciltiy as FHIR location
* CSD Organization as FHIR organization

Prerequisites
=============

Assumes that you have installed BaseX and OpenInfoMan according to:
> https://github.com/openhie/openinfoman/wiki/Install-Instructions


Directions
==========
To get the libarary:
<pre>
cd ~/
git clone https://github.com/openhie/openinfoman-fhir
</pre>

Library Module
--------------
Common functionality for the is packaged in an XQuery module
<pre>
cd ~/openinfoman-fhir/repo
basex -Vc "REPO INSTALL openinfoman_fhir_adapter.xqm"
</pre>


Stored Functions
----------------
To install the stored functions (one for each of the FHIR resources) you can do: 
<pre>
cd ~/basex/resources/stored_query_definitions
ln -sf ~/openinfoman-fhir/resources/stored_query_definitions/* .
</pre>
Be sure to reload the stored functions: 
> https://github.com/openhie/openinfoman/wiki/Install-Instructions#Loading_Stored_Queries


FIHR Endpoints
--------------
You can the stored functions to the GET endpoints requried by FHIR with:  
<pre>
cd ~/basex/webapp
ln -sf ~/openinfoman-fhir/webapp/openinfoman_fhir_bindings.xqm
</pre>

