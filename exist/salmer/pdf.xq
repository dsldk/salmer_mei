xquery version "3.0" encoding "UTF-8";


(: 

TO DO: 
The general URL parameter should be changed into only a filename parameter, eg. "Vi_1553_LN1421_011v.xml"
and the actual URL to be rendered such as https://melodier.dsl.dk/print.xq?doc=Vi_1553_LN1421_011v.xml should be generated by the script

:) 



import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";

declare namespace request=   "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util =     "http://exist-db.org/xquery/util";
declare namespace xmldb =    "http://exist-db.org/xquery/xmldb";

declare variable $url := request:get-parameter("url", "");
declare variable $origin := request:get-header("origin");

declare variable $workingDir := "/tmp";
declare variable $shellScript := "./url_to_pdf.sh";


(: List of domains allowed to access this resource with Javascript :)
declare variable $allowed as node():= doc("library/cors_domains.xml"); 
 
declare function local:filename_from_url($url as xs:string) as xs:string* {
    (: extract page/file name from submitted url :)
    let $u := translate($url,"\","/")
    let $filename_w_ext := (tokenize($u,"/")[last()],$u)[.!=''][1]
    return (substring-before($filename_w_ext,"."),$filename_w_ext)[.!=''][1]
};

declare function local:url_to_pdf($url as xs:string) as node()* {
    let $options := 
        <options>
            <workingDir>{$workingDir}</workingDir>
        </options>
    let $results := if (normalize-space($url)) 
        then
            process:execute(($shellScript, $url),$options)  
        else
            <p>Invalid URL or file name</p>
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

declare function local:pdf($url,$filename) as node()* {
    let $pdf := local:url_to_pdf($url)
    let $download :=
        if (file:exists(concat($workingDir,"/output.pdf"))) then
            local:download_file(concat($workingDir,"/output.pdf"),"application/pdf",concat($filename,".pdf"))
        else
            <p>Error</p>
    return $download
};

(:    let $filename := local:filename_from_url($url)  :)
let $filename := "download"

let $response := local:pdf($url,$filename) 

return $response