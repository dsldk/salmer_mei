xquery version "3.0";

declare namespace local="http://dsl.dk/this/app";
declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace dsl="http://dsl.dk";

declare option exist:serialize "method=xhtml media-type=text/xml indent=yes";

declare variable $tei_base := "http://salmer.dsl.lan:8080/exist/apps/salmer/xml/";
declare variable $xsl      := doc('xsl/concordance.xsl');
declare variable $db       := '/db/salmer';
declare variable $index    := doc(concat($db,"/library/publications.xml"));

(:
    Generate a concordance file translating @xml:ids in TEI texts to chapter/section numbers.            
    The resulting XML is stored in db/salmer/tmp/                     
:)


let $index-doc := 
<index>
{
    for $pub in $index//dsl:pub
                let $doc-name  := $pub/dsl:tei
                let $params := <parameters/>
        order by $doc-name
        return
            (<text id="{substring-before($doc-name,'.xml')}">
                { transform:transform(doc(concat($tei_base,$doc-name)), $xsl, $params) }
            </text>)
}
</index>


let $remove-return-status := if(exists(collection(concat($db,'/tmp/','concordance.xml')))) then  xmldb:remove($db, 'concordance.xml') else ""
let $store-return-status := xmldb:store(concat($db,'/tmp/'), 'concordance.xml', $index-doc)  

return  (: <message>Document Created {$store-return-status} at {$db}/tmp/concordance.xml</message>  :) 
          
    $index-doc
    