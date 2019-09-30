xquery version "3.0" encoding "UTF-8";

declare namespace request=   "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util =     "http://exist-db.org/xquery/util";
declare namespace xmldb =    "http://exist-db.org/xquery/xmldb";

declare variable $resource := request:get-parameter("res", "");
declare variable $origin := request:get-header("origin");

(: List of domains allowed to access this resource with Javascript :)
declare variable $allowed as node():= 
    <domains>
        <domain>http://salmer.dsl.lan:8080</domain>
        <domain>https://tekstnet.dk</domain>
    </domains>;

let $response := if (util:binary-doc-available($resource))
    then
        let $mimetype := xmldb:get-mime-type($resource)
        let $filename := tokenize($resource,"/")[last()]
        let $bin := util:binary-doc($resource)
        let $headers := 
            if ($allowed//*[.=$origin]) then
                response:set-header("Access-Control-Allow-Origin", $origin)
            else
                ""
        return response:stream-binary($bin, $mimetype, $filename)
    else
        <html xmlns="http://www.w3.org/1999/xhtml">
        	<head>
        	    <title>Not found</title>
                <meta charset="UTF-8"/>
        	</head>
        	<body>
        	   <p>Resource {$resource} not found</p>
            </body>
        </html>
    

return $response