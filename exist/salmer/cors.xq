xquery version "3.0" encoding "UTF-8";

declare namespace request=   "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util =     "http://exist-db.org/xquery/util";
declare namespace xmldb =    "http://exist-db.org/xquery/xmldb";

declare variable $resource := request:get-parameter("res", ""); 

let $response := if (util:binary-doc-available($resource))
    then
        let $mimetype := xmldb:get-mime-type($resource)
        let $filename := tokenize($resource,"/")[last()]
        let $bin := util:binary-doc($resource)
        let $headers := response:set-header("Access-Control-Allow-Origin", "https://tekstnet.dk")  
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