xquery version "3.0" encoding "UTF-8";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk"; 
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace m = "http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $query_title   := request:get-parameter("qt", "");   (: Query by title                :)
declare variable $pname         := request:get-parameter("q", "");    (: Query by pitch name           :)
declare variable $contour       := request:get-parameter("c", "");    (: Query by melody contour       :)
declare variable $absp          := request:get-parameter("a", "");    (: Query by pitch number         :)
declare variable $transpose     := request:get-parameter("t", "");    (: All transpositions?           :)
declare variable $edge          := request:get-parameter("e", "");    (: Edge search (beginning only)? :)
declare variable $repeat        := request:get-parameter("r", "");    (: Allow repeated notes?         :)
declare variable $fuzzy         := request:get-parameter("f", "0") cast as xs:integer;   (: Fuzzyness  :)
declare variable $page          := request:get-parameter("page", "1") cast as xs:integer;
declare variable $search_in     := request:get-parameter("x", "");    (: List of publications to search in   :)
declare variable $publications  := doc('library/publications.xml'); 
declare variable $l             := doc('library/language/da.xml');    (: Localisation of labels etc. :)   
declare variable $collection    := '/db/salmer';
declare variable $solr_base     := 'http://salmer.dsl.lan:8983/solr/salmer/'; (: Solr core :)
declare variable $this_script   := 'mei_search.xq';

(: key string for substituting numbers by characters. :)
(: pitches:   j = c4 (= MIDI pitch no. 60);           :)
(: intervals: Z = unison (repeated note)              :)
declare variable $chars         := "ÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØ";

(: get parameters from session attributes :)
(: declare variable $perpage   := xs:integer(request:get-parameter("perpage", session:get-attribute("perpage")));  :)
declare variable $perpage   := xs:integer(request:get-parameter("perpage", 5));

declare variable $session   := session:create();

(: save parameters as session attributes; set to default values if not defined :)
(: declare variable $session-perpage   := xs:integer(session:set-attribute("perpage", if ($perpage>0) then $perpage else "5"));  :)

(: declare variable $from     := (xs:integer($page) - 1) * xs:integer(session:get-attribute("perpage")); :)
declare variable $from     := (xs:integer($page) - 1) * $perpage;


(: \ and / not allowed as characters in Solr queries :)
declare function local:contour_to_chars($contour as xs:string) as xs:string {
    let $chars := translate($contour, "/\-","udr")
  return $chars
};

declare function local:chars_to_contour($chars as xs:string) as xs:string {
    let $contour := translate($chars, "udr", "/\-")
  return $contour
};

declare function local:get_match_positions($highlights as xs:string?) as node()* {
    let $matches as node()* :=
        for $this_trsp in tokenize($highlights," ")
        (: if all transpositions are searched, the higlighted string is a concatenation of all transpositions joined with spaces; separate them and return matches from each :)
            let $frags as xs:string* := tokenize(normalize-space($this_trsp),"\]")
            let $fragLengths as xs:integer* :=
                for $frag in $frags
                return string-length(translate($frag,"[",""))        
            let $matches_in_this_trsp as node()* :=
                (: length correction (+1) is needed when the query is based on interval instead of notes (i.e., contour search) :)  
                for $frag at $pos in $frags[position() != last()]
                return 
                    <match>
                        <pos>{sum($fragLengths[position() < $pos]) + string-length(substring-before($frag, "[")) + 1}</pos>
                        <length>{string-length(substring-after($frag,"[")) + xs:integer($contour != "")}</length>
                    </match>
         return $matches_in_this_trsp
    return $matches
};

declare function local:pitches_to_interval_chars($pitchstr as xs:string) as xs:string {
    let $pitches as xs:string* := tokenize($pitchstr, "-")
    let $intervals as xs:string* :=
        for $i in (1 to count($pitches) - 1)
            let $int  := number($pitches[$i + 1])-number($pitches[$i])
            let $char := substring($chars,number($int + 50),1)
        return $char
    return string-join($intervals, "")    
};

(:  Generate Solr query :)
declare function local:solr_query() {
    let $ints as xs:string := if($absp != "") then local:pitches_to_interval_chars($absp) else "" (: Query by interval sequence :)
    let $q_str := concat('%22',encode-for-uri(translate(normalize-space($query_title)," ","+")),'%22')
    let $fuzzyness := if($fuzzy > 0) then concat("~",xs:string($fuzzy)) else ""
    let $solrQuery1 := 
            if ($query_title != "") then
                (: search by title :)
                concat("freq=termfreq(title,'",$q_str,"')&amp;q=title:'",$q_str,"'")
            else
            if ($contour != "") then 
                (: search by contour :)
                concat("freq=termfreq(contour,'",local:contour_to_chars($contour),"')&amp;hl.fl=contour&amp;q=contour:",local:contour_to_chars($contour))
            else
            if ($pname != "") then 
                (: search by pitch names :)
                concat("freq=termfreq(pitch,'",$pname,"')&amp;hl.fl=pitch&amp;q=pitch:",$pname)
            else
            if ($absp != "") then
                (: search by notated pitches :)
                let $field_0 := if ($transpose != "1") then "abs_pitch" else "transposition"
                let $field_1 := if ($repeat != "1") then 
                    $field_0 else concat($field_0,'_norepeat')
                let $field := if ($edge != "1") then 
                    $field_1 else concat($field_1,'_edge')
                let $pitches as xs:integer* :=
                    for $p in tokenize($absp, "-")
                    return xs:integer($p)
                (: transpose pitch query down to the lowest possible octave :)
                let $transposeDown as xs:integer := xs:integer(12*(min($pitches) idiv 12))
                let $transposedDownPitches as xs:integer* := 
                    for $i in (1 to count($pitches))
                    return xs:integer($pitches[$i] - $transposeDown)
                (: searching through 4 octaves :)
                let $pitchStrings as xs:string* := 
                    for $i in (3 to 6)
                        let $transpose := xs:integer($i * 12)
                        let $pseq := 
                            for $p in $transposedDownPitches
                            return encode-for-uri(substring($chars,number($p + $transpose),1))
                    return concat(string-join($pseq,""),$fuzzyness) 
                let $freq as xs:string* := 
                    for $str in $pitchStrings
                    return concat("termfreq(",$field,",'",$str,"')") 
                return concat("freq=sum(",string-join($freq,","),")&amp;hl.fl=",$field,"&amp;q=",$field,":(",string-join($pitchStrings,"+"),")")
            else
            ()
    let $search_in_seq := 
        for $n in tokenize($search_in,",")
        return $publications/dsl:publications/dsl:pub[string(position()) = $n]/dsl:id/text()
    let $solrQuery2 := if (not($solrQuery1) or count($search_in_seq) = 0 or count($search_in_seq) = count($publications/dsl:publications/dsl:pub)) then
            ()
        else
            concat("+AND+publ:(",string-join($search_in_seq,'+'),")") 
    (:return concat($solr_base,'select?wt=xml&amp;hl=on&amp;hl.fragsize=10000&amp;',$solrQuery1,$solrQuery2,'&amp;rows=',session:get-attribute("perpage"),'&amp;start=',$from,"&amp;fl=*,score,freq:$freq&amp;sort=$freq+desc,score+desc&amp;hl.method=fastVector&amp;hl.tag.pre=[&amp;hl.tag.post=]"):)
    return concat($solr_base,'select?wt=xml&amp;hl=on&amp;hl.fragsize=10000&amp;',$solrQuery1,$solrQuery2,'&amp;rows=',$perpage,'&amp;start=',$from,"&amp;fl=*,score,freq:$freq&amp;sort=$freq+desc,score+desc&amp;hl.method=fastVector&amp;hl.tag.pre=[&amp;hl.tag.post=]")
};


(: Functions for visualizing the results :)
 
(:  :declare function local:verovio_match($file as xs:string, $highlight as xs:string*)  {:)
declare function local:verovio_match($doc as node(), $fileId as xs:string, $highlight as xs:string*) as node()* {
    let $highlight_list := if (count($highlight) > 0) then 
            <div class="highlight_list" style="display:none">{$highlight}</div>
        else
            ""
    let $output1 :=
        <div id="{$fileId}" class="mei"><p class="loading"><img src="style/img/loading.gif" width="128" height="128" alt="Henter noder..." title="Henter noder..."/></p></div>
    let $output2 :=
        <div id="{$fileId}_options" class="mei_options">
            <!--MEI options menu will be inserted here-->
            {$highlight_list}
        </div>
    return ($output1, $output2)
};

declare function local:highlight_ids($idString as xs:string, $matches as node()*) as xs:string* {
    let $all_ids := tokenize($idString,",")
    let $highlight_ids :=
        for $match in $matches
            let $match_seq :=
               for $id in $all_ids[position() = (xs:integer($match/pos) to xs:integer($match/pos + $match/length - 1))]
               return $id
        return $match_seq
    return $highlight_ids
};


(: Paging :)
 
declare function local:paging( $total as xs:integer ) as node()* {
	(: remove old page parameter from query string :)
    let $query_string := 
        if(request:get-query-string() != "") then
            fn:replace(util:unescape-uri(request:get-query-string(),"UTF-8"),"&amp;page=[\d]*","")
        else ""
    let $nav :=
        if ($total > $perpage) then
            (
        	let $nextpage := ($page + 1) (:cast as xs:string:)
        	let $next     :=
        	  if($from + $perpage <= $total) then
        	    <a xmlns="http://www.w3.org/1999/xhtml" rel="next" title="Næste side" class="paging" 
        	    href="{concat($this_script,'?', $query_string, '&amp;page=',$nextpage)}">&gt;</a>
        	  else
        	    <span xmlns="http://www.w3.org/1999/xhtml" class="paging selected">&gt;</span> 
        	let $prevpage := ($page - 1) (:cast as xs:string:)
        	let $previous :=
        	  if($from - $perpage > 0) then
        	    <a xmlns="http://www.w3.org/1999/xhtml" rel="prev" title="Foregående side" class="paging" 
        	    href="{concat($this_script,'?', $query_string, '&amp;page=',$prevpage)}">&lt;</a>
        	  else
        	    <span xmlns="http://www.w3.org/1999/xhtml" class="paging selected">&lt;</span> 
        	let $page_nav := for $p in 1 to ceiling( $total div $perpage ) cast as xs:integer
        		  return 
        		  (if( not($page = $p) ) then
        		    <a xmlns="http://www.w3.org/1999/xhtml" title="Gå til side {xs:string($p)}" class="paging"
        		    href="{concat($this_script,'?', $query_string, '&amp;page=',xs:string($p))}" >{$p}</a>
        		  else
        		    <span xmlns="http://www.w3.org/1999/xhtml" class="paging selected">{$p}</span>
        		  )
            return 
                <div xmlns="http://www.w3.org/1999/xhtml" class="paging_div">
                    {$previous} {$page_nav} {$next}
                </div>
            )
        else 
            ()
	return $nav
};

 
declare function local:check_publications() as node()* {
    let $search_in_seq := tokenize($search_in,",")
    (: check: the "all" check box value seems to be included in the query string sometimes :)
    let $all_checkbox := if(count($search_in_seq) >= count($publications/dsl:publications/dsl:pub/dsl:id) or count($search_in_seq) = 0) then 
        <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="all" id="allPubl" value="" onchange="allPublClicked();" checked="checked"/> 
        else
        <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="all" id="allPubl" value="" onchange="allPublClicked();"/> 
    let $all := 
        <div xmlns="http://www.w3.org/1999/xhtml">
            {$all_checkbox}
            <label class="input-label" for="allPubl"><span class="checkbox_title">ALLE SALMEBØGER </span> 
            <!--({count($search_in_seq)}/{count($publications/dsl:publications/dsl:pub/dsl:id)})--></label>
            <hr/>
        </div>
    let $publ_list :=
        for $publ at $pos in $publications/dsl:publications/dsl:pub[normalize-space(dsl:mei_coll)]
            let $checkbox := if(string($pos) = $search_in_seq or count($search_in_seq) = 0) then 
	            <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="x" id="{$publ/dsl:id/text()}" value="{$pos}" onchange="publClicked();" checked="checked"/> 
                else 
                <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="x" id="{$publ/dsl:id/text()}" value="{$pos}" onchange="publClicked();"/> 
            return 
                <div xmlns="http://www.w3.org/1999/xhtml" class="publicationCheckbox">
                    {$checkbox}
                    <label class="input-label" for="{$publ/dsl:id/text()}"><span class="checkbox_title">{$publ/dsl:title/text()}</span> 
                    ({$publ/dsl:year/text()})</label>
                </div>
    return ($all, $publ_list)
};

declare function local:get_titles_solr() as node()* {
    let $query := concat($solr_base,"select?fl=title&amp;q=title:*&amp;rows=10000&amp;wt=xml")
    let $solr_docs := doc($query)
    let $options := 
        for $doc in $solr_docs/*/*/*[name()='doc']
            let $title := $doc/*[@name='title'][@type='uniform' or not(../m:title[@type="uniform"])]/*[1]
            order by $title ascending
        return <option value="{$title}">{$title}</option>
    return 
        <select onchange="document.getElementById('query_title').value=this.value">
            <option value="" selected="selected">Vælg titel</option>
            {$options}
        </select>
};

declare function local:get_titles() as node()* {
    let $work_titles :=
        for $work in collection($collection)//m:workList/m:work[m:title]
            let $title := $work/m:title[@type="uniform" or not(../m:title[@type="uniform"])][1]
            order by lower-case($title) ascending
        return $title
    let $options := 
        for $title in distinct-values($work_titles/normalize-space(string()))
        return <option value="{$title}">{$title}</option>
    return 
        <select id="title_select" onchange="document.getElementById('query_title').value = this.value; document.getElementById('title_form').submit();">
            <option value="" selected="selected">Vælg titel</option>
            {$options}
        </select>
};

(: Timing :)
declare function local:execution_time( $start-time, $end-time )  {
    let $duration := $end-time - $start-time
    let $seconds := $duration div xs:dayTimeDuration("PT1S")
    return
        <span class="debug">Søgningen tog {$seconds} s.</span>
};

let $active_tab := 
    if($pname != "") then "openPitchTab"
    else if($contour != "") then "openContourTab"
    else if($absp != "") then "openPianoTab"
    else "openTitleTab"

let $result :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>DSL-melodisøgning</title>
        <meta charset="UTF-8"/> 
        
        <link rel="stylesheet" type="text/css" href="https://static.ordnet.dk/app/go_smn_app.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/fix_go_collisions.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/elements.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/layout.css" />
    	<link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/styles.css" />
        <link rel="stylesheet" type="text/css" href="https://tekstnet.dk/static/print.css" media="print" />
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
        
        <!--<link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />-->
        <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css" />
        
        <!-- User interaction settings -->
        <script type="text/javascript">
            var enableMenu = false;     // do not show options menu
            var enableLink = false;     // do not show links to melody database
            var enableMidi = true;      // enable MIDI player
            var enableOptions = false;  // do not show melody customization options
            var enableSearch = true;    // enable phrase marking for melodic search 
            var enableComments = false; // do not show editorial comments
        </script>   
        
        <!-- Note highlighting only works with jQuery 3+ -->
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     
        <script type="text/javascript" src="js/libs/verovio/verovio-toolkit.js">/* Verovio */</script>
        <!-- alternatively use CDNs, like: -->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/latest/verovio-toolkit.js">/* */</script>-->
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/develop/verovio-toolkit.js">/* */</script>-->
        <script type="text/javascript" src="js/MeiAjax.js"><!-- MEI tools --></script>
        <script type="text/javascript" src="js/MeiSearch.js"><!-- MEI search tools --></script>

	    <!-- MIDI -->        
        <script type="text/javascript" src="js/libs/wildwebmidi/074_recorder.js"><!-- MIDI library --></script>
        <script type="text/javascript" src="js/midiplayer.js"><!-- MIDI player --></script>
        <script type="text/javascript" src="js/midiLib.js"><!-- custom MIDI library --></script>

	</head>
	<body class="metadata" onload="document.getElementById('{$active_tab}').click();">
	   {doc(concat($collection,"/assets/page_head.html"))}
	   <div class="searchWrapper search">
    	   <div class="search_options search-bg">
                <div class="search_block search_block_narrow">
                    <form action="" method="get" class="form" id="publ_form">
                        <!--<div class="input-label">Søg i:</div>-->
                        <div class="checkbox-options checkbox-list">
                            {local:check_publications()}
                        </div>
                    </form>
                </div>
        	   <div class="search_block">
              	   <div class="tab form">
              	      <!--<span class="input-label">Søg efter:</span>-->
                      <button class="tablinks" onclick="openTab(event, 'title_form')" id="openTitleTab">Titel</button>
                      <button class="tablinks" onclick="openTab(event, 'pitch_form')" id="openPitchTab">Tonenavne</button>
                      <button class="tablinks" onclick="openTab(event, 'contour_form')" id="openContourTab">Kontur</button>
                      <button class="tablinks" onclick="openTab(event, 'piano_wrapper')" id="openPianoTab">Noder</button>
                   </div>
        	       <form action="" method="get" class="form tabcontent" id="title_form">
        	           <p>
        	               <input name="qt" id="query_title" type="text" value="{$query_title}" class="search-text input"/>
        	               <img src="https://tekstnet.dk/static/info.png" alt="hint" title="Skriv titel eller del af en titel"/>
        	               <input name="x" id="x0" type="hidden" value="{$search_in}"/>
            	           <input type="submit" value="Søg" class="search-button box-gradient-green" onclick="this.form['x'].value = updateAction();"/>
            	           <br/>
        	           </p>
        	           <p>
                	       {doc("assets/title_select.html")   (: or generate dynamically with: local:get_titles() :)}
                	   </p>
            	   </form>
        	       <form action="" method="get" class="form tabcontent" id="pitch_form">
            	       <p>
        	           <input name="x" id="x1" type="hidden" value="{$search_in}"/>
            	       <input type="text" name="q" id="pnames" value="{$pname}" class="search-text input"/> 
            	       <img src="https://tekstnet.dk/static/info.png"  alt="hint"
            	        title="Søg efter en bestemt tonefølge, f.eks. 'CDEF'.
H skrives B.            	        
Altererede toner skrives således: 
cis: V, es: W, fis: X, as: Y, b: Z"/>
            	       <input type="submit" value="Søg" class="search-button box-gradient-green"
            	       onclick="this.form['x'].value = updateAction();"/></p>
        	       </form>
        	       <form action="" method="get" class="form tabcontent" id="contour_form">
            	       <p>
                       <input name="x" id="x2" type="hidden" value="{$search_in}"/>
            	       <input type="text" name="c2" id="contour" value="{local:chars_to_contour($contour)}" class="search-text input"/> 
            	       <input type="hidden" name="c" id="contour_hidden" value="{$contour}"/> 
            	       <img src="https://tekstnet.dk/static/info.png" alt="hint" title="Søg efter melodier med en bestemt kontur, f.eks. '-//\'. 
- : Tonegentagelse
/ : Opadgående interval
\ : Nedadgående interval"/>
            	       <input type="submit" value="Søg" class="search-button box-gradient-green" 
            	       onclick="this.form['c'].value = this.form['c2'].value.replace(/\//g, 'u').replace(/\\/g,'d').replace(/-/g,'r');this.form['x'].value = updateAction()"/></p>
        	       </form>
        	       
        	       <div id="piano_wrapper" class="form tabcontent">
        	           <form action="" id="pSearch" class="form">
                         <div id="piano_cell">
                            <div id="pQueryOut"><!--  --></div>
                            <div id="piano">
                                <div class="keys">
                                    <div class="key" data-key="60"><!--  --></div>
                                    <div class="key black black1" data-key="61"><!--  --></div>
                                    <div class="key" data-key="62"><!--  --></div>
                                    <div class="key black black3" data-key="63"><!--  --></div>
                                    <div class="key" data-key="64"><!--  --></div>
                                    <div class="key" data-key="65"><!--  --></div>
                                    <div class="key black black1" data-key="66"><!--  --></div>
                                    <div class="key" data-key="67"><!--  --></div>
                                    <div class="key black black2" data-key="68"><!--  --></div>
                                    <div class="key" data-key="69"><!--  --></div>
                                    <div class="key black black3" data-key="70"><!--  --></div>
                                    <div class="key" data-key="71"><!--  --></div>
                                    <div class="key" data-key="72"><!--  --></div>
                                    <div class="key black black1" data-key="73"><!--  --></div>
                                    <div class="key" data-key="74"><!--  --></div>
                                    <div class="key black black3" data-key="75"><!--  --></div>
                                    <div class="key" data-key="76"><!--  --></div>
                                    <div class="key" data-key="77"><!--  --></div>
                                    <div class="key black black1" data-key="78"><!--  --></div>
                                    <div class="key" data-key="79"><!--  --></div>
                                    <div class="key black black2" data-key="80"><!--  --></div>
                                    <div class="key" data-key="81"><!--  --></div>
                                    <div class="key black black3" data-key="82"><!--  --></div>
                                    <div class="key" data-key="83"><!--  --></div>
                                    <div class="key" data-key="84"><!--  --></div>
                                    <!--<div class="key black black1" data-key="85"></div>-->
                                </div>
                            </div>
                            
                            
                            <input type="submit" value="Søg" class="search-button box-gradient-green" 
                                onclick="this.form['x'].value = updateAction()"  style="margin-bottom:5px;"/>&#160;
                            <input type="button" value="Nulstil" onclick="reset_a();" class="search-button box-gradient-green"/>
                            

                            
                            
                        </div>
                        <div id="piano_search_cell">
                            <div id="pSearchDiv">
                                    <div>
                        	            <input name="a" id="absp" type="hidden" value="{$absp}"/>
                        	            <input name="x" id="x3" type="hidden" value="{$search_in}"/>
                                        <div class="checkbox-options">
                                	        {let $tr := if($transpose="1") then 
                                	           <input type="checkbox" name="t" id="transpositions" value="1" checked="checked"/> 
                                	         else 
                                	           <input type="checkbox" name="t" id="transpositions" value="1"/> 
                                	         return $tr
                                	        }
                                	        <label class="input-label" for="transpositions">Alle transpositioner</label>
                        	                <img src="https://tekstnet.dk/static/info.png" title="Kryds af, hvis intervalfølgen må begynde på en hvilken som helst tone"/>
                            	        </div>
                                        <div class="checkbox-options">
                                	        {let $e := if($edge="1") then 
                                	           <input type="checkbox" name="e" id="edge" value="1" checked="checked"/> 
                                	         else 
                                	           <input type="checkbox" name="e" id="edge" value="1"/> 
                                	         return $e
                                	        }
                                	        <label class="input-label" for="edge">Begynder med</label>
                        	                <img src="https://tekstnet.dk/static/info.png" title="Søg kun efter begyndelsen af melodien"/>
                            	        </div>
                                        <div class="checkbox-options">
                                	        {let $rep := if($repeat="1") then 
                                	           <input type="checkbox" name="r" id="repetitions" value="1" checked="checked"/> 
                                	         else 
                                	           <input type="checkbox" name="r" id="repetitions" value="1"/> 
                                	         return $rep
                                	        }
                                	        <label class="input-label" for="repetitions">Ignorer tonegentagelser</label>
                        	                <img src="https://tekstnet.dk/static/info.png" title="Kryds af, hvis hvis tonegentagelser skal betragtes som én tone, f.eks. ved afvigende antal stavelser på samme melodi (giver flere resultater)"/>
                            	        </div><br/>
                            	        <div class="checkbox-options">
                            	            <label class="input-label" for="fuzzyness" style="margin-left: 20px;">Præcision:</label>
                            	            <img src="https://tekstnet.dk/static/info.png" title="Søgningen kan udvides ved at tillade en eller to afvigelser, 
dvs. afvigende tonehøjder eller 
manglende eller tilføjede toner"/><br/>
                            	            {let $exact := if($fuzzy!=-1 and $fuzzy!=1 and $fuzzy!=2) then 
                                	            <input type="radio" name="f" id="exact" value="0" checked="checked"/>
                                	         else 
                                	           <input type="radio" name="f" id="exact" value="0"/> 
                                	         return $exact
                                	        }
                            	            <label class="input-label" for="exact">Eksakt match</label><br/> 
                            	            {let $fuzzy1 := if($fuzzy=1) then 
                                	            <input type="radio" name="f" id="fuzzy1" value="1" checked="checked"/>
                                	         else 
                                	            <input type="radio" name="f" id="fuzzy1" value="1"/>
                                	         return $fuzzy1
                                	        }
                            	            <label class="input-label" for="fuzzy1">Tillad 1 afvigelse</label><br/> 
                            	            {let $fuzzy2 := if($fuzzy=2) then 
                                	            <input type="radio" name="f" id="fuzzy2" value="2" checked="checked"/>
                                	         else 
                                	            <input type="radio" name="f" id="fuzzy2" value="2"/>
                                	         return $fuzzy2
                                	        }
                            	            <label class="input-label" for="fuzzy2">Tillad 2 afvigelser</label>
                            	        </div>
                            	        
                                    </div>
                            </div>
                        </div>
                    </form>
                </div>
	        </div>
	     </div>
        </div>
        <!--<textarea rows="10" cols="80" id="debug_text"></textarea>-->
        <div style="height: 30px;">
            <!-- MIDI Player -->
            <div id="player" style="z-index: 20; position: absolute;"/>
        </div>
 	   
	   {
	   let $start-time := util:system-time()
       let $solrResult := 
            if($query_title != "" or $pname != "" or $absp != "" or $contour != "") then
                doc(local:solr_query())
            else
                false()
       let $numFound := if($solrResult) then
                number($solrResult/*/*[@numFound][1]/@numFound)
            else
                0
	   let $output :=
	       <div class="result_list">
    	   {
	       let $count := 
	            if($numFound > 0 or $query_title or $pname or $absp or $contour) then
	               concat("Resultater: ",$numFound)
	            else ""
	       let $list :=
        	   if($numFound > 0) then
        	       <div>
        	           {
    	                for $res at $pos in $solrResult/*/*/*[name()="doc"]
    	                let $coll := concat($collection, substring-after($res/*[@name="collection"],$collection))
    	                let $file := doc(concat($coll,"/",$res/*[@name="file"]/string()))
    	                let $title := if($res/*[@name="title"]/*/string() != "") 
    	                    then $res/*[@name="title"]/*[1]/string()
    	                    else if (doc(concat("data/",$res/*[@name="file"]/string()))//m:titleStmt/m:title[text()])
    	                    then doc(concat("data/",$res/*[@name="file"]/string()))//m:titleStmt/m:title[text()][1]/string()    
                            else $res/*[@name="file"]/string()
                        let $rec_type := if($file/m:mei/m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]) then
                            string-join($file/m:mei/m:meiHead/m:workList/m:work/m:classification/m:termList/m:term[@type="itemClass"]/string()," ")
                            else "music_document"
    	                return
    	                    <div xmlns="http://www.w3.org/1999/xhtml" class="item search-result">
                                <div>
                                    <a href="document.xq?doc={substring-after($res/*[@name="collection"],'data/')}/{$res/*[@name="file"]/string()}" 
                                        title="{$l//*[name()=$rec_type]/string()}" class="title {$rec_type}">
                                        <span><!--{$from + $pos - 1}. -->{$title} 
                                        
                                            
                                        {
                                            let $pub_title := if ($rec_type="music_document") then
                                                concat(
                                                    ' (',
                                                    $publications/dsl:publications/dsl:pub[dsl:id=$res/*[@name="publ"]]/dsl:title/string(),
                                                    ', ',
                                                    $publications/dsl:publications/dsl:pub[dsl:id=$res/*[@name="publ"]]/dsl:year/string(),
                                                    ')'                                                    
                                                    )
                                                else
                                                ""
                                             return $pub_title
                                        } 
                                        
                                        
                                        
                                        </span>
                                    </a>
                                    <br/>
                                    {
                                        let $preview := if ($file/m:mei/m:music/m:body/m:mdiv/m:score)
                                            then
                            	                let $matches := local:get_match_positions($solrResult/*/*[@name="highlighting"]/*[@name=$res/*[@name="id"]]/*[1]/*[1])
                            	                let $highlight_ids := local:highlight_ids($res/*[@name="ids"]/string(), $matches)
                                                let $score_preview :=
                                                    <div>
                                                        {
                                                            let $hit_label := if(count($matches) > 0) 
                                                                then   
                                                                    if(count($matches) = 1) then "1 forekomst" else concat(count($matches)," forekomster")
                                                                else 
                                                                    ""
                                                            return $hit_label
                                                        }
                                                        {
                                                            let $excerpts :=
                                                            if(count($file//m:mdiv[.//*/@xml:id = $highlight_ids] and count($matches) > 0) != count($file//m:mdiv) ) 
                                                            then " (uddrag vises)" else ""
                                                            return $excerpts
                                                        }
                                                        &#160;
                                                        <div class="midi_player">
                                                            <div class="midi_button play" id="play_{substring-before($res/*[@name="file"]/string(),'.')}" title="Afspil" 
                                                                onclick="play_midi('{substring-before($res/*[@name="file"]/string(),'.')}');">
                                                                <span class="symbol"><span class="label">Afspil</span></span> 
                                                            </div>
                                                            <div class="midi_button stop" id="stop_{substring-before($res/*[@name="file"]/string(),'.')}" title="Stop afspilning" onclick="stop()">
                                                                <span class="symbol"><span class="label">Stop</span></span> 
                                                            </div>
                                                        </div> 
                                                        <div class="debug">
                                                        <!--[Solr hits: {$res/*[@name="freq"]}]<br/>-->
                                                        <!--[Matches: {$matches}]<br/>-->
                                                        <!--[Highlight: {local:highlight_ids($res/*[@name="ids"]/string(), $matches)}]<br/>-->
                                                        <!--[Highlight IDs: {$highlight_ids}]<br/>-->
                                                        <!--[Solr highlight:  {$solrResult/*/*[@name="highlighting"]/*[@name=$res/*[@name="id"]]/*[1]/*[1]}]-->
                                                        <!--[{count($file//m:mdiv[.//m:note/@xml:id = $highlight_ids]) } / {count($file//m:mdiv) } dele]-->
                                                        <!--{substring-after($res/*[@name="collection"],$collection)} -->
                                                        <!--{concat($coll,"/",$res/*[@name="file"]/string())}-->
                                                        <!--[Title: {$res/*[@name="title"]/*[1]/string()}]-->
                                                        </div>
                                                        {
                                                            local:verovio_match($file, $res/*[@name="id"], $highlight_ids)
                                                        }
                                                    </div>
                                                return $score_preview    
                                            else 
                                                <div>{$l//*[name()=$rec_type]/string()}</div>
                                            
                                        return $preview
                                    }
                                </div>
                            </div>
        	            }
        	            <div>{local:paging($numFound)}</div>
                        <div>{local:execution_time($start-time, util:system-time())}</div>

                   </div>
                   
                    else "" 
    	       return ($count, local:paging($numFound), $list)

    	    }
                       <!--<div class="debug">
                            {local:solr_query()}
                       </div>-->
            </div>
        return $output
	    }
	</body>
</html>	

return $result