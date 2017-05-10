xquery version '1.0-ml';

(:
 : This is a sample triggers module, which simply logs the creation of a new document.
 :)

import module namespace trgr='http://marklogic.com/xdmp/triggers' 
  at '/MarkLogic/triggers.xqy';

declare variable $trgr:uri as xs:string external;

(: let $newDoc:=util:filter-pdf($trgr:uri) :)

xdmp:log(fn:concat('*****Document ', $trgr:uri, ' was created.*****'))