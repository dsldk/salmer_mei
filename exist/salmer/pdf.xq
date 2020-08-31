xquery version "3.0" encoding "UTF-8";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";

declare namespace request=   "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util =     "http://exist-db.org/xquery/util";
declare namespace xmldb =    "http://exist-db.org/xquery/xmldb";

declare variable $url := request:get-parameter("url", "");
declare variable $origin := request:get-header("origin");
declare variable $requestedDomain := replace($url,"^(http[s]?://[a-z\.]*).*$","$1");

declare variable $workingDir := "/tmp";
declare variable $shellScript := "./url_to_pdf.sh";


(: List of domains allowed to access this resource with Javascript :)
declare variable $allowed as node():= doc("library/cors_domains.xml"); 


declare function local:url_to_pdf($url as xs:string) as node()* {
    let $options := 
        <options>
            <workingDir>{$workingDir}</workingDir>
        </options>
    let $results := if (normalize-space($url)) 
        then
            process:execute(($shellScript, $url),$options)  (: generate PDF file on server :)
        else
            <p>Invalid URL</p>
    return $results
};

declare function local:download_file($path as xs:string, $mimetype, $as_filename) as node()* {
    let $status := if (file:exists($path)) 
        then
           let $file := file:read-binary($path)
           let $headers :=
               if ($allowed//*[.=$origin]) then
                    response:set-header("Access-Control-Allow-Origin", $origin)
               else
                    ""
           let $download := response:stream-binary($file, $mimetype, $as_filename)  (: the actual download :)
           return   
               <p>File sent</p>
        else
           <p>Invalid URL or file name</p> 
    return $status    
};

(: limit PDF creation to pages from listed sites only :)
declare function local:url_accepted($url as xs:string) as xs:boolean {
    let $ok := if ($allowed//*[.=$requestedDomain]) then
            true()
        else 
            false()
    return $ok
};

declare function local:pdf($url as xs:string, $filename as xs:string) as node()* {
    let $pdf := local:url_to_pdf($url)
    let $download :=
        if (file:exists(concat($workingDir,"/output.pdf"))) then
            local:download_file(concat($workingDir,"/output.pdf"),"application/pdf",concat($filename,".pdf"))
        else 
            <p>Error</p>
    return $download
};

(: get the file name from 1) the "doc" parameter, 2) the page/script name, or 3) just call it "download" :)  
declare function local:get_filename($url as xs:string) as xs:string {
      let $filename := if (normalize-space(substring-before(tokenize(substring-after($url,"doc="),"/")[last()],"."))) then
            substring-before(tokenize(substring-after($url,"doc="),"/")[last()],".")
        else if (normalize-space(substring-before(tokenize(tokenize($url,"\?")[1],"/")[last()],"."))) then
            substring-before(tokenize(tokenize($url,"\?")[1],"/")[last()],".")
        else
            "download"
    return $filename   
};

let $filename := local:get_filename($url)

let $response := if (local:url_accepted($url)) then 
        local:pdf($url,$filename)
    else
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>Error</title>
                <meta charset="UTF-8"/>
            </head>
            <body>
                <p>PDF creation not allowed from domain {$requestedDomain}</p>
            </body>
        </html>
        
return $response