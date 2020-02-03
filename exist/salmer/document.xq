xquery version "3.0" encoding "UTF-8";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $docref   := request:get-parameter("doc", "");
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

let $list := 
    for $doc in collection(concat($database,'/',$datadir,'/',$coll))/m:mei
    where util:document-name($doc)=$filename
    return $doc

let $title := $list//m:workList/m:work[1]/m:title[string()][1]/string()

let $rec_type := string-join($list//m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]/string()," ")   

let $result :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>{$title} – DSL</title>
        <meta charset="UTF-8"/>
        <link rel="stylesheet" type="text/css" href="https://static.ordnet.dk/app/go_smn_app.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/fix_go_collisions.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/elements.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/layout.css" />
    	<link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/styles.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/print.css" media="print" />
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
        
        <!--<link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />-->
        <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css" />
        
        <!-- User interaction settings -->
        <script type="text/javascript">
            var enableMenu = true;      // show options menu
            var enableLink = false;     // do not show links to melody database (i.e., to this page)
            var enablePrint = true;     // show link to print version
            var enableMidi = true;      // enable MIDI player
            var enableOptions = true;   // show melody customizations options menu
            var enableSearch = true;    // enable phrase marking for melodic search 
            var enableComments = true;  // show editorial comments
        </script>   
        
        <!-- Note highlighting only works with jQuery 3+ -->
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js"><!-- jquery --></script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js"><!-- jquery ui --></script>     
        <script type="text/javascript" src="js/libs/verovio/2.0.2-95c61b2/verovio-toolkit.js"><!-- Verovio --></script>
        <!-- alternatively use CDNs, like: -->
        <!--<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://code.jquery.com/ui/1.12.1/jquery-ui.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/latest/verovio-toolkit.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/develop/verovio-toolkit.js">/* */</script>-->
        <script src="js/MeiAjax.js"><!-- MEI tools --></script>

	    <!-- MIDI -->        
        <!--<script src="js/wildwebmidi.js"> MIDI library </script>-->
        <script src="js/libs/wildwebmidi/074_recorder.js"><!-- MIDI library --></script>
        <script src="js/midiplayer.js"><!-- MIDI player --></script>
        <script src="js/midiLib.js"><!-- custom MIDI library --></script>
        <!--<script type="text/javascript">
            enableMidi = false; 
        </script>-->

	</head>
	<body class="frontpage metadata">
	

	   <!-- Page head -->
	   {doc(concat($database,"/assets/page_head.html"))}
	   
	   <!-- Search -->
	   <div class="searchWrapper search subpage-search {$rec_type}">
    	    <div class="search_options search-bg container row">
    	       <form action="mei_search.xq" method="get" class="form" id="title_form">
            	   <p><label class="input-label left-margin" for="pnames">Titelsøgning</label>
                   <input name="x" id="x1" type="hidden" value=""/>
                   <input name="qt" id="query_title" type="text" value="" class="search-text input"/>
                   <img src="https://tekstnet.dk/static/info.png" alt="hint" title="Skriv titel eller del af en titel"/>
                   <input type="submit" value="Søg" class="search-button box-gradient-green"
                   onclick="this.form['x'].value = updateAction();"/>                                       
                       <br/>
                   </p>
                   <p>
                       <label class="input-label left-margin">&#160;</label>{doc("assets/title_select.html")   (: or generate dynamically with: local:get_titles() :)}
                   </p>
                    <div class="text-row">
                       <a href="mei_search.xq" id="advanced-search-link">Avanceret søgning</a>
                    </div>
               </form>
    	    </div>
        </div>

        <div class="documentFrame container">
            <!-- Metadata -->
            {
                let $metadata := if(count($list) = 0) 
                    then
                        <div>
                            <p>{$filename} blev ikke fundet i databasen.</p>
                            <p><a href="javascript:window.history.back();">Tilbage til foregående side</a></p>
                        </div>
                    else 
                        <div id="mei_metadata" class="mei_metadata">
                            <p class="loading">[Henter metadata...]</p>
                        </div>
                return $metadata                    
            }
            {
                let $chapters := if($tei_doc) then $tei_doc/tei:TEI/tei:text/tei:body/tei:div else () 
                let $tekstnet_link := if($chapters[.//tei:notatedMusic/tei:ptr[@target=$filename or substring-before(@target,'#')=$filename]]) 
                    then
                        let $chapter as xs:integer := count($chapters[.//tei:notatedMusic/tei:ptr[@target=$filename or substring-before(@target,'#')=$filename]]/preceding-sibling::tei:div) + 1
                        (: Use section only if there is more than one  :)
                        let $section as xs:string := if(count($chapters[$chapter]/tei:div/tei:head[@type="add"]) > 1)
                            then
                                concat("/",count($chapters[$chapter]/tei:div/tei:head[@type="add"][following::tei:notatedMusic/tei:ptr[@target=$filename or substring-before(@target,'#')=$filename]]))
                            else 
                                ""
                        let $tei_name as xs:string := substring-before($index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei/string(),".xml") 
                        return <p><a href="https://tekstnet.dk/{$tei_name}/{$chapter}{$section}">&gt; Digital udgave på tekstnet.dk</a></p>
                    else
                        ""
                return $tekstnet_link
            }
        </div>
        
        <div class="documentFrame container">
            <!-- Music and text -->
            {  
            	for $mdiv at $pos in $list[1]//m:mdiv
                	let $include_data := 
                	   if($pos=1) then true() else false()   
                	(:   false()   :)
                	let $params := 
                    	<parameters>
                    	  <param name="mdiv" value="{$mdiv/@xml:id}"/>
                    	  <param name="doc"  value="{$filename}"/>
                    	  <!--<param name="include_data" value="{$include_data}"/>-->
                    	</parameters>
                	let $music := transform:transform($list[1],$mdivXsl,$params)
                	let $text := if($coll!="" and doc-available(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei)))
                	   then 
                    	   <div id="tei_vocal_text_{$mdiv/@xml:id}" class="tei_vocal_text {$tei_doc_name} {$mdiv/@xml:id}">
                    	       <!-- References to TEI file and MEI:mdiv/@xml:id transmitted in @class -->
                               <p class="loading">[Henter tekst...]</p>
                           </div>
                	   else 
                	       <div>
                               <p>Tekst ikke fundet i databasen.</p>
                           </div>
                return ($music, $text)  
            }
        </div>


        <div style="height: 30px;">
            <!-- MIDI Player -->
            <div id="player" style="z-index: 20; position: absolute;"/>
        </div>
    </body>
</html>

return $result