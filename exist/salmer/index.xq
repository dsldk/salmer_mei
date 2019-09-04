xquery version "3.0" encoding "UTF-8";

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


<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>Salmebasen – DSL</title>
        <meta charset="UTF-8"/>
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

	</head>
	<body class="frontpage metadata">
	
	
	   <!-- Page head -->
	   {doc(concat($database,"/assets/page_head.html"))}
	   
	   <!-- Search -->
	   <div class="searchWrapper box-gradient-blue search subpage-search">
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
                       <label class="input-label left-margin">&#160;</label>{doc("assets/title_select.html")}
                   </p>
                    <div class="text-row">
                       <a href="mei_search.xq" id="advanced-search-link">Avanceret søgning</a>
                    </div>
               </form>
    	    </div>
        </div>

        <div class="documentFrame container">
            <h1>Salmebasen</h1>
            <p>DSL's salmebase sammenfatter de melodier, der indgår i salmebøgerne i projektet <a href="https://dsl.dk/projekter/musik-og-sprog-i-reformationstidens-danske-salmesang" title="Musik og 
            sprog i reformationstidens danske salmesang">Musik og sprog i reformationstidens danske salmesang</a>. Det er hensigten, at salmebasen skal illustrere sammenhænge på tværs af de enkelte publikationer
            og give supplerende historiske oplysnigner og henvisninger til andre ressourcer med relationer til melodierne.
            </p>
            <p>Melodierne i salmebasen kan findes enten ved at slå titlerne op ovenfor eller ved at søge i selve musikken her:</p>
            <ul>
                <li><a href="http://salmer.dsl.dk/mei_search.xq" title="Slå op i salmebasen">Find melodier i salmebasen (avanceret søgning)</a></li>
            </ul>
            <p>En anden indgang til salmerne er de digitale udgaver af de salmebøger, der er omfattet af projektet:</p>
            <ul>
                <li><a href="https://tekstnet.dk/claus-mortensen-messe-1528/metadata" title="Det kristelige messeembede (1528)">Det kristelige messeembede (Claus Mortensen, 1528)</a></li>
                <li><a href="https://tekstnet.dk/oluf-ulriksen-messe-1535/metadata" title="Haandbog i det evangeliske messeembede (1535)">Håndbog i det evangeliske messeembede (Oluf Ulriksen, 1535)</a></li>
                <li><a href="https://tekstnet.dk/oluf-ulriksen-messehaandbog-1539/metadata" title="Håndbog om den rette evangeliske Messe (1539)">Håndbog om den rette evangeliske Messe (Oluf Ulriksen, 1539)</a></li>
                <li><a href="https://tekstnet.dk/vingaard_1553/metadata" title="En Ny Psalmebog (1553)">En Ny Psalmebog (1553)</a></li>
                <li><a href="https://tekstnet.dk/thomissoen_1569/metadata" title="Den Danske Psalmebog (1569)">Den danske Psalmebog (Hans Thomissøn, 1569)</a></li>
                <li><a href="https://tekstnet.dk/jespersen_1573/metadata" title="Graduale (1573)">Graduale (Niels Jespersen, 1573)</a></li>
            </ul>
            <p>Hver melodi i udgaverne er forsynet med en menu, som bl.a. giver mulighed for at slå melodien op i salmebasen.</p>
        
        
        
        </div>

        
    </body>
</html>

