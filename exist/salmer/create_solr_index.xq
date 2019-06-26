xquery version "3.0";

declare namespace local="http://dsl.dk/this/app";
declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace dsl="http://dsl.dk";

declare option exist:serialize "method=xhtml media-type=text/xml indent=yes";

(: Generate a file for indexing MEI files in Solr :)


(: It is assumed that the data to be indexed is in /db/salmer/data :)

let $collection := '/db/salmer'


let $index-doc := 
<add>
    {
    for $doc in collection(concat($collection,'/data//'))/m:mei
        let $doc-name  := util:document-name($doc)
        let $coll-name := util:collection-name($doc)
        let $params := 
            <parameters>
                <param name="filename" value="{$doc-name}"/>
                <param name="collection" value="{$coll-name}"/>
            </parameters>
        return transform:transform($doc, doc('xsl/index_for_solr.xsl'), $params) 
    }
</add>

(: let $login := xmldb:login($collection, 'mylogin', 'my-password') :)

let $file-name := 'solr_index_add.xml'
let $remove-return-status := if(exists(collection(concat($collection,'/index/',$file-name)))) then  xmldb:remove($collection, $file-name) else ""
let $store-return-status := xmldb:store(concat($collection,'/index/'), $file-name, $index-doc)  

return  (: <message>Document Created {$store-return-status} at {$collection}/{$file-name}</message>  :) 
          
    $index-doc
    