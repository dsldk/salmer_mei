xquery version "3.1";

(: Returns a transformed version of the MEI document referred to in the request.    
   Accepts both GET and POST requests.
   GET supports the following parameters:
   doc:  MEI file name (omit any directory name; subdirectories will be searched and first matching file returned)
   mdiv: The desired <mdiv> element to be included (all, if none is specified)
   xsl:  The XSL style sheet to be applied. Default is show.xsl
   id:   The target element for the response (needed to trace back the element that made the request)
   GET example:                                                                     
    transform_mei.xq?doc=Th_1569_LN1426_001r.xml&mdiv=mdiv-01&xsl=comments.xsl&id=Th_1569_LN1426_001rMDIVmdiv-01

   A POST request allows the following sequential transformations: show, transpose, clef, noteValues, beams.
   The POST request should post a JSON object or XML with contents similar to the following:         
    <post-parameters>
        <doc>Th_1569_LN1426_044v.xml</doc>
        <id>Th_1569_LN1426_044vMDIVmdiv-02</id>
        <show>
            <xslt>show.xsl</xslt>
            <parameters>
                <mdiv>mdiv-01</mdiv>
            </parameters>
        </show>
        <transpose>
            <xslt>transpose.xsl</xslt>
            <parameters>
                <direction>down</direction>
                <interval>7</interval>
            </parameters>
        </transpose>
        <clef>
            <xslt>clef.xsl</xslt>
            <parameters>
                <clef>g</clef>
            </parameters>
        </clef>
        <noteValues>
            <xslt>duration.xsl</xslt>
            <parameters>
                <factor>4</factor>
            </parameters>
        </noteValues>
        <beams>
            <xslt>beam.xsl</xslt>
        </beams>
    </post-parameters>
:)

declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace local = "http://dsl.dk/this/app";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";

declare variable $database   := "/db/salmer";
declare variable $datadir    := "data";
declare variable $xsldir     := "xsl";
declare variable $defaultXSL := "show.xsl";
declare variable $post       := local:get_post_data();

(: Decoding POST request :)

declare function local:get-elements() as node()* {
    let $all_names :=  
        for $name in request:get-parameter-names()
            let $main_name := if(contains($name,'[')) then substring-before($name,'[') else $name
        return $main_name
    for $unique_name in distinct-values($all_names)
    return (element {$unique_name} {request:get-parameter($unique_name, ''), local:get-subelements($unique_name)})
};

declare function local:get-subelements($elem as xs:string) as node()* {
    let $all_names :=  
        for $name in request:get-parameter-names()
            let $start := substring($name,1,string-length($elem))
            let $remainder := substring-after($name,$elem)
            let $subname := if(contains($remainder,'[')) then substring-before(substring-after($remainder,'['),']') else ''
            where $start = $elem and $subname != ''
        return $subname
    for $unique_name in distinct-values($all_names)
        let $new_elem := concat($elem,'[',$unique_name,']')
    return (element {$unique_name} {request:get-parameter($new_elem, ''), local:get-subelements($new_elem)})
};

declare function local:get_post_data() as node() {
    let $results :=
    <results>
      <headers>
         {for $header in request:get-header-names()
          return
             <header name="{$header}" value="{request:get-header($header)}"/>
         }
      </headers>
      <post-parameters>
      {
        for $parameter in local:get-elements()
        return $parameter
      }
      </post-parameters>
    </results>
    return $results
};

(: Transformation :)

declare function local:single_transformation($mei as node(), $settings as node()*) as node()? {
    let $xsl    := doc(concat($database,'/',$xsldir,'/',$settings/xslt))
    let $params := 
        <parameters>
        {
            for $param in $settings/parameters/*
            return <param name="{name($param)}" value="{$param/string()}"/>
        }    
        </parameters>
     return transform:transform($mei,$xsl,$params) 
};

let $show-parameters := if ($post/post-parameters/show) then
        (: POST request; everything should be provided in the posted data :)
        $post/post-parameters/show
    else
        (: GET request; only file name and the optional parameters "mdiv" and "xsl" are expected in the query string :) 
        <show>
            <xslt>{request:get-parameter('xsl', $defaultXSL)}</xslt>
            <parameters>
                <mdiv>{request:get-parameter('mdiv', '')}</mdiv>
            </parameters>
        </show>

let $fileURI := concat($database,'/',$datadir,'//',$post/post-parameters/doc)

let $doc := 
    for $d in collection(concat($database,'/',$datadir))//m:mei
        where ( util:document-name($d) = $post/post-parameters/doc )
    return $d

let $mei :=   
    if($doc) then   
        let $step1 := local:single_transformation($doc[1], $show-parameters)    
        let $step2 := if($post/post-parameters/transpose) then local:single_transformation($step1, $post/post-parameters/transpose) else $step1
        let $step3 := if($post/post-parameters/clef) then local:single_transformation($step2, $post/post-parameters/clef) else $step2
        let $step4 := if($post/post-parameters/noteValues) then local:single_transformation($step3, $post/post-parameters/noteValues) else $step3
        let $step5 := if($post/post-parameters/beams) then local:single_transformation($step4, $post/post-parameters/beams) else $step4     
    return 
        $step5
    else
        concat('Document ',$fileURI,' not found')
        
(: consider: transform:stream-transform(), see http://exist-db.org/exist/apps/doc/xsl-transform.xml  :)        

(: if a target ID is provided, wrap the response in a <response> element communicating back the ID :)
let $response := if ($post/post-parameters/id) then 
        <response targetId="{$post/post-parameters/id}">{$mei}</response>
    else
        $mei

(: allow access from other servers/locations (e.g., a local viewer or an edition on a different server) :)          
let $headers := response:set-header("Access-Control-Allow-Origin", "*")  

return $response 