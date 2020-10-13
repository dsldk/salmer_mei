xquery version "3.0" encoding "UTF-8";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace m = "http://www.music-encoding.org/ns/mei";
declare namespace t = "http://www.tei-c.org/ns/1.0"; 
declare namespace h = "http://www.w3.org/1999/xhtml";

declare option exist:serialize "method=xml media-type=text/xml"; 

declare variable $database := '/db/salmer/data';
declare variable $m_source := request:get-parameter("m_source", "salmer");
declare variable $tei := request:get-parameter("tei", "");
declare variable $tei_base := "https://raw.githubusercontent.com/dsldk/salmer_data/develop/xml/";
declare variable $mei_base := "https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/mei/";  
declare variable $tei_doc := if ($tei != "") then doc(concat($tei_base, request:get-parameter("tei", ""))) else (); 

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

declare variable $mei_dir := $books/dsl:book[dsl:tei=$tei]/dsl:mei;


declare function local:get_local_mei($filename) {
    for $doc in collection(concat($database,'/',$mei_dir))
    where substring(util:document-name($doc),1,string-length($filename)) = $filename
    order by util:document-name($doc)
    return $doc
};

declare function local:get_mei($filename) {
    let $mei_doc := doc(concat($mei_base,$mei_dir,'/',$filename))
    return $mei_doc 
};

declare function local:syl_with_hyphen($syl) {
    let $conn := 
        if($syl/@wordpos="m" or $syl/@wordpos="t") then "-" else " "
    return concat($conn,normalize-space($syl))
};

declare function local:text_hyphenated($doc as node()?, $mdiv as xs:string) {
    let $text := 
        for $measure in $doc/m:mei/m:music/m:body/m:mdiv[@xml:id=$mdiv or $mdiv=""]//m:staff
            let $measure_text :=
                for $line_no in (1 to count($measure//(m:note | m:syllable)[1]/m:verse))
                    let $line :=
                        for $syl in $measure//m:verse[@n=$line_no]/m:syl
                        return local:syl_with_hyphen($syl)
                return <div xmlns="http://www.w3.org/1999/xhtml">{normalize-space(string-join($line,""))}</div>
            return $measure_text            
    return $text
};

declare function local:de-hyphen($text){
  for $e in $text//text()
  return  <div xmlns="http://www.w3.org/1999/xhtml">{translate($e,"-","")}</div>
};

declare function local:tei_to_div($lg) {
    let $lines :=
        for $l in $lg
        return <div xmlns="http://www.w3.org/1999/xhtml">{$l//normalize-space(.)}</div>
    return $lines
};

declare function local:compare_texts($mei, $tei) {
    let $higlighted :=
        for $line at $lpos in $mei/*
            let $marked_up := 
                for $word at $wpos in tokenize($line,' ')
                    let $tword := $tei/*[$lpos]/tokenize(./string(),' ')[$wpos]
                    let $marked_up_word := if (compare($word, $tword) = 0) 
                        then concat($word,' ')
                        else (<span xmlns="http://www.w3.org/1999/xhtml" class="highlight">{$word}</span>,' ')
                 return $marked_up_word  
            return <div xmlns="http://www.w3.org/1999/xhtml">{$marked_up}</div>
    return $higlighted
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
    	<link rel="stylesheet" type="text/css" href="meloditekstkorrektur.css" />
        
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"><!-- --></script>
        <script type="text/javascript" src="meloditekstkorrektur.js"><!-- --></script>
        
	</head>
	<body style="margin: 20px; background-image: none;" onload="document.getElementById('tei').value='{$tei}';">
	
                <div style="background-color: #eee; position: fixed; padding: 10px 20px; margin:-20px; width: 100%">
                	<form method="get" action="">
                        <div>Vælg tekst: 
                            <select name="tei" id="tei" style="margin-bottom: 10px;">
                                <option value=""/>
                                {
                                    for $book in $books/dsl:book 
                                    return <option value="{$book/dsl:tei}">{$book/dsl:title}</option>
                                }
                            </select>
                            &#160;&#160;
                            Hent MEI-tekst fra: &#160;
                            {
                                let $radio := if ($m_source="github") then
                                    <span>
                                        <input type="radio" name="m_source" id="m_source1" value="github" checked="checked"/> <label for="m_source1">Github (langsom)</label>
                                        &#160;
                                        <input type="radio" name="m_source" id="m_source2" value="salmer"/> <label for="m_source2">Salmeserveren (måske uaktuel)</label>
                                    </span>
                                else
                                    <span>
                                        <input type="radio" name="m_source" value="github"/> <label for="m_source1">Github (langsom)</label>
                                        &#160;
                                        <input type="radio" name="m_source" value="salmer" checked="checked"/> <label for="m_source2">Salmeserveren (måske uaktuel)</label>
                                    </span>
                                return $radio
                            }
                            &#160;
                            <input type="submit" value="Hent"/>
                            &#160;&#160;&#160;&#160;&#160;&#160;
                            <input type="checkbox" checked="checked" name="hl" id="hl" onchange="toggle_highlight()"/> <label for="hl">Fremhæv forskelle</label>
                        </div>
                    </form>
                </div>

	
	
        <table style="border: 0px; top: 70px; width: 100%; position: absolute; z-index: -1;">
        {   let $output1 := 
                if ($tei != "") then 
                    <tr>
                        <th>MEI-tekst med delestreger</th>
                        <th>MEI-tekst uden delestreger</th>
                        <th>TEI-tekst</th>
                    </tr>
                else ""
            return $output1
        }
        {    let $output2 :=
                if ($tei != "") then         
                    for $notatedMusic in $tei_doc//t:notatedMusic
                        let $mei_filename := tokenize($notatedMusic/t:ptr/@target,'#')[1]
                        let $mdiv := substring-after($notatedMusic/t:ptr/@target,'#')
                        let $mei_file := if ($m_source = "salmer") then
                                local:get_local_mei($mei_filename) 
                            else 
                                local:get_mei($mei_filename) 
                        let $hyphenated_text := local:text_hyphenated($mei_file, $mdiv)
                        let $mei_text := <div xmlns="http://www.w3.org/1999/xhtml">{local:de-hyphen($hyphenated_text)}</div>
                        let $no_of_lines := count($mei_text/h:div)
                        let $tei_text := <div xmlns="http://www.w3.org/1999/xhtml">{local:tei_to_div($notatedMusic/following::t:lg[1]/(t:l | following::t:l)[position() <= $no_of_lines])}</div>
                        let $anchor := substring-before(tokenize($mei_filename,"_")[last()],'.xml')  
                        let $heading := 
                            <tr>
                                <td colspan="3"><b>{$mei_file/m:mei/m:meiHead/m:workList/m:work/m:title[1]} </b>({$notatedMusic/t:ptr/@target/string()})</td>
                            </tr>
                    return (
                        $heading,
                        <tr>
                            <td>{$hyphenated_text}</td>
                            <td>{local:compare_texts($mei_text, $tei_text)}</td>
                            <td>{$tei_text}</td>
                        </tr>
                        )
                else ""                        
            return $output2
        }
        </table>

    </body>
</html>