xquery version "3.0" encoding "UTF-8";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $host     := request:get-header('HOST'); (: "localhost"; with salmer.dsl.lan on port 8080 use: concat(request:get-header('HOST'),'/exist/rest') :)
declare variable $origin   := request:get-header("origin");
declare variable $docref   := request:get-parameter("doc", "");
declare variable $language := request:get-parameter("language", "");

declare variable $database := "/db/salmer"; (: with salmer.dsl.lan on port 8080 use "/db/salmer" :) 
declare variable $datadir  := "data";
declare variable $metaXsl  := doc(concat($database,"/xsl/metadata_to_html.xsl"));
declare variable $mdivXsl  := doc(concat($database,"/xsl/mdiv_to_html.xsl"));
declare variable $textXsl  := doc(concat($database,"/xsl/tei_text_to_html.xsl"));
declare variable $index    := doc(concat($database,"/library/publications.xml"));

(: List of domains allowed to access this resource with Javascript :)
declare variable $allowed as node():= 
    <domains>
        <domain>http://salmer.dsl.lan:8080</domain>
        <domain>https://tekstnet.dk</domain>
    </domains>;
    
    
(: Filter away any MDIV reference from URL :)
let $document := if(contains($docref,"MDIV"))
    then 
        concat(substring-before($docref,"MDIV"),".xml")
    else
        $docref

let $filename := tokenize($document, '/')[position() = last()]

let $coll := if(contains($document, '/'))
    then
        string-join(tokenize($document, '/')[position() lt last()], '/')
    else 
    (: Collection not specified; try to guess the collection name from the MEI file name.                                    :)
    (: Works only if the MEI file name contains the collection name (for example, Th_1569_LN1426_001r.xml is in collection Th_1569) :)
    if($index//dsl:pub[contains($filename,dsl:mei_coll)])
    then 
        $index//dsl:pub/dsl:mei_coll[contains($filename,string(.))]
    else
        ""
        
let $list := 
    for $doc in collection(concat($database,'/',$datadir,'/',$coll))/m:mei
    where util:document-name($doc)=$filename
    return $doc
    
(: allow access from certain other domains :)          
let $headers := 
    if ($allowed//*[.=$origin]) then
        response:set-header("Access-Control-Allow-Origin", $origin)
    else
        ""

let $result :=
        <div class="documentFrame container" xmlns="http://www.w3.org/1999/xhtml">
            {  
            	for $doc in $list
                	let $params := 
                    	<parameters>
                    	  <param name="hostname"    value="{$host}"/>
                    	  <param name="database"    value="{$database}"/>
                    	  <param name="datadir"     value="{$datadir}"/>
                    	  <param name="database"    value="{$database}"/>
                    	  <param name="coll"        value="{$coll}"/>
                    	  <param name="filename"    value="{$filename}"/>
                    	  <param name="doc"         value="{concat($database,'/',$datadir,'/',$document)}"/>
                    	  <param name="script_path" value="./document.xq"/>
                    	  <param name="language"    value="{$language}"/>
                    	</parameters>
            	return transform:transform($doc,$metaXsl,$params)            	
            }
        </div>
        

return $result