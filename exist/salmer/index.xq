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

let $output :=
    
    <html xmlns="http://www.w3.org/1999/xhtml">
    	<head>
    	    <title>Melodibasen – Danske reformationssalmer - DSL</title>
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
            <!--<link rel="stylesheet" type="text/css" href="style/mei_search.css"/>-->
            
            <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
            <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     
    
            <script type="text/javascript" src="js/javascript.js">/* "Tekstnet" JS */</script>
    
    
    	</head>
    	<body class="frontpage metadata">
        
        
           <header class="header" id="header">
           
                <!-- Page head -->
    	        {doc(concat($database,"/assets/header.html"))}
    	       
                <!-- Search -->
                {search:searchbox()}
    
    	   </header>
    	   
          <div id="front-page-splash" class="main-top-section background-cover bg-print-none wrapper">
                
               
                <div class="container">
                
                    <div class="library">
                
                        <div class="col-sm-4 library__item">
                            <div class="library__item-head">
                              <div class="library__item-icon">
                                <img src="/style/img/publication.svg" alt=""/>
                              </div>
                              <h3 class="library__item-title">Salme- og messebøger</h3>
                            </div>
                            <p>
                                Se melodierne i de enkelte publikationer: 
                                <!--Basen indeholder melodier fra følgende publikationer:-->
                            </p>
                            <p>
                                {local:list-publications()}
                            </p>
                        </div>
    
                        <div class="col-sm-4 library__item">
                            <div class="library__item-head">
                              <div class="library__item-icon">
                                <img src="/style/img/search.png" alt=""/>
                              </div>
                              <h3 class="library__item-title">Melodisøgning</h3>
                            </div>
                            <p>Find melodierne ved at slå titlerne op eller ved at søge i selve musikken</p>
                            <div class="library__item-link">
                              <a href="/mei_search.xq" class="btn btn-primary arrow-r"><span class="sr-only">Gå til søgesiden</span></a>
                            </div>
                        </div>
                        
                        <div class="col-sm-4 library__item">
                            <div class="library__item-head">
                              <div class="library__item-icon">
                                <img src="/style/img/book.svg" alt=""/>
                              </div>
                              <h3 class="library__item-title">Digitale udgaver</h3>
                            </div>
                            <p>Tekstkritiske udgaver af Danmarks første salmebøger, messebøger og Bibel med noder, ordbog og indledninger</p>
                            <p>(åbner i et nyt vindue)</p>
                            <div class="library__item-link">
                              <a href="https://tekstnet.dk/search?category=reformationstiden" target="_blank" class="btn btn-primary arrow-r"><span class="sr-only">Gå til tekstoversigt</span></a>
                            </div>
                        </div>
                        
                    
                    </div>
            
                </div>
            
            </div>
    
    	</body>
    </html>

return $output
