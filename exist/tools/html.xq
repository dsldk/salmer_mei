xquery version "3.1";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk";
declare namespace transform = "http://exist-db.org/xquery/transform";

declare option exist:serialize "method=html5 media-type=text/html"; 

(: read TEI documents from salmer.dsl.lan: :)
declare variable $tei_base      := "http://salmer.dsl.lan:8080/exist/apps/salmer/xml/";
(: read TEI documents from Github: :)
(:declare variable $tei_base      := "https://raw.githubusercontent.com/dsldk/salmer_data/develop/xml/"; :)
(: Locally: :)
(: declare variable $tei_base      := "/db/salmer/data-tei/"; :)  
declare variable $tei_xslt_base := "/db/tools/html/xslt/";

declare variable $tei := request:get-parameter("tei", "");
declare variable $database := "/db/salmer";  
declare variable $books := doc(concat($database,"/library/publications.xml"));

let $output := if (normalize-space($tei)) then
    let $doc := doc(concat($tei_base, $tei))
    (: tilføj evt. betingelse her: hvis $tei begynder med http://, så spring $tei_base over)  :)
    
    let $params := <parameters/>
    let $transformed := transform:transform($doc,"http://melodier.dsl.lan:8080/exist/rest/db/tools/html/xslt/main.xsl",$params)
    return $transformed
else    
    <html>
    	<head>
    	    <title>Gennemse tekst</title>
            <meta charset="UTF-8"/> 
    	</head>
    	<body style="margin: 20px; background-image: none;" onload="document.getElementById('tei').value='{$tei}';">
        	<form method="get" action="" style="background-color: #eee; margin: -20px -20px 3px -20px; padding: 5px 20px; position:fixed; width: 100%; height: 50px;">
                <div>Vælg tekst: 
                    <select name="tei" id="tei" onchange="this.form.submit(); return false;" style="margin-bottom: 10px;">
                        <option value=""/>
                        {
                            for $book in $books//dsl:pub 
                            return <option value="{$book/dsl:tei}">{$book/dsl:title}</option>
                        }
                    </select>
                </div>
            </form>
        </body>
    </html>

return $output
    