module namespace search="http://dsl.dk/salmer/search";

declare function search:searchbox($lang_module as node()*) as node()* {
    let $output as node() :=
        <div class="main-top-section background-cover" xmlns="http://www.w3.org/1999/xhtml">
            <div class="container">
                <input type="checkbox" id="search-field-toggle"/>
                <label for="search-field-toggle"><span class="sr-only">{$lang_module/*[name()='toggle_search_field']/text()}</span></label>
                <div id="search-field">
                    <form action="mei_search.xq" method="get" id="search-mobile">
                        <div class="search-line input-group">
                            <span class="input-group-addon"><img src="/style/img/search.png" alt=""/></span>
                            <input id="query_title" type="text" class="form-control" name="qt" placeholder="{$lang_module/*[name()='search_placeholder_title']/text()}" value=""/>
                            <button title="{$lang_module/*[name()='search_button']/text()}" class="btn btn-primary arrow-r" type="submit" onclick="this.form['x'].value = updateAction();"/>
                            <input name="x" id="x1" type="hidden" value=""/>
                        </div>
                    </form>
                    <div>
                        <select xmlns="http://www.w3.org/1999/xhtml" class="select-css" id="title_select" onchange="document.getElementById('query_title').value = this.value; document.getElementById('query_title').focus(); this.value='';">
                            <option value="" selected="selected">{$lang_module/*[name()='choose_from_list']/text()}</option>
                            {doc("assets/title_select.html")/*/*}
                        </select>
                    </div>
                    <div id="advanced-search-link">
                        <a href="mei_search.xq">{$lang_module/*[name()='advanced_search']/text()}</a>
                    </div>
                </div>
            </div>
        </div>
    return $output
};    

