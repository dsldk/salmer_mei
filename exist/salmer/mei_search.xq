xquery version "3.0" encoding "UTF-8";

declare namespace local = "http://dsl.dk/this/app";
declare namespace dsl = "http://dsl.dk";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace m = "http://www.music-encoding.org/ns/mei";

declare variable $pname         := request:get-parameter("q", "");    (: Query by pitch name     :)
declare variable $contour       := request:get-parameter("c", "");    (: Query by melody contour :)
declare variable $absp          := request:get-parameter("a", "");    (: Query by pitch number   :)
declare variable $transpose     := request:get-parameter("t", ""); 
declare variable $page          := request:get-parameter("page", "1") cast as xs:integer;
declare variable $search_in     := request:get-parameter("x", "");    (: List of publications to search in   :)
declare variable $data          := doc('index/search_index.xml');  
declare variable $publications  := doc('index/publications.xml'); 
declare variable $collection    := '/db/salmer';

(: get parameters from session attributes :)
declare variable $perpage   := xs:integer(request:get-parameter("perpage", session:get-attribute("perpage")));

declare variable $session   := session:create();

(: save parameters as session attributes; set to default values if not defined :)
declare variable $session-perpage   := xs:integer(session:set-attribute("perpage", if ($perpage>0) then $perpage else "5"));

declare variable $from     := (xs:integer($page) - 1) * xs:integer(session:get-attribute("perpage")) + 1;
declare variable $to       :=  $from + xs:integer(session:get-attribute("perpage")) - 1;


(: if only the number of matches is needed :)
declare function local:string_matches_count($data as xs:string, $query as xs:string, $count as xs:integer) as xs:integer {
    let $new_count := if(contains($data,$query)) then 
        $count + 1 + local:string_matches_count(substring-after($data, $query), $query, $count)
    else 
        0
    return $new_count
};

(: returns the matching positions :)
declare function local:index-of-string($arg as xs:string?, $substring as xs:string) as xs:integer* {
  if (contains($arg, $substring))
  then (string-length(substring-before($arg, $substring))+1,
        for $other in local:index-of-string(substring-after($arg, $substring), $substring)
(:      Trying to include overlapping matches (starting at matching position + 1) - causes a server error :-(   
        for $other in local:index-of-string(substring($arg, string-length(substring-before($arg, $substring)) + 1), $substring):)
        return $other + string-length(substring-before($arg, $substring)) + string-length($substring))
  else ()
 } ;

declare function local:string_matches($data as xs:string, $query as xs:string) as xs:integer* {
    let $matches as xs:integer* := local:index-of-string($data, $query)
    return $matches
};

declare function local:str_pos_to_id($file as xs:string, $matches as xs:integer*) as xs:string* {
    (: find the IDs corresponding to the string match positions :)
    let $melody := $data/*/dsl:melody[dsl:file=$file]
    let $id_seq := tokenize($melody/dsl:id,",")
    let $ints := local:pitches_to_intervals($absp)
    let $ids :=
        for $match in $matches
        let $id :=
            if ($pname != "" or $contour != "") then
                $id_seq[number($match)]
            else
            if ($ints != "") then
                let $item_no := count(tokenize(substring($melody/dsl:intervals/string(),1,number($match)),",")) 
                return $id_seq[number($item_no)]
            else
            ()
        return $id
    return $ids    
};

declare function local:merge_strings($pnames as xs:string, $intervals as xs:string) as xs:string {
    (: combines a list of pitch names with the corresponding list of intervals for non-transposing searches :)
    let $i_seq as xs:string* := tokenize($intervals,",") 
    let $new_seq := 
        for $i at $pos in (1 to string-length($pnames))
        return concat(substring($pnames,$pos,1),$i_seq[$pos])
    return string-join($new_seq, ",")    
};

declare function local:get_pitch_names($pnums as xs:string) as xs:string {
    (: convert list of pitch numbers to string of pitch names :)  
    let $pnames as xs:string := "CVDWEFXGYAZB"
    let $p_seq as xs:string* := tokenize($pnums,"-") 
    let $name_seq as xs:string* := 
        for $i in $p_seq
        return string(substring($pnames,number($i) mod 12 + 1,1))
    return string-join($name_seq, "")    
};

declare function local:pitches_to_intervals($pitchstr as xs:string) as xs:string {
    let $pitches as xs:string* := tokenize($pitchstr, "-")
    let $intervals as xs:string* :=
        for $i at $pos in (1 to count($pitches) - 1)
            let $int  := number($pitches[$pos + 1])-number($pitches[$pos])
            let $sign := if ($int > 0) then "+" else ""
        return concat($sign,string($int))
    return string-join($intervals, ",")    
};

declare function local:get_results() {
    let $search_in_seq := 
        for $n in tokenize($search_in,",")
        return $publications/dsl:publications/dsl:pub[dsl:n = $n]/dsl:id/text()
    let $ints := local:pitches_to_intervals($absp) (: Query by interval sequence :)
    for $melody in $data/*/*
        let $doc-name:=$melody/dsl:file/string()
        let $matches := 
            if ($contour != "") then 
                let $contour_list := $melody/dsl:contour/string()
                return local:string_matches($contour_list, $contour)
            else
            if ($pname != "") then 
                let $pitch_list := $melody/dsl:pitch/string()
                return local:string_matches($pitch_list, $pname)
            else
            if ($ints != "" and $transpose = "1") then
                (: all transpositions - only look at intervals :)
                let $interval_list := $melody/dsl:intervals/string()
                return local:string_matches($interval_list, $ints)
            else
            if ($ints != "" and $transpose != "1") then
                (: no transpositions (excepts octaves) - look at both intervals and pitch names :)
                (: step 1: only search intervals first (to avoid unnecessary searches for both pitch and interval) :)
                let $interval_list := $melody/dsl:intervals/string()
                let $interval_matches := local:string_matches($interval_list, $ints)
                (: step 2: check if pitches match too (just checking the first pitch name) :)
                let $true_matches := 
                    for $match in $interval_matches
                        let $item_no := count(tokenize(substring($interval_list,1,$match + 1),",")) 
                        let $pitch_list := $melody/dsl:pitch/string()
                        let $pitch := local:get_pitch_names(tokenize($absp,"-")[1])
                    where substring($pitch_list,$item_no,1) = $pitch
                    return $match 
                return $true_matches 
            else
                ()
        where (count($matches) > 0 and ($melody/dsl:publ/text() = $search_in_seq or count($search_in_seq) = 0))
        order by count($matches) descending, $melody/dsl:file/text() ascending
        return 
            <result xmlns="http://dsl.dk">
                <doc>{$doc-name}</doc>
                <title>{$melody/dsl:title/string()}</title>
                <publ>{$melody/dsl:publ/string()}</publ>
                <matches>{$matches}</matches>
            </result>
};

(: Functions for visualizing the results :)
 
declare function local:verovio_match($file as xs:string, $highlight as xs:string*)  {
    let $output1 :=
        <div xmlns="http://www.w3.org/1999/xhtml" id="{substring-before($file,".")}" class="mei"><!-- SVG will be inserted here --></div>
    let $mei := doc(concat($collection,"/data/",$file)) 
    let $xsl := if (count($highlight) > 0) then "/xsl/highlight.xsl" else "/xsl/show.xsl"  
    (: possibly some transforms here :)
    let $output2 :=    
       <div style="display:none" xmlns="http://www.w3.org/1999/xhtml" id="{substring-before($file,".")}_data" type="text/data">
       {
            let $params := 
            <parameters>
                <param name="mdiv" value=""/>
                <param name="highlight" value="{$highlight}"/>
            </parameters>
            return transform:transform($mei,doc(concat($collection,$xsl)),$params)  
       }
       </div>
    return ($output1, $output2)
};

declare function local:highlight_ids($file as xs:string, $match_ids as xs:string*) as xs:string* {
    let $all_ids := tokenize($data/*/dsl:melody[dsl:file=$file]/dsl:id/string(),",")
    let $query_length :=
        if ($contour != "") then
            string-length($contour) + 1
        else
        if ($pname != "") then
            string-length($pname)
        else
            count(tokenize($absp,"-"))
    let $highlight_ids :=
        for $match in $match_ids
            let $match_pos := index-of($all_ids,$match) 
            let $match_seq :=
               for $id in $all_ids[position() = ($match_pos to $match_pos + $query_length - 1)]
               return $id
        return $match_seq
    return $highlight_ids
};

(: Paging :)

declare function local:paging( $list ) as node()* {
	let $total := count($list)
	(: remove old page parameter from query string :)
    let $query_string := 
        if(request:get-query-string() != "") then
            fn:replace(util:unescape-uri(request:get-query-string(),"UTF-8"),"&amp;page=[\d]*","")
        else ""
    let $nav :=
    
        if ($list and $total > $perpage) then
            (
        	let $nextpage := ($page + 1) (:cast as xs:string:)
        	let $next     :=
        	  if($from + $perpage <= $total) then
        	    <a xmlns="http://www.w3.org/1999/xhtml" rel="next" title="Næste side" class="paging" 
        	    href="{concat('mei_search.xq?', $query_string, '&amp;page=',$nextpage)}">&gt;</a>
        	  else
        	    <span xmlns="http://www.w3.org/1999/xhtml" class="paging selected">&gt;</span> 
        
        	let $prevpage := ($page - 1) (:cast as xs:string:)
        	let $previous :=
        	  if($from - $perpage > 0) then
        	    <a xmlns="http://www.w3.org/1999/xhtml" rel="prev" title="Foregående side" class="paging" 
        	    href="{concat('mei_search.xq?', $query_string, '&amp;page=',$prevpage)}">&lt;</a>
        	  else
        	    <span xmlns="http://www.w3.org/1999/xhtml" class="paging selected">&lt;</span> 
        
        	let $page_nav := for $p in 1 to ceiling( $total div $perpage ) cast as xs:integer
        		  return 
        		  (if( not($page = $p) ) then
        		    <a xmlns="http://www.w3.org/1999/xhtml" title="Gå til side {xs:string($p)}" class="paging"
        		    href="{concat('mei_search.xq?', $query_string, '&amp;page=',xs:string($p))}" >{$p}</a>
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
            <label class="input-label" for="allPubl"><span class="checkbox_title">ALLE SALMEBØGER </span> ({count($search_in_seq)}/{count($publications/dsl:publications/dsl:pub/dsl:id)})</label>
            <hr/>
        </div>
    let $publ_list :=
        for $publ in $publications/dsl:publications/dsl:pub
            let $checkbox := if($publ/dsl:n/text() = $search_in_seq or count($search_in_seq) = 0) then 
	            <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="x" id="{$publ/dsl:id/text()}" value="{$publ/dsl:n}" onchange="publClicked();" checked="checked"/> 
                else 
                <input xmlns="http://www.w3.org/1999/xhtml" type="checkbox" name="x" id="{$publ/dsl:id/text()}" value="{$publ/dsl:n}" onchange="publClicked();"/> 
            return 
                <div xmlns="http://www.w3.org/1999/xhtml" class="publication">
                    {$checkbox}
                    <label class="input-label" for="{$publ/dsl:id/text()}"><span class="checkbox_title">{$publ/dsl:title/text()}</span> ({$publ/dsl:editor/text()},&#160;{$publ/dsl:year/text()})</label>
                </div>
    return ($all, $publ_list)
};



(: Timing :)

declare function local:execution_time( $start-time, $end-time )  {
    let $duration := $end-time - $start-time
    let $seconds := $duration div xs:dayTimeDuration("PT1S")
    return
        (: Query completed in ... :)
        <span class="debug">Søgningen tog {$seconds} s.</span>
};

<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>DSL-melodisøgning</title>
        <meta charset="UTF-8"/> 
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"><!-- jquery --></script>
        <!--<script type="text/javascript" src="http://www.verovio.org/javascript/latest/verovio-toolkit.js"> verovio </script>-->
        <script type="text/javascript" src="http://www.verovio.org/javascript/develop/verovio-toolkit.js"><!-- verovio --></script>
        <script type="text/javascript">
		    /* Create the Verovio toolkit instance */
		    var vrvToolkit = new verovio.toolkit();
	    </script>
	    
	    <!-- MIDI -->        
        <script src="js/wildwebmidi.js"><!-- MIDI library --></script>
        <script src="js/midiplayer.js"><!-- MIDI player --></script>
        <script src="js/midiLib.js"><!-- custom MIDI library --></script>
	    

        <script src="js/mei_search.js"><!-- search tools --></script>
        <link rel="stylesheet" type="text/css" href="https://static.ordnet.dk/app/go_smn_app.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/fix_go_collisions.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/elements.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/layout.css" />
    	<link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/styles.css" />
        <link rel="stylesheet" type="text/css" href="http://tekstnet.dk/static/print.css" media="print" />
        <link rel="stylesheet" type="text/css" href="style/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
	</head>
	<body>
	   <div class="searchWrapper box-gradient-blue search">
    	   <div class="search_options search-bg">
                <div class="search_block search_block_narrow">
                    <form action="" method="get" class="form" id="publ_form">
                        <div class="input-label">Søg i:</div>
                        <div class="checkbox-options checkbox-list">
                            {local:check_publications()}
                        </div>
                    </form>
                </div>
        	   <div class="search_block">
        	       <form action="" method="get" class="form" id="pitch_form">
        	           <div class="input-label">Søg efter:</div>
            	       <p><label class="input-label" for="pnames">Tonenavne</label>
        	           <input name="x" id="x1" type="hidden" value="{$search_in}"/>
            	       <input type="text" name="q" id="pnames" value="{$pname}" class="search-text input"/> 
            	       <img src="https://tekstnet.dk/static/info.png" 
            	        title="Søg efter en bestemt tonefølge, f.eks. 'CDEF'. 
        Altererede toner skrives således: 
        cis: V, es: W, fis: X, as: Y, b: Z" onclick="this.form['x'].value = updateAction()"/>
            	       <input type="submit" value="Søg" class="search-button box-gradient-green"/></p>
        	       </form>
        	       <form action="" method="get" class="form" id="contour_form">
            	       <p><label class="input-label" for="contour">Kontur</label>
                       <input name="x" id="x2" type="hidden" value="{$search_in}"/>
            	       <input type="text" name="c" id="contour" value="{$contour}" class="search-text input"/> 
            	       <img src="https://tekstnet.dk/static/info.png" title="Søg efter melodier med en bestemt kontur, f.eks. '-//\'. 
        - : Tonegentagelse
        / : Opadgående interval
        \ : Nedadgående interval"/>
            	       <input type="submit" value="Søg" class="search-button box-gradient-green" onclick="this.form['x'].value = updateAction()"/></p>
        	       </form>
        	       
        	       <div id="piano_wrapper">
            	       <div id="piano_cell">
                        <div id="pQueryOut"></div>
                        <div id="piano">
                            <div class="keys">
                                <div class="key" data-key="60"></div>
                                <div class="key black black1" data-key="61"></div>
                                <div class="key" data-key="62"></div>
                                <div class="key black black3" data-key="63"></div>
                                <div class="key" data-key="64"></div>
                                <div class="key" data-key="65"></div>
                                <div class="key black black1" data-key="66"></div>
                                <div class="key" data-key="67"></div>
                                <div class="key black black2" data-key="68"></div>
                                <div class="key" data-key="69"></div>
                                <div class="key black black3" data-key="70"></div>
                                <div class="key" data-key="71"></div>
                                <div class="key" data-key="72"></div>
                                <div class="key black black1" data-key="73"></div>
                                <div class="key" data-key="74"></div>
                                <div class="key black black3" data-key="75"></div>
                                <div class="key" data-key="76"></div>
                                <div class="key" data-key="77"></div>
                                <div class="key black black1" data-key="78"></div>
                                <div class="key" data-key="79"></div>
                                <div class="key black black2" data-key="80"></div>
                                <div class="key" data-key="81"></div>
                                <div class="key black black3" data-key="82"></div>
                                <div class="key" data-key="83"></div>
                                <div class="key" data-key="84"></div>
                                <!--<div class="key black black1" data-key="85"></div>-->
                            </div>
                        </div>
                    </div>
                    <div id="piano_search_cell">
                        <div id="pSearchDiv">
                            <form action="" id="pSearch" class="form">
                                <div>
                                    <div class="checkbox-options">
                            	        {let $tr := if($transpose="1") then 
                            	           <input type="checkbox" name="t" id="transpositions" value="1" checked="checked"/> 
                            	         else 
                            	           <input type="checkbox" name="t" id="transpositions" value="1"/> 
                            	         return $tr
                            	        }
                            	        <label class="input-label" for="transpositions">&#160;&#160;Alle transpositioner</label>
                    	                <img src="https://tekstnet.dk/static/info.png" title="Kryds af, hvis intervalfølgen må begynde på en hvilken som helst tone"/>
                        	        </div>
                    	            <input name="a" id="absp" type="hidden" value="{$absp}"/>
                    	            <input name="x" id="x3" type="hidden" value="{$search_in}"/>
                                    <input type="submit" value="Søg" class="search-button box-gradient-green" onclick="this.form['x'].value = updateAction()"/><font size="5px"><br/></font>
                                    <input type="button" value="Nulstil" onclick="reset_a();" class="search-button box-gradient-green"/>
                                </div>
                                <div id="test"></div>
                            </form>
                        </div>
                    </div>
                </div>
	        </div>
	   </div>
       </div>
       
        <div style="height: 30px;">
            <!-- MIDI Player -->
            <div id="player" style="z-index: 20; position: absolute;"/>
        </div>
 	   
	   {
	   let $start-time := util:system-time()
       let $results := 
            if($pname != "" or $absp != "" or $contour != "") then
                local:get_results()
            else
                false()
	   let $output :=
	       <div class="result_list">
    	   {
	       let $count := 
	            if($results or $pname or $absp or $contour) then
	               concat("Resultater: ",count($results))
	            else ""
	       let $list :=
        	   if($results) then
        	       <div>
        	           {
    	                for $res at $pos in $results
    	                let $file := doc(concat("data/",$res/dsl:doc/string()))
    	                let $matches := tokenize($res/dsl:matches/string()," ")
    	                let $match_ids := local:str_pos_to_id($res/dsl:doc/string(), $matches)
    	                let $highlight_ids := local:highlight_ids($res/dsl:doc, $match_ids)
    	                let $title := if($res/dsl:title/string() != "") 
    	                    then $res/dsl:title/string()
    	                    else if (doc(concat("data/",$res/dsl:doc/string()))//m:titleStmt/m:title[text()])
    	                    then doc(concat("data/",$res/dsl:doc/string()))//m:titleStmt/m:title[text()][1]/string()    
                            else $res/dsl:doc/string()
                        where $pos >= $from  and $pos <= $to
    	                return
    	                    <div xmlns="http://www.w3.org/1999/xhtml" class="item search-result">
                                <p>
                                    <a href="javascript:void(0);" class="sprite arrow-white-circle">
                                        <span><!--{$from + $pos - 1}. -->{$title} ({$publications/dsl:publications/dsl:pub[dsl:id=$res/dsl:publ]/dsl:title/string()}, 
                                        {$publications/dsl:publications/dsl:pub[dsl:id=$res/dsl:publ]/dsl:year/string()})</span>
                                    </a>
                                    <br/>
                                    {count($match_ids)} 
                                    {
                                        let $hit_label := 
                                        if(count($match_ids) = 1) then " forekomst" else " forekomster"
                                        return $hit_label
                                    }
                                    {
                                        let $excerpts :=
                                        if(count($file//m:mdiv[.//m:note/@xml:id = $highlight_ids]) != count($file//m:mdiv) ) 
                                        then " (uddrag vises)" else ""
                                        return $excerpts
                                    }
                                    
                                    <div class="midi_player">
                                        <div class="midi_button play" id="play_{substring-before($res/dsl:doc/string(),'.')}">
                                            <a href="javascript:void(0);" title="Afspil" 
                                            onclick="play_midi('{substring-before($res/dsl:doc/string(),'.')}', verovio_options); $(this).blur();"></a>
                                        </div>
                                        <div class="midi_button stop" id="stop_{substring-before($res/dsl:doc/string(),'.')}">
                                            <a href="javascript:void(0);" title="Stop afspilning" 
                                            onclick="stop(); $(this).blur();"></a>
                                        </div>
                                    </div>
                                    
                                    <div class="debug">
                                    <!--[{$match_ids}]-->
                                    <!--[{count($file//m:mdiv[.//m:note/@xml:id = $highlight_ids]) } / {count($file//m:mdiv) } dele]-->
                                    </div>
                                </p>
                                { local:verovio_match($res/dsl:doc, $highlight_ids) }
                            </div>
        	            }
        	            <div>{local:paging($results)}</div>
                        <div>{local:execution_time($start-time, util:system-time())}</div>

                   </div>
                   
                    else ""
    	       return ($count, local:paging($results), $list)
    	    }
            </div>
        return $output
	   }
	</body>
</html>	
