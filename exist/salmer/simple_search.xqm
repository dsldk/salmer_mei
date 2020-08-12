module namespace search="http://dsl.dk/salmer/search";

declare function search:searchbox() as node()* {
    let $output as node() :=
        <div class="main-top-section background-cover" xmlns="http://www.w3.org/1999/xhtml">
            <div class="container">
                <input type="checkbox" id="search-field-toggle"/>
                <label for="search-field-toggle"><span class="sr-only">Vis/skjul søgefelt</span></label>
                    <div id="search-field">
                        <form action="mei_search.xq" method="get" id="search-mobile">
                            <div class="search-line input-group">
                                <span class="input-group-addon"><img src="/style/img/search.png" alt=""/></span>
                                <input id="query_title" type="text" class="form-control" name="qt" placeholder="Søg i salmetitlerne i databasen" value=""/>
                                <button title="Søg" class="btn btn-primary arrow-r" type="submit" onclick="this.form['x'].value = updateAction();"/>
                                <input name="x" id="x1" type="hidden" value=""/>
                            </div>
                        </form>
                        <div>
                            {doc("assets/title_select.html")}
                        </div>
                        <div id="advanced-search-link">
                            <a href="mei_search.xq">Avanceret søgning</a>
                        </div>
                    </div>
            </div>
        </div>
    return $output
};    

