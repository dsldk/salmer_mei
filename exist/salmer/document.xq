xquery version "3.0" encoding "UTF-8";

declare namespace h="http://www.w3.org/1999/xhtml";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace app="http://kb.dk/this/app";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace m="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $document := request:get-parameter("doc", "");
declare variable $host     := concat(request:get-header('HOST'),'/exist/rest'); (: "localhost";  :)
declare variable $language := request:get-parameter("language", "");

(: to be eliminated: :)
declare variable $score    := request:get-parameter("score", "");


declare variable $database := "/db/salmer";
declare variable $datadir  := "data";
declare variable $coll     := string-join(tokenize($document, '/')[position() lt last()], '/');
declare variable $filename := tokenize($document, '/')[position() = last()];
declare variable $xsl      := doc(concat($database,"/xsl/mei_to_html_public.xsl"));
declare variable $head     := request:get-parameter("head", "Musik og tekst i reformationstidens danske salmesang");

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
            var enableMidi = true;
            var enableSearch = true;
            var enableMenu = true;
            var enableComments = true;
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

        <script src="js/MeiLib.js"><!-- MEI tools --></script>

	    <!-- MIDI -->        
        <script src="js/wildwebmidi.js"><!-- MIDI library --></script>
        <script src="js/midiplayer.js"><!-- MIDI player --></script>
        <script src="js/midiLib.js"><!-- custom MIDI library --></script>

        <script type="text/javascript" src="js/libs/Saxon-CE_1.1/Saxonce/Saxonce.nocache.js"><!-- Saxon CE --></script>

	</head>
	<body class="frontpage">
	   {doc(concat($database,"/assets/page_head.html"))}
	   <div class="searchWrapper box-gradient-blue search">
    	    <div class="search_options search-bg">{$head}</div>
        </div>
        <div class="documentFrame container">
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
            	  <param name="score"       value="{$score}"/>
            	</parameters>
            	return transform:transform($list[1],$xsl,$params)            	
              }
        </div>
        
        <!--<textarea rows="10" cols="80" id="debug_text"></textarea>-->
        <div style="height: 30px;">
            <!-- MIDI Player -->
            <div id="player" style="z-index: 20; position: absolute;"/>
        </div>
    </body>
</html>

return $result