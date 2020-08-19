xquery version "3.0" encoding "UTF-8";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

declare namespace request="http://exist-db.org/xquery/request";

declare variable $url := request:get-parameter("url", "");

let $options := 
    <options>
        <workingDir>/tmp</workingDir>
    </options>
return
<results>
    {process:execute(("./url_to_pdf.sh", $url),$options)}
</results>

