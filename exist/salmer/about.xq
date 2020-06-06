xquery version "3.0" encoding "UTF-8";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/salmer";  

let $output :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>Om salmemelodibasen – DSL</title>
        <meta charset="UTF-8"/>
        
        
        <link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />
        
        <link rel="stylesheet" type="text/css" href="style/magenta/dsl-basis_screen.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/elements.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/select-css.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/layout.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/styles.css"/>
        <link rel="stylesheet" type="text/css" href="style/magenta/dsl-basis_print.css" media="print"/>
        <link rel="stylesheet" type="text/css" href="style/magenta/print.css" media="print"/>
        
        <link rel="stylesheet" type="text/css" href="style/magenta/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
        
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     

        <script type="text/javascript" src="js/magenta/javascript.js">/* "Tekstnet" JS */</script>

        
	</head>
	<body class="metadata">
	
       <header xmlns="http://www.w3.org/1999/xhtml" class="header" id="header">
       
            <!-- Page head -->
	        {doc(concat($database,"/assets/magenta/header.html"))}
	       
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
                                    <button title="Søg" class="btn btn-primary arrow-r" type="submit" onclick="this.form['x'].value = updateAction();"/>
                                    <input name="x" id="x1" type="hidden" value=""/>
                                </div>
                            </form>
                            <div>
                                {doc("assets/magenta/title_select.html")   (: or generate dynamically with: local:get_titles() :)}
                            </div>
                            <div id="advanced-search-link">
                                <a href="mei_search.xq">Avanceret søgning</a>
                            </div>
                        </div>
                </div>
            </div>

	   </header>
	   
       <div class="page-wrapper">
            <div class="background-box">
                <div class="headline-box container">
                    <h2>Om melodibasen</h2>
                </div>
            </div>
            
            <div class="container">
                <p>Salmemelodi-databasen indgår i webstedet 
                <a href="https://tekstnet.dk/search?category=reformationstiden"><em>Danske Reformationssalmer. Melodier 
                og tekster 1529-1573</em></a>. Databasen supplerer den digitale udgave af 1500-tallets danske salme- og messebøger
                med information om de melodier, der optræder i materialet.</p>
                <h3>Organisation</h3>
                <p> Det Danske Sprog- og Litteraturselskab<br /> Christians Brygge 1<br /> 1219 København
                    K<br /> Tlf. 33 13 06 60<br />
                </p>
                <p>Skriv til: <a href="mailto:man@dsl.dk">man@dsl.dk</a></p>
                <h3>Redaktion (DSL)</h3>
                <p>Ledende redaktør: Marita Akhøj Nielsen</p>
                <p>Filologisk redaktion: Simon Skovgaard Boeck (fra 2020), Bjarke Moe og Mette-Marie Møller Svendsen</p>
                <p>IT-udvikling: Axel Teich Geertinger, Thomas Hansen (DSL) og
                    IT-udviklingsfirmaet <a href="https://www.magenta.dk/" target="_blank">Magenta</a>
                </p>
                <h3>Tilsynsførende</h3>
                <p>Fagligt tilsyn, DSL: Dorthe Duncker, Anne Mette Hansen, Ebba Hjorth og Inger Sørensen</p>
                <p><img src="/style/img/Carlsbergfondet-DK-logo_RGB.png" title="Carlsbergfondet" alt="Carlsbergfondet" style="margin-top: 25px"/></p>
            </div>

        </div>
	    <!-- Page footer -->
	    {doc(concat($database,"/assets/magenta/footer.html"))}

    </body>
</html>

return $output