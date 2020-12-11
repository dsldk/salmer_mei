(: List duplicate IDs in texts :)
(: TEI files are assumed to be located in /db/tools/tekster/ :)

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:get_all_ids() as node() {
    let $output := 
        for $book in collection("/db/tools/tekster")/tei:TEI
            let $text_id := tokenize(document-uri(root($book)),'/')[last()]
            let $ids := 
                for $elem in $book//*[@xml:id]
                    let $name := local-name($elem)
                    let $id := $elem/@xml:id/string()
    (: where $text_id = "jespersen_1573.xml" :) 
                
                order by $elem/@xml:id
                return element {$name} {
                    attribute xml:id { $id }
                }
        return 
            <text file="{$text_id}">
                {$ids}
            </text>
            
    return
        <all-ids>
             {$output}
        </all-ids>
};


let $all_ids := local:get_all_ids()

let $elements :=  $all_ids//*[@xml:id]
let $ids :=  $all_ids//@xml:id/string()

let $output := 
    for $id in $ids[index-of($ids,.)[2]]
        let $texts := 
            for $elem in $elements[@xml:id/string() = $id]
            return <text file="{$elem/parent::text/@file}"/>
        let $count:= count($texts)
    order by $count descending, $id
    return 
        <duplicate xml:id="{$id}" count="{$count}">{$texts}</duplicate>  

return
    <index>
        {$output}
        <total>{sum($output/@count)}</total>
    </index>