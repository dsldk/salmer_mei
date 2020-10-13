xquery version "3.0" encoding "UTF-8";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace m = "http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/xml"; 

declare variable $database := '/db/salmer/data';
declare variable $tei_base := "https://raw.githubusercontent.com/dsldk/salmer_data/develop/xml/";
declare variable $mei_base := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/mei/";  
declare variable $tei := request:get-parameter("tei", "");
declare variable $books := 
    <books xmlns="http://dsl.dk">
        <book>
            <title>Jespersen 1573</title>
            <tei>jespersen_1573.xml</tei>
            <mei>Je_1573</mei>
        </book>
        <book>
            <title>Mortensøn 1529</title>
            <tei>claus-mortensen-messe-1529.xml</tei>
            <mei>Mo_1529</mei>
        </book>
        <book>
            <title>Thomissøn 1569</title>
            <tei>thomissoen_1569.xml</tei>
            <mei>Th_1569</mei>
        </book>
        <book>
            <title>Ulricksøn 1535</title>
            <tei>oluf-ulriksen-messe-1535.xml</tei>
            <mei>Ul_1535</mei>
        </book>
        <book>
            <title>Ulricksøn 1539</title>
            <tei>oluf-ulriksen-messehaandbog-1539.xml</tei>
            <mei>Vo_1539</mei>
        </book>
        <book>
            <title>Vingaard 1553</title>
            <tei>vingaard_1553.xml</tei>
            <mei>Je_1553</mei>
        </book>
    </books>;


declare function local:get_results($mei) {
    for $doc in collection($database)
    where substring(util:document-name($doc),1,string-length($mei)) = $mei
    order by util:document-name($doc)
    (: get local:  :)
    return $doc
    (: get remote:  :)
    (: return doc(concat($mei_base,$mei,'/',util:document-name($doc)))  :)
};

declare function local:syl_with_hyphen($syl) {
    let $conn := 
        if($syl/@wordpos="m" or $syl/@wordpos="t") then "-" else " "
    return concat($conn,normalize-space($syl))
};

declare function local:text_hyphenated($doc) {
    let $text := 
        for $measure in $doc//m:staff
            let $measure_text :=
                for $line_no in (1 to count($measure//(m:note | m:syllable)[1]/m:verse))
                    let $line :=
                        for $syl in $measure//m:verse[@n=$line_no]/m:syl
                        return local:syl_with_hyphen($syl)
                return <div xmlns="http://www.w3.org/1999/xhtml">{string-join($line,"")}</div>
            return $measure_text            
    return $text
};

declare function local:de-hyphen($text){
  for $e in $text//text()
  return  <div xmlns="http://www.w3.org/1999/xhtml">{translate($e,"-","")}</div>
};

declare function local:transform_tei($doc, $filename){
    let $params := 
    <parameters>
       <param name="hostname" value="{request:get-header('HOST')}"/>
       <param name="file" value="{$filename}"/>
    </parameters>
    return transform:transform($doc,xs:anyURI(concat("http://",request:get-header('HOST'),"/exist/rest/db/tools/korrektur/meloditekstkorrektur.xsl")),$params)
};


<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>DSL-meloditekstkorrektur</title>
        <meta charset="UTF-8"/> 
        <link rel="stylesheet" type="text/css" href="https://static.ordnet.dk/app/go_smn_app.css" />
        <link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/fix_go_collisions.css" />
        <link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/elements.css" />
        <link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/layout.css" />
    	<link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/styles.css" />
        <link rel="stylesheet" type="text/css" href="http://salmer.dsl.dk/static/print.css" media="print" />
        <script type="text/javascript" src="meloditekstkorrektur.js">
            <!-- some javascript -->
        </script>
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
        <table style="border: 0px; width: 100%; position: absolute; top: 50px">
            <tr>
                <td style="width: 60%; border: 0px">
        {   let $mei := $books/dsl:book[dsl:tei=$tei]/dsl:mei
            let $output :=
                if($mei != "") then
                    let $results := local:get_results($mei)
                    let $result_list :=
                    <div style="overflow-y: scroll; overflow-x: hidden; height: 85vh" id="mei">
                        <!--<p>{count($results)} resultat(er)</p>-->
                        <table style="width: 95%;">
                            <tr>
                                <th>Tekst med delestreger</th>
                                <th>Tekst uden delestreger</th>
                            </tr>
                            {
                                for $doc in $results
                                    let $text    := local:text_hyphenated($doc)
                                    let $anchor := substring-before(tokenize(util:document-name($doc),"_")[last()],'.xml')  
                                    let $heading := 
                                        <tr><td colspan="3">
                                            {util:document-name($doc)}&#160;
                                            <a href="javascript:void(0);" onclick="goto('{$anchor}');" name="mei_{$anchor}" 
                                            id="mei_{$anchor}" tabindex="1{translate($anchor,'rv','')}"
                                            title="Forsøg at finde stedet i TEI-dokumentet">[{$anchor}]</a>
                                        </td></tr>
                                    let $texts   := <tr>
                                                        <td>{$text}</td>
                                                        <td>{local:de-hyphen($text)}</td>
                                                    </tr>
                                return ($heading, $texts)
                            }
                        </table>
                        <a name="mei_end" id="mei_end" tabindex="9998"/>
                    </div>
                    return $result_list
                else
                    <div>
                        <!-- -->
                    </div>
            return $output
        }
                </td>
                <td style="width: 35%; border: 0px;">
                    <div style="overflow-y: scroll; overflow-x: hidden; height: 85vh" id="tei">
                       {
                            let $tei_out := if ($tei) then
                                local:transform_tei(doc(concat($tei_base, $tei)),$tei) 
                            else 
                                ""
                            return $tei_out
                       }
                    </div>
                </td>
            </tr>
        </table>

    </body>
</html>