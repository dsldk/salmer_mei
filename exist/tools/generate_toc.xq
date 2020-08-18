(: Generate a MEI <contents> table of contents based on "hasPart" relations :)

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $host     := request:get-header('HOST'); (: "localhost"; with melodier.dsl.lan on port 8080 use: concat(request:get-header('HOST'),'/exist/rest') :)
declare variable $origin   := request:get-header("origin");
declare variable $docref   := request:get-parameter("doc", "");
declare variable $language := request:get-parameter("language", "");

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
    
    
(: allow access from certain other domains :)          
let $headers := 
    if ($allowed//*[.=$origin]) then
        response:set-header("Access-Control-Allow-Origin", $origin)
    else
        ""

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

let $doc := doc(concat('/db/salmer/data/',$document))    


(: guess URL to tekstnet.dk page :)                
let $tei_doc_name := if($coll!="")
    then 
        $index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei
    else 
        ""

let $tei_doc := if($tei_doc_name!="" and doc-available(concat($tei_base,$tei_doc_name)))
    then 
        doc(concat($tei_base,$tei_doc_name))
    else 
        false()
        
let $chapters := if($tei_doc) then $tei_doc/tei:TEI/tei:text/tei:body/tei:div else () 




let $output := 
    for $rel at $pos in $doc//m:work/m:relationList/m:relation
        let $target := doc(concat('/db/salmer/data/',$rel/@target))
        (:let $this_filename := tokenize($rel/@target, '/')[position() = last()]:)
        let $this_filename := tokenize($rel/@target, '/')[position() = last()]
        let $chapter as xs:integer := count($chapters[.//tei:notatedMusic/tei:ptr[@target=$this_filename or substring-before(@target,'#')=$this_filename]]/preceding-sibling::tei:div) + 1
        (: Use section only if there is more than one  :)
        let $section as xs:string := if(count($chapters[$chapter]/tei:div/tei:head[@type="add"]) > 1)
            then
                concat("/",count($chapters[$chapter]/tei:div/tei:head[@type="add"][following::tei:notatedMusic/tei:ptr[@target=$this_filename or substring-before(@target,'#')=$this_filename]]))
            else 
                ""
        let $tekstnet_link := <ptr type="edition" target="https://tekstnet.dk/{$tei_doc_name}/{$chapter}{$section}"/>
        
    return 
          <contentItem label="{$pos}">
               <title>{$target//m:meiHead/m:workList/m:work/m:title[not(@type)][1]/text()}</title>
               <title type="uniform">{$target//m:meiHead/m:workList/m:work/m:title[@type='uniform'][1]/text()}</title>
               <locus>{$target//m:meiHead/m:workList/m:work/m:identifier[@label='Thomissøn 1569' or @label='Jespersen 1573' or 
                    @label='Mortensøn 1528' or @label='Ulricksøn 1535' or @label='Vingaard 1553' or @label='Vormordsen 1539'][1]/text()}</locus>
               {$tekstnet_link}
               <ptr type="db" target="{$rel/@target}"/>
          </contentItem>



return
     <contents>
         {$output}
     </contents>