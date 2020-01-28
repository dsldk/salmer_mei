xquery version "1.0" encoding "UTF-8";

(: A script to generate a select box for browsing by title. :)
(: Uses uniform titles or - if no uniform title is given - the first title given :)

declare namespace m="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/salmer";  
declare variable $datadir  := "data";


<select xmlns="http://www.w3.org/1999/xhtml" id="title_select" onchange="document.getElementById('query_title').value = this.value; document.getElementById('title_form').submit();">
    <option value="" selected="selected">Vælg fra liste</option>
    {
    for $c in  distinct-values(collection(concat($database,'/',$datadir))/m:mei/m:meiHead/m:workList/m:work[1]/m:title
    [@type="uniform" or count(../m:title[@type])=0][1]/normalize-space(string()))
            order by lower-case($c)
            return 
               <option value="{$c}">{$c}</option>
    }
</select>
