xquery version "3.0";

declare namespace local="http://dsl.dk/this/app";
declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace dsl="http://dsl.dk";

declare option exist:serialize "method=xhtml media-type=text/xml indent=yes";

(: Generate a file for indexing MEI files in Solr :)


(: It is assumed that the data to be indexed is in /db/salmer/data :)

let $db := '/db/salmer'
let $collection := ''  (: for instance, 'Th_1569'; use empty string to select all :)


let $index-doc := 
<add>
    {
(: Kun småbøgerne: :)    
(:    for $doc in collection(concat($db,'/data/',$collection,'/'))/m:mei[not(contains(util:document-name(.),"Je_" ) or contains(util:document-name(.),"Th_"))][count(m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]/text())=0]  :)
(:  Kun Vingaard :)
(:     for $doc in collection(concat($db,'/data/',$collection,'/'))/m:mei[contains(util:document-name(.),"Vi_" )]  :)
(:  Kun metaposter :)
(:     for $doc in collection(concat($db,'/data/',$collection,'/'))/m:mei[not(contains(util:document-name(.),"_15" ))]  :)
(:  Alle  :)    
(:     for $doc in collection(concat($db,'/data/',$collection,'/'))/m:mei[not(m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"])]  :)
    for $doc in collection(concat($db,'/data/',$collection,'/'))/m:mei[not(m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"])]  
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

let $file-name := 'solr_index_add.xml'
let $remove-return-status := if(exists(collection(concat($db,'/index/',$file-name)))) then  xmldb:remove($db, $file-name) else ""
let $store-return-status := xmldb:store(concat($db,'/index/'), $file-name, $index-doc)  

return  (: <message>Document Created {$store-return-status} at {$db}/{$file-name}</message>  :) 
          
    $index-doc
    