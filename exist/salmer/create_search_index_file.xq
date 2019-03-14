xquery version "3.0";

declare namespace local="http://dsl.dk/this/app";
declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace dsl="http://dsl.dk";

declare option exist:serialize "method=xhtml media-type=text/xml indent=yes";


(: It is assumed that the data to be indexed is in /db/dsl/data :)

let $collection := '/db/salmer'


let $index-doc := 
<index xmlns="http://dsl.dk">
    {
    for $doc in collection(concat($collection,'/data'))/m:mei
        let $doc-name:=util:document-name($doc)
        let $params := 
            <parameters>
                <param name="filename" value="{$doc-name}"/>
            </parameters>
        return transform:transform($doc, doc('xsl/index_for_searching.xsl'), $params) 
    }
</index>

(: let $login := xmldb:login($collection, 'mylogin', 'my-password') :)

let $file-name := 'search_index.xml'
let $remove-return-status := if(exists(collection(concat($collection,'/index/',$file-name)))) then  xmldb:remove($collection, $file-name) else ""
let $store-return-status := xmldb:store(concat($collection,'/index/'), $file-name, $index-doc)

return  (: <message>Document Created {$store-return-status} at {$collection}/{$file-name}</message>  :) 
          
    $index-doc
    