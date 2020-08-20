xquery version "3.0" encoding "UTF-8";

import module namespace settings="http://dsl.dk/salmer/settings" at "./settings.xqm";
import module namespace search="http://dsl.dk/salmer/search" at "./simple_search.xqm";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/salmer";  

(: Set language :)
let $language := settings:language(request:get-parameter("language", ""))
let $l := doc(concat('library/language/',$language,'.xml'))/*[1]    (: Localisation of labels etc. :)   

let $content := if (doc(concat("texts/guidelines_",$language,".html")))
    then doc(concat("texts/guidelines_",$language,".html"))
    else doc("texts/guidelines_da.html")

let $output :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>{$l/*[name()='page_title_guidelines']/text()}</title>
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

        <script type="text/javascript" src="js/javascript.js">/* Text site js */</script>
        <script type="text/javascript" src="js/general.js">/* utilities */</script>

        <script type="text/javascript">
            language = "{$language}";
        </script>

	</head>
	<body class="metadata">
	
       <header class="header" id="header">
       
            <!-- Page head -->
	        {doc(concat($database,"/assets/header_",$language,".html"))}
	       
            <!-- Search -->
            {search:searchbox($l)}

	   </header>
        
	   <!-- page content -->
       {$content}

	   <!-- Page footer -->
	   {doc(concat($database,"/assets/footer_",$language,".html"))}

    </body>
</html>

return $output