xquery version "3.0" encoding "UTF-8";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $host       := request:get-header('HOST'); (: "localhost"; with melodier.dsl.lan on port 8080 use: concat(request:get-header('HOST'),'/exist/rest') :)
declare variable $origin     := request:get-header("origin");
declare variable $meidocref  := request:get-parameter("doc", "");
declare variable $teidocref  := request:get-parameter("tei", "");
declare variable $mdiv       := request:get-parameter("mdiv", "");

declare variable $tei_base := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/";
declare variable $database := "/db/salmer"; (: with melodier.dsl.lan on port 8080 use "/db/salmer" :) 
declare variable $datadir  := "data";
declare variable $metaXsl  := doc(concat($database,"/xsl/metadata_to_html.xsl"));
declare variable $mdivXsl  := doc(concat($database,"/xsl/mdiv_to_html.xsl"));
declare variable $textXsl  := doc(concat($database,"/xsl/tei_text_to_html.xsl"));
declare variable $index    := doc(concat($database,"/library/publications.xml"));

(: List of domains allowed to access this resource with Javascript :)
declare variable $allowed as node():= 
    <domains>
        <domain>http://melodier.dsl.lan:8080</domain>
        <domain>https://tekstnet.dk</domain>
    </domains>;

let $filename := tokenize($meidocref, '/')[position() = last()]


let $tei_doc := if(doc-available(concat($tei_base,$teidocref)))
    then 
        doc(concat($tei_base,$teidocref))
    else 
        false()

let $text_data := if($tei_doc) 
    then
        $tei_doc//tei:div[@type='psalm' and .//tei:notatedMusic/tei:ptr[@target=$filename or substring-before(@target,'#')=$filename]][1]
    else
        ()

let $result :=
        <div xmlns="http://www.w3.org/1999/xhtml">
            {  
                (: get only the TEI sibling elements between the current <notatedMusic> element and the following one  :)
                let $text_step1 :=
                    <div>
                        {$text_data//tei:notatedMusic[contains(tei:ptr/@target,concat('#',$mdiv)) or tei:ptr/@target=$filename]/following-sibling::*}
                    </div>
                let $text_step2 :=  
                    if($text_step1//tei:notatedMusic) then
                        <div>
                            {$text_step1/*[not(preceding::tei:notatedMusic)][not(name()='notatedMusic')]}
                        </div>
                    else                               
                        <div>{$text_step1}</div> 
                let $params2 := 
                    <parameters>
                      <param name="mdiv" value="{$mdiv}"/>
                    </parameters>
                return transform:transform($text_step2,$textXsl,$params2)  
            }
        </div>


return $result