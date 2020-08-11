module namespace settings="http://dsl.dk/salmer/settings";

declare function settings:language($new_language as xs:string) as xs:string {
    (: Set and return language :)
    let $language := if(normalize-space($new_language))
        then
            $new_language 
        else if(normalize-space(request:get-cookie-value("language")))
        then 
            request:get-cookie-value("language")
        else 
            "da"    
    let $language_cookie := response:set-cookie("language", $language)    
    return $language
};    

