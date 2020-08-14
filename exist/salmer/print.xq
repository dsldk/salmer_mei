xquery version "3.0" encoding "UTF-8";

import module namespace settings="http://dsl.dk/salmer/settings" at "./settings.xqm";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $docref   := request:get-parameter("doc", "");
declare variable $mdiv     := request:get-parameter("mdiv", "");
declare variable $host     := request:get-header('HOST'); (: "localhost"; with salmer.dsl.lan on port 8080 use: concat(request:get-header('HOST'),'/exist/rest') :)
declare variable $language := request:get-parameter("language", "");
declare variable $head     := request:get-parameter("head", "Musik og tekst i reformationstidens danske salmesang");

declare variable $tei_base := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/";
declare variable $database := "/db/salmer"; (: with salmer.dsl.lan on port 8080 use "/db/salmer" :) 
declare variable $datadir  := "data";
declare variable $metaXsl  := doc(concat($database,"/xsl/metadata_to_html.xsl"));
declare variable $mdivXsl  := doc(concat($database,"/xsl/mdiv_to_html.xsl"));
declare variable $textXsl  := doc(concat($database,"/xsl/tei_text_to_html.xsl"));
declare variable $index    := doc(concat($database,"/library/publications.xml"));

(: Set language :)
let $language := settings:language(request:get-parameter("language", ""))
let $l := doc(concat('library/language/',$language,'.xml'))/*[1]    (: Localisation of labels etc. :)   

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
        $index//dsl:pub/dsl:mei_coll[normalize-space(.) and contains($filename,string(.))]
    else
        ""

let $tei_doc := if($coll!="" and doc-available(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei)))
    then 
        doc(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei))
    else 
        false()

let $text_data := if($tei_doc) 
    then
        $tei_doc//tei:div[@type='psalm' and .//tei:notatedMusic/tei:ptr[@target=$filename or substring-before(@target,'#')=$filename]][1]
    else
        ()

let $list := 
    for $doc in collection(concat($database,'/',$datadir,'/',$coll))/m:mei
    where util:document-name($doc)=$filename
    return $doc

let $title := $list//m:workList/m:work[1]/m:title[string()][not(@type/string())][1]/string()

let $rec_type := if($list//m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"])
    then 
        string-join($list//m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]/string()," ")
    else "music_document"

let $result :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>{$title} – DSL</title>
        <meta charset="UTF-8"/>
        
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_print.css"/>
        
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js"><!-- jquery --></script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js"><!-- jquery ui --></script>     
        <script type="text/javascript" src="js/libs/verovio/verovio-toolkit.js"><!-- Verovio --></script>

        <script type="text/javascript" src="js/MeiPrint.js"><!-- jquery --></script>


	</head>
	<body>
	

	   <div class="button"><button onclick="window.print();" class="mei_menu" style="padding:2px 10px;"><img src="style/img/print.png" alt="{$l/*[name()='print_button']/text()}" 
	   style="vertical-align: bottom;"/>&#160; {upper-case($l/*[name()='print_button']/text())}</button></div>


        <div>
            <!-- Metadata -->
            <div class="title">
                {
                    let $img_src := if(contains($rec_type,' '))
                        then substring-before($rec_type,' ')
                        else $rec_type
                    return <img src="/style/img/{$img_src}.png" alt="{$rec_type}" style="margin-right:5px;"/> 
                }
                {
                    let $this_publ := if($index//dsl:pub[dsl:mei_coll=$coll])
                        then concat($index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:title," ")
                        else ""
                    return $this_publ
                }
                {
                    let $editor := if($index//dsl:pub[dsl:mei_coll=$coll])
                        then $index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:editor
                        else ""  
                    let $year := if($index//dsl:pub[dsl:mei_coll=$coll])
                        then $index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:year
                        else ""
                    let $imprint := if($editor!="" and $year!="")
                        then concat("(",$editor,", ",$year,")")
                        else if($editor!="" or $year!="")
                        then concat("(",$editor,$year,")")
                        else ""
                    return $imprint
                }
            </div>
            {
                let $title := if($list[1]//m:workList/m:work/m:title/text()) 
                    then <h1>{$list[1]//m:workList/m:work/m:title[text()][1]/text()}</h1>
                    else ""
                return $title                        
            }
            
        </div>
        
        <div class="documentFrame container">
            <!-- Music and text -->
            {  
            	for $mdiv at $pos in $list[1]//m:mdiv[@xml:id=$mdiv or $mdiv=""]
                	let $include_data := 
                	   if($pos=1) then true() else false()   
                	(:   false()   :)
                	let $params := 
                    	<parameters>
                    	  <param name="mdiv"         value="{$mdiv/@xml:id}"/>
                    	  <param name="doc"          value="{$filename}"/>
                    	  <!--<param name="include_data" value="{$include_data}"/>-->
                    	</parameters>
                	let $music := transform:transform($list[1],$mdivXsl,$params)
                	(: get only the TEI elements after the current <notatedMusic> and only until the following one  :)
                    let $text_step1 :=
                        <div>
                            {$text_data//tei:notatedMusic[contains(tei:ptr/@target,concat('#',$mdiv/@xml:id)) or tei:ptr/@target=$filename]/following-sibling::*}
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
                    	  <param name="mdiv" value="{$mdiv/@xml:id}"/>
                    	</parameters>
                    let $text :=  transform:transform($text_step2,$textXsl,$params2)
                return (<div class="score">{$music}</div>, <div class="clear_both"><!-- clear --></div>, <div class="text_container">{$text}</div>)  
            }
        </div>
        <div class="footer">&#169; Det Danske Sprog- og Litteraturselskab</div>
    </body>
</html>

return $result