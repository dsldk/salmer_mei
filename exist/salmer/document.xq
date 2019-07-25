xquery version "3.0" encoding "UTF-8";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $document := request:get-parameter("doc", "");
declare variable $host     := concat(request:get-header('HOST'),'/exist/rest'); (: "localhost";  :)
declare variable $language := request:get-parameter("language", "");
declare variable $head     := request:get-parameter("head", "Musik og tekst i reformationstidens danske salmesang");

declare variable $tei_base := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/";
declare variable $database := "/db/salmer";
declare variable $datadir  := "data";
declare variable $coll     := string-join(tokenize($document, '/')[position() lt last()], '/');
declare variable $filename := tokenize($document, '/')[position() = last()];
declare variable $metaXsl  := doc(concat($database,"/xsl/metadata_to_html.xsl"));
declare variable $mdivXsl  := doc(concat($database,"/xsl/mdiv_to_html.xsl"));
declare variable $textXsl  := doc(concat($database,"/xsl/tei_text_to_html.xsl"));
declare variable $index    := doc(concat($database,"/index/publications.xml"));

let $tei_doc  := if($coll!="" and doc-available(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei)))
    then 
        doc(concat($tei_base,$index//dsl:pub[dsl:mei_coll=$coll][1]/dsl:tei))
    else 
    (: TEI file or TEI file name not found; try to guess the collection name from the MEI file name. :)
    (: Works only if the MEI file name contains the collection name (e.g., Th_1569_LN1426_001r.xml is in collection Th_1569) :)
    if(doc-available(concat($tei_base,$index//dsl:pub[contains($filename,dsl:mei_coll)][1]/dsl:tei)))
        then 
            doc(concat($tei_base,$index//dsl:pub[contains($filename,dsl:mei_coll)][1]/dsl:tei))
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

let $result :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>{$title} – DSL</title>
        <meta charset="UTF-8"/>
        <link rel="stylesheet" type="text/css" href="https://static.ordnet.dk/app/go_smn_app.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/fix_go_collisions.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/elements.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/layout.css" />
    	<link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/styles.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/print.css" media="print" />
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
        
        <!--<link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />-->
        <link rel="stylesheet" href="http://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css" />
        
        <!-- User interaction settings -->
        <script type="text/javascript">
            var enableMenu = true;      // show options menu
            var enableLink = false;     // do not show links to melody database (i.e., to this page)
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

	</head>
	<body class="frontpage metadata">
	
	
<!--<div style="border: 1px solid black; width:80%; height: 200px; overflow:scroll;" id="debug">
Debug here
</div>-->

	   <div class="wait_overlay"><!-- overlay for progress/wait cursor --></div>
	
	   <!-- Page head -->
	   {doc(concat($database,"/assets/page_head.html"))}
	   
	   <!-- Search -->
	   <div class="searchWrapper box-gradient-blue search subpage-search">
    	    <div class="search_options search-bg container row">
    	       <form action="mei_search.xq" method="get" class="form" id="pitch_form">
            	   <p><label class="input-label left-margin" for="pnames">Melodisøgning</label>
                   <input name="x" id="x1" type="hidden" value=""/>
                   <input type="text" name="q" id="pnames" value="" class="search-text input"/> 
                   <img src="https://tekstnet.dk/static/info.png" 
                    title="Søg efter en bestemt tonefølge, f.eks. 'CDEF'.
H skrives B.            	        
Altererede toner skrives således: 
cis: V, es: W, fis: X, as: Y, b: Z"/>
                   <input type="submit" value="Søg" class="search-button box-gradient-green"
                   onclick="this.form['x'].value = updateAction();"/></p>
                                       
                    <div class="text-row">
                       <a href="mei_search.xq" id="advanced-search-link">Avanceret søgning</a>
                    </div>
                                       
               </form>
    	    </div>
        </div>

        <div class="documentFrame container">
            <!-- Metadata -->
            {  
            	for $doc in $list
                	let $params := 
                    	<parameters>
                    	  <param name="hostname"    value="{$host}"/>
                    	  <param name="database"    value="{$database}"/>
                    	  <param name="datadir"     value="{$datadir}"/>
                    	  <param name="database"    value="{$database}"/>
                    	  <param name="coll"        value="{$coll}"/>
                    	  <param name="filename"    value="{$filename}"/>
                    	  <param name="doc"         value="{concat($database,'/',$datadir,'/',$document)}"/>
                    	  <param name="script_path" value="./document.xq"/>
                    	  <param name="language"    value="{$language}"/>
                    	</parameters>
            	return transform:transform($doc,$metaXsl,$params)            	
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