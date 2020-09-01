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

(: Login required for public use only :)
declare function local:login() as xs:boolean
{
  let $lgin := xmldb:login("/db", "YourAdminUserName", "YourAdminPassword")
  return $lgin
};

declare function local:url_to_pdf($url as xs:string) as node()* {
    let $options := 
        <options>
            <workingDir>{$workingDir}</workingDir>
        </options>
    (: process:execute is available for dba group users only. :)
    (: If used publicly, the script must log in to the db:    :)
    (: let $login := local:login()                            :)
    let $results := if (normalize-space($url)) 
        then
            process:execute(($shellScript, $url),$options)  (: generate PDF file on server :)
        else
            <p>Invalid URL</p>
    return $results
};

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


let $filename := "download"

let $response := local:pdf($url, $filename)

let $response := if ($url = "") then 
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>Error</title>
                <meta charset="UTF-8"/>
            </head>
            <body>
                <p>Parameter missing: url</p>
            </body>
        </html>
    else 
        local:pdf($url,$filename)


return $response