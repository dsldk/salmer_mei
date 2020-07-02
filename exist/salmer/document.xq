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
(: declare variable $metaXsl  := doc(concat($database,"/xsl/metadata_to_html.xsl")); :)
declare variable $mdivXsl  := doc(concat($database,"/xsl/mdiv_to_html.xsl"));
declare variable $textXsl  := doc(concat($database,"/xsl/tei_text_to_html.xsl"));
declare variable $index    := doc(concat($database,"/library/publications.xml"));
declare variable $l        := doc('library/language/da.xml');    (: Localisation of labels etc. :)   


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

let $tei_doc_name := if($coll!="")
    then 
        $index//dsl:pub[dsl:mei_coll=$coll]/dsl:tei
    else 
        ""

let $tei_doc := if($tei_doc_name!="" and doc-available(concat($tei_base,$tei_doc_name)))
    then 
        doc(concat($tei_base,$tei_doc_name))
    else 
        false()

let $list := 
    for $doc in collection(concat($database,'/',$datadir,'/',$coll[1]))/m:mei
    where util:document-name($doc)=$filename
    return $doc

let $title := $list//m:workList/m:work[1]/m:title[string() and (@type="uniform" or not(../m:title[@type="uniform"]))][1]/string()

let $rec_type := if($list/m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"])
    then 
        string-join($list/m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]/string()," ")
    else "music_document"
        

let $result :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>{$title} – DSL</title>
        <meta charset="UTF-8"/>
        
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png"/>
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png"/>
        
        <link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />
        
        <link rel="stylesheet" type="text/css" href="style/dsl-basis_screen.css" />
        <link rel="stylesheet" type="text/css" href="style/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="style/elements.css" />
        <link rel="stylesheet" type="text/css" href="style/select-css.css" />
        <link rel="stylesheet" type="text/css" href="style/styles.css"/>
        <!--<link rel="stylesheet" type="text/css" href="style/dsl-basis_print.css" media="print"/>
        <link rel="stylesheet" type="text/css" href="style/print.css" media="print"/>-->
        
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
                
        <!-- User interaction settings -->
        <script type="text/javascript">
            var enableMenu = true;              // show options menu
            var enableLink = false;             // do not show links to melody database (i.e., to this page)
            var enablePrint = true;             // show link to print version
            var enableMidi = true;              // enable MIDI player
            var enableMidiDownload = true;      // enable MIDI download
            var enableOptions = true;           // show melody customizations options menu
            var enableSearch = true;            // enable phrase marking for melodic search 
        </script>   
        
        <!-- Note highlighting only works with jQuery 3+ -->
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     
        <script type="text/javascript" src="js/libs/verovio/verovio-toolkit.js">/* Verovio */</script>
        <!-- alternatively use CDNs, like: -->
        <!--<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://code.jquery.com/ui/1.12.1/jquery-ui.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/latest/verovio-toolkit.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/develop/verovio-toolkit.js">/* */</script>-->
        <script type="text/javascript" src="js/MeiAjax.js"><!-- MEI tools --></script>

        <script type="text/javascript" src="js/javascript.js">/* "Tekstnet" JS */</script>


	    <!-- MIDI -->        
        <!--<script src="js/wildwebmidi.js"> MIDI library </script>-->
        <script type="text/javascript" src="js/libs/wildwebmidi/074_recorder.js"><!-- MIDI library --></script>
        <script type="text/javascript" src="js/midiplayer.js"><!-- MIDI player --></script>
        <script type="text/javascript" src="js/midiLib.js"><!-- custom MIDI library --></script>

        <script type="text/javascript" src="js/FileSaver.js">/* js for file download */</script>
        
	</head>
	<body class="frontpage metadata">
	
	   <div id="wait" class="wait_overlay"><!-- "busyS" indicator overlay --></div>

       <header xmlns="http://www.w3.org/1999/xhtml" class="header" id="header">
       
            <!-- Page head -->
	        {doc(concat($database,"/assets/header.html"))}
	       
            <!-- Search -->
	           
            <div class="main-top-section background-cover">
                <div class="container">
                    <input type="checkbox" id="search-field-toggle"/>
                    <label for="search-field-toggle"><span class="sr-only">Vis/skjul søgefelt</span></label>
                        <div id="search-field">
                            <form action="mei_search.xq" method="get" id="search-mobile">
                                <div class="search-line input-group">
                                    <span class="input-group-addon"><img src="/style/img/search.png" alt=""/></span>
                                    <input id="query_title" type="text" class="form-control" name="qt" placeholder="Søg i salmetitlerne i databasen" value=""/>
                                    <button title="Søg" class="btn btn-primary arrow-r" type="submit"><!-- Søg --></button>
                                </div>
                            </form>
                            <div>
                                {doc("assets/title_select.html")   (: or generate dynamically with: local:get_titles() :)}
                            </div>
                            <div id="advanced-search-link">
                                <a href="mei_search.xq">Avanceret søgning</a>
                            </div>
                        </div>
                </div>
            </div>

	   </header>
	   
       <div class="page-wrapper">
            
            <!-- Enable critical comments -->
            <!--<label class="checkbox-inline" for="text-critical-note-checkbox">-->
              <input type="checkbox" id="text-critical-note-checkbox" data-toggle="appnote" checked="checked" style="display: none;"/>
            <!--  <span class="checkbox-label-text">Tekstkritik</span>
            </label>-->
            
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
                            <div class="container">
                                <p class="loading">Henter metadata...</p>
                            </div>
                        </div>
                return $metadata                    
            }

            <!-- Music and text -->

            <div class="documentFrame container">
                <!-- Music included in this document -->
                {  
                    for $mdiv at $pos in $list[1]//m:mdiv
                        let $params := 
                            <parameters>
                              <param name="mdiv" value="{$mdiv/@xml:id}"/>
                              <param name="doc"  value="{$filename}"/>
                            </parameters>
                        let $music := <div class="mei-wrapper">{transform:transform($list[1],$mdivXsl,$params)}</div>
                        let $text := if($coll!="" and doc-available(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei)))
                           then 
                               <div id="tei_vocal_text_{$mdiv/@xml:id}" class="tei_vocal_text {$tei_doc_name} {$mdiv/@xml:id}">
                                   <!-- References to TEI file and MEI:mdiv/@xml:id transmitted in @class -->
                                   <p class="loading">Henter tekst...</p>
                               </div>
                           else 
                               <div>
                                   <p>Tekst ikke fundet i databasen.</p>
                               </div>
                    return ($music, $text)  
                }
                <!-- Music included from related records (for melody meta records) -->
                {
                    for $embodiment at $pos in $list[1]//m:meiHead/m:workList/m:work/m:relationList/m:relation[@rel="hasEmbodiment" and not(contains(@target,"://"))]
                        let $this_doc_uri := concat($database,'/',$datadir,'/',$embodiment/@target) 
                        let $this_doc := doc($this_doc_uri)
                        let $output :=
                            for $mdiv at $pos in $this_doc/m:mei//m:mdiv
                                let $this_filename := util:document-name($this_doc)
                                let $params := 
                                    <parameters>
                                      <param name="mdiv" value="{$mdiv/@xml:id}"/>
                                      <param name="doc"  value="{$this_filename}"/>
                                    </parameters>
                                let $music := <div class="mei-wrapper">{transform:transform($this_doc,$mdivXsl,$params)}</div> 
                            return $music
                    return 
                        <div>
                            <h3>{$embodiment/@label/string()}</h3>
                            {$output}
                        </div>
                }
            </div>
            
        </div>

	    <!-- Page footer -->
	    {doc(concat($database,"/assets/footer.html"))}

        <div style="height: 30px;">
            <!-- MIDI Player -->
            <div id="player" style="z-index: 20; position: absolute;"/>
        </div>
        
        <!-- test
        <input type="button" onclick="javascript:comments = !comments; comments ? $('.textcriticalnote.annotation-marker').css('display','inline') : $('.textcriticalnote.annotation-marker').css('display','none');" value="Tekstkritik"/>
        test end -->
        
    </body>
</html>

return $result