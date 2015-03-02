openinfoman-fhir
================

The OpenInfoMan FHIR Adapater to represent CSD entities as FHIR resources:
* CSD Provider as FHIR practitioner http://www.hl7.org/implement/standards/fhir/practitioner.html
* CSD Faciltiy as FHIR location http://www.hl7.org/implement/standards/fhir/location.html
* CSD Organization as FHIR organization http://www.hl7.org/implement/standards/fhir/organization.html
* CSD Facilities in a Organizational Hierarchy as FHIR ValueSets appropriately composed of each other http://www.hl7.org/implement/standards/fhir/valueset.html 

It makes use of the OpenInfoMan software https://github.com/openhie/openinfoman

Ubuntu Installation
===================
You can easily install on Ubuntu 14.04 and Ubuntu 14.10 using the following commands
<pre>
sudo add-apt-repository ppa:openhie/release
sudo apt-get update
sudo apt-get install openinfoman-fhir
</pre>



Manual Installation
===================

Assumes that you have installed BaseX and OpenInfoMan according to:
> https://github.com/openhie/openinfoman/wiki/Install-Instructions


Directions
----------
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

