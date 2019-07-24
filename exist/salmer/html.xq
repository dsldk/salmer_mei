xquery version "3.1";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk";
declare namespace transform = "http://exist-db.org/xquery/transform";

declare option exist:serialize "method=html5 media-type=text/html"; 

declare variable $tei_base      := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/";
(: Local test:  :)
(: declare variable $tei_base      := xs:anyURI(concat("http://",request:get-header('HOST'),"/exist/rest/db/tools/html/"));  :)
declare variable $tei_xslt_base := xs:anyURI(concat("http://",request:get-header('HOST'),"/exist/rest/db/tools/html/xslt/"));

declare variable $tei := request:get-parameter("tei", "");
declare variable $books := 
    <books xmlns="http://dsl.dk">
        <!--<book>
            <title>TEST</title>
            <tei>thomissoen_test.xml</tei>
            <mei>Th_1569</mei>
        </book>-->
        <book>
            <title>Det kristelige messeembede (Mortensøn, 1528)</title>
            <tei>claus-mortensen-messe-1528.xml</tei>
            <mei>Mo_1528</mei>
        </book>
        <book>
            <title>Haandbog i det evangeliske messeembede (Ulricksøn, 1535)</title>
            <tei>oluf-ulriksen-messe-1535.xml</tei>
            <mei>Ul_1535</mei>
        </book>
        <book>
            <title>Håndbog om den rette evangeliske Messe (Vormordsen/Ulricksøn, 1539)</title>
            <tei>oluf-ulriksen-messehaandbog-1539.xml</tei>
            <mei>Vo_1539</mei>
        </book>
        <book>
            <title>En Ny Psalmebog (Vingaard, 1553)</title>
            <tei>vingaard_1553.xml</tei>
            <mei>Vi_1553</mei>
        </book>
        <book>
            <title>Den danske Psalmebog (Thomissøn, 1569)</title>
            <tei>thomissoen_1569.xml</tei>
            <mei>Th_1569</mei>
        </book>
        <book>
            <title>Graduale (Jespersen, 1573)</title>
            <tei>jespersen_1573.xml</tei>
            <mei>Je_1573</mei>
        </book>
    </books>;

let $output := if (normalize-space($tei)) then
    let $doc := doc(concat($tei_base, $tei))
    (: tilføj betingelse her: hvis $tei begynder med http://, så spring $tei_base over)  :)
    
    let $params := <parameters/>
    let $transformed := transform:transform($doc,xs:anyURI(concat("http://",request:get-header('HOST'),"/exist/rest/db/tools/html/xslt/main.xsl")),$params)
    (:let $transformed := transform:transform(doc(concat($tei_base, $tei)),xs:anyURI(concat($tei_xslt_base,"main.xsl")),$params):)
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
                            for $book in $books/dsl:book 
                            return <option value="{$book/dsl:tei}">{$book/dsl:title}</option>
                        }
                    </select>
                </div>
            </form>
        </body>
    </html>

return $output
    