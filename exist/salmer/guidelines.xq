xquery version "3.0" encoding "UTF-8";

import module namespace settings="http://dsl.dk/salmer/settings" at "./settings.xqm";
import module namespace search="http://dsl.dk/salmer/search" at "./simple_search.xqm";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/salmer";  

(: Set language :)
let $language := settings:language(request:get-parameter("language", ""))
let $l := doc(concat('library/language/',$language,'.xml'))    (: Localisation of labels etc. :)   

let $content := if (doc(concat("texts/guidelines_",$language,".html")))
    then doc(concat("texts/guidelines_",$language,".html"))
    else doc("texts/guidelines_da.html")

let $output :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>Vejledning – Salmemelodier – DSL</title>
        <meta charset="UTF-8"/>
        
        
        <link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />
        
        <link rel="stylesheet" type="text/css" href="style/dsl-basis_screen.css" />
        <link rel="stylesheet" type="text/css" href="style/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="style/elements.css" />
        <link rel="stylesheet" type="text/css" href="style/select-css.css" />
        <link rel="stylesheet" type="text/css" href="style/layout.css" />
        <link rel="stylesheet" type="text/css" href="style/styles.css"/>
        <link rel="stylesheet" type="text/css" href="style/dsl-basis_print.css" media="print"/>
        <link rel="stylesheet" type="text/css" href="style/print.css" media="print"/>
        
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     

        <script type="text/javascript" src="js/javascript.js">/* "Tekstnet" JS */</script>

        
	</head>
	<body class="metadata">
	
       <header class="header" id="header">
       
            <!-- Page head -->
	        {doc(concat($database,"/assets/header.html"))}
	       
            <!-- Search -->
            {search:searchbox()}

	   </header>
        
	   <!-- page content -->
       {$content}

	   <!-- Page footer -->
	   {doc(concat($database,"/assets/footer.html"))}

    </body>
</html>

return $output