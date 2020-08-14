xquery version "3.0" encoding "UTF-8";

import module namespace settings="http://dsl.dk/salmer/settings" at "./settings.xqm";
import module namespace search="http://dsl.dk/salmer/search" at "./simple_search.xqm";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace dsl = "http://dsl.dk";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $host     := concat(request:get-header('HOST'),'/exist/rest'); (: "localhost";  :)
declare variable $language := request:get-parameter("language", "");
declare variable $head     := request:get-parameter("head", "Musik og tekst i reformationstidens danske salmesang");
declare variable $database := "/db/salmer";
declare variable $publications  := doc('library/publications.xml'); 


declare function local:full-title($id as xs:string) as node()* {
    let $title := 
        for $p in $publications/dsl:publications/dsl:pub
        where $p/dsl:id = $id
        return <span xmlns="http://www.w3.org/1999/xhtml" class="link-text">{$p/dsl:editor/string()}, <em>{$p/dsl:title/string()}</em> ({$p/dsl:year/string()})</span>
    return $title
};


declare function local:list-publications() as node()* {
    let $titles := 
        for $p in $publications/dsl:publications/dsl:pub
        where normalize-space($p/dsl:mei_coll)
        return 
            <div xmlns="http://www.w3.org/1999/xhtml" >
                <a href="document.xq?doc={$p/dsl:mei_coll}/{$p/dsl:id}.xml" class="list-link-a">
                    <div class="btn btn-primary arrow-r list-link"><!-- link marker --></div>
                    {local:full-title($p/dsl:id)}
                </a>
            </div>
    return $titles
};

(: Set language :)
let $language := settings:language(request:get-parameter("language", ""))
let $l := doc(concat('library/language/',$language,'.xml'))/*[1]    (: Localisation of labels etc. :)   

let $content := if (doc(concat("texts/index_",$language,".html")))
    then doc(concat("texts/index_",$language,".html"))
    else doc("texts/index_da.html")

let $output :=
    
    <html xmlns="http://www.w3.org/1999/xhtml">
    	<head>
    	    <title>{$l/*[name()='page_title_general']/text()}</title>
            <meta charset="UTF-8"/>
            
            <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png"/>
            <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png"/>
            
            <link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />
            
            <link rel="stylesheet" type="text/css" href="style/dsl-basis_screen.css" />
            <link rel="stylesheet" type="text/css" href="style/bootstrap.min.css" />
            <link rel="stylesheet" type="text/css" href="style/elements.css" />
            <link rel="stylesheet" type="text/css" href="style/select-css.css" />
            <link rel="stylesheet" type="text/css" href="style/styles.css"/>
            <link rel="stylesheet" type="text/css" href="style/dsl-basis_print.css" media="print"/>
            <link rel="stylesheet" type="text/css" href="style/print.css" media="print"/>
            
            <link rel="stylesheet" type="text/css" href="style/mei.css"/>
            
            <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
            <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     
    
            <script type="text/javascript" src="js/javascript.js">/* "Tekstnet" JS */</script>
            <script type="text/javascript" src="js/general.js">/* utilities */</script>

            <script type="text/javascript">
                language = "{$language}";
            </script>

    	</head>
    	<body class="frontpage metadata">
        
        
           <header class="header" id="header">
           
                <!-- Page head -->
    	        {doc(concat($database,"/assets/header_",$language,".html"))}
    	       
                <!-- Search -->
                {search:searchbox($l)}
    
    	   </header>
    	   
    	   <!-- page content -->
           {$content}
        
    	</body>
    </html>

return $output
