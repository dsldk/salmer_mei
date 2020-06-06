xquery version "3.0" encoding "UTF-8";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/salmer";  

let $output :=
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	    <title>Vejledning – Salmemelodier – DSL</title>
        <meta charset="UTF-8"/>
        
        
        <link rel="stylesheet" href="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.css" />
        
        <link rel="stylesheet" type="text/css" href="style/magenta/dsl-basis_screen.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/elements.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/select-css.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/layout.css" />
        <link rel="stylesheet" type="text/css" href="style/magenta/styles.css"/>
        <link rel="stylesheet" type="text/css" href="style/magenta/dsl-basis_print.css" media="print"/>
        <link rel="stylesheet" type="text/css" href="style/magenta/print.css" media="print"/>
        
        <link rel="stylesheet" type="text/css" href="style/magenta/mei.css"/>
        <link rel="stylesheet" type="text/css" href="style/mei_search.css"/>
        
        <script type="text/javascript" src="js/libs/jquery/jquery-3.2.1.min.js">/* jquery */</script>
        <script type="text/javascript" src="js/libs/jquery/jquery-ui-1.12.1/jquery-ui.js">/* jquery ui */</script>     

        <script type="text/javascript" src="js/magenta/javascript.js">/* "Tekstnet" JS */</script>

        
	</head>
	<body class="metadata">
	
       <header xmlns="http://www.w3.org/1999/xhtml" class="header" id="header">
       
            <!-- Page head -->
	        {doc(concat($database,"/assets/magenta/header.html"))}
	       
            <!-- Search -->
	           
            <div class="main-top-section background-cover">
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
                                {doc("assets/magenta/title_select.html")   (: or generate dynamically with: local:get_titles() :)}
                            </div>
                            <div id="advanced-search-link">
                                <a href="mei_search.xq">Avanceret søgning</a>
                            </div>
                        </div>
                </div>
            </div>

	   </header>
	   
       <div class="page-wrapper">
            <div class="background-box">
                <div class="headline-box container">
                    <h2>Vejledning til melodibasen</h2>
                </div>
            </div>
            <div class="documentFrame container">

            <ul>
                <li><a href="#introduction">Hvad indeholder databasen?</a></li>
                <li><a href="#notation">Brug af noderne</a>
                    <ul>
                        <li><a href="#play">Afspilning</a></li>
                        <li>
                            <a href="#notation">Ændring af noderne</a>
                            <ul>
                                <li><a href="#clef">Nøgler</a></li>
                                <li><a href="#duration">Nodeværdier</a></li>
                                <li><a href="#transposition">Transponering</a></li>
                            </ul>
                        </li>
                    </ul>
                </li>
                <li><a href="#search">Søgning</a>
                    <ul>
                        <li><a href="#search_title">Titelsøgning</a></li>
                        <li><a href="#advanced">Melodisøgning</a>
                            <ul>
                                <li><a href="#search_pitchname">Søgning efter tonenavne</a></li>
                                <li><a href="#search_contour">Søgning efter melodikontur</a></li>
                                <li><a href="#search_notation">Søgning efter noder</a></li>
                            </ul>
                        </li>
                    </ul>
                </li>

            </ul>
            
            <h2><a name="introduction">Hvad indeholder databasen?</a></h2>
            <p>Databasen <em>Salmemelodier. Danske reformationssalmer 1529-1573</em> indeholder de melodier, der optræder i de danske salmebøger fra årene 1529-1573, som er udgivet digitalt på  
            <a href="https://tekstnet.dk/search?category=reformationstiden" target="_blank" titel="Digital udgave af salmebøgerne">tekstnet.dk</a>.<br/>
            Udover noderne indeholder basen historisk information om melodierne og illustrerer deres indbyrdes forbindelser.</p>
            <p>Materialet beskrives på forskellige niveauer, og for at lette overblikket er de forskellige posttyper og interne links farvekodet som følger:</p>
            <table>
                <tr>
                    <td><span class="relation music_document">Melodi i publikation</span></td>
                    <td>Melodi, som den står i en bestemt salmebog.<br/> 
                    Hvis melodien ikke forekommer i andre af korpussets salmebøgerne, er eventuel historisk information om melodien også her.</td>
                </tr>
                <tr>             
                    <td><span class="relation melody">Melodi</span></td>
                    <td>Samlende beskrivelse af en melodi, som optræder i flere af salmebøgerne. <br/>
                    Her findes den historiske information om melodien generelt samt links til de poster, der beskriver melodien i de enkelte salmebøger. </td>
                </tr>
                <tr>
                    <td><span class="relation publication">Publikation</span></td>
                    <td>Publikationsposterne repæsenterer de enkelte salme- og messebøger, som indeholder melodierne.<br/>
                    Posterne indeholder bl.a. sorterbare indholdsfortegnelser og kan derfor tjene som overblik over og indgang til salmebøgerne.</td>
                </tr>
                <tr>
                    <td><span class="relation liturgy">Liturgisk enhed</span></td>
                    <td>Beskriver en enhed, som typisk består af flere korte melodistykker og tekst, der ikke kan karakteriseres som 
                    en salme, men som tilsammen danner en liturgisk enhed. <br/>
                    Det gælder f.eks. <a href="https://salmer.dsl.dk/document.xq?doc=kyrie_eleison_gud_fader_forbarme_dig.xml">litaniet</a>,
                    som står i både Thomissøns salmebog og Jespersens graduale.</td>
                </tr>
            </table>
            
            <p>Links til den digitale udgave af salmebøgerne er markeret med gult og indikerer med ikoner, om der er tale om en salmetekst med noder:
            <span class="edition_link"><span class="edition" title="Salme med noder">Digital udgave</span></span> eller uden: 
            <span class="edition_link"><span class="text_edition" title="Salmetekst uden noder">Digital udgave</span></span>.</p>
            
            <h2><a name="notation">Brug af noderne</a></h2>

            <p><img style="float:right; margin: 0 0 20px 20px;" src="/style/img/menu.png" title="Nodemenu" alt="Nodemenu"/>Via menuknappen ud for hver melodi er 
            der mulighed for at interagere med noderne på forskellig vis:</p>
            
            <h3><a name="play">Afspilning</a></h3>
            <p>Klik på knappen <img src="/style/img/play.png" title="Afspilning" alt="Afspil"/> (afspilning) for at lytte til melodien. 
            Noderne fremhæves under afspilningen.</p>
            
            <h3><a name="notation">Ændring af noderne</a></h3>
            
            <h4><a name="clef">Nøgler</a></h4>
            <p>Melodierne er ofte noteret med nøgler, som er ualmindelige i dag. For at lette læsningen kan nøglerne udskiftes med mere nutidige: 
            G-nøgle, oktaverende G-nøgle (&quot;tenornøgle&quot;) eller basnøgle. Klik på den ønskede nøgle i nodemenuen for at skifte nøgle.</p>
            
            <h4><a name="duration">Nodeværdier</a></h4>
            <p>I salmebøgerne er melodierne noteret med ældre nodeformer: enten koralnotation (nodehoveder uden halse) eller mensuralnotation. 
            Mensuralnotation ligner moderne noder, og de er i den digitale udgave noteret med de tilsvarende nutidige noder. 
            Det gør dog, at nodeværdierne kan synes meget lange i forhold til gængs praksis i dag. 
            For at tilpasse noderne mere til nutidig praksis og undgå de meget lange nodeværdier, kan nodeværdier i mensuralnotation reduceres til det halve eller det kvarte ved hjælp af nodemenuen.<br/>
            NB: Ved reduktion af nodeværdier markeres mensurtegnet (det, som vi i dag ville læse som en &quot;taktart&quot;) i begyndelsen af satsen med rødt for at understrege, 
            at det ikke skal læses som en nutidig taktart, men en angivelse af mensur, som ikke umiddelbart kan halveres og derfor vil være misvisende i sammenhæng med de ændrede nodeværdier.</p>
            
            <h4><a name="transposition">Transponering</a></h4>
            <p>Melodierne kan transponeres op eller ned til andre tonearter efter behov ved hjælp af nodemenuen. Afspilningen afspejler den aktuelle transposition.</p>
            
            <h2><a name="search">Søgning</a></h2>
            <p> </p>
            
            <h3><a name="search_title">Titelsøgning</a></h3>
            <p>På alle sider både i salmebasen og den digitale udgave af salmebøgerne er der adgang til at søge i salmernes titler ved at klikke på søgeknappen 
            <img src="/style/img/search.png" title="Søgning" alt="Søgning"/> øverst til højre. <br/>
            Der kan søges enten ved at skrive dele af en salmetitel eller ved at vælge fra listen over titler. </p>
            
            <h3><a name="advanced">Melodisøgning</a></h3> 
            <p>På salmebasens søgeside er der desuden mulighed for at søge i selve melodierne. Søgesiden findes på <a href="mei_search.xq">https://salmer.dsl.dk/mei_search.xq</a>
            eller fra de øvrige sider ved at klikke på &quot;Avanceret søgning&quot; under titelsøgefeltet. Fanebladene giver adgang til en række forskellige søgefuntioner:</p>
            
            <h4><a name="search_pitchname">Søgning efter tonenavne</a></h4>
            <p>Der kan søges efter melodier ved hjælp af tonernes navne. <br/>
            Tonen h skrives <kbd>B</kbd>. Tonen cis/des skrives <kbd>V</kbd>, dis/es <kbd>Y</kbd>, fis/ges <kbd>X</kbd>, gis/as <kbd>Y</kbd> og ais/b <kbd>Z</kbd>.</p>
            <p>EKSEMPEL: <a href="https://salmer.dsl.dk/mei_search.xq?x=&amp;q=CAFACDC" title="Søg efter tonerne CAFACDC">Søgning efter tonerne <kbd>CAFACDC</kbd></a> 
            finder melodien <em>Nu er fød os Jesus Christ / Resonet in laudibus</em> (i dag også kendt som <em>Lad det klinge sødt i sky</em>).</p>
            
            <h4><a name="search_contour">Søgning efter melodikontur</a></h4>
            <p>En mere fleksibel måde at søge i melodierne på er at angive melodiens kontur, dvs. om melodien bevæger sig op (angives ved tegnet <kbd>/</kbd>),
            ned (<kbd>\</kbd>) eller har tonegentagelse (<kbd>-</kbd>). Alternativt kan konturen skrives med bogstaver: <kbd>u</kbd> for &quot;up&quot; (op), 
            <kbd>d</kbd> for &quot;down&quot; (ned) eller <kbd>r</kbd> for &quot;repeat&quot; (tonegentagelse).<br/>
            Da kontursøgningen ikke tager hensyn til intervallernes størrelse, men kun deres retning, finder den langt flere resultater end tonesøgningen. 
            Ofte vil det derfor være hensigtsmæssigt med en længere søgestreng for at begrænse antallet af resultater.</p> 
            <p>EKSEMPEL: <a href="https://salmer.dsl.dk/mei_search.xq?x=&amp;c=dduuudrdduuud" title="Søgning efter konturen \\///\-\\///\">Søgning efter konturen <kbd>\\///\-\\///\</kbd></a> finder – ligesom ovenfor – 
            <em>Nu er fød os Jesus Christ / Resonet in laudibus</em>.</p>
            
            <h4><a name="search_notation">Søgning med noder</a></h4>
            <p>Der kan søges i melodierne ved indtastning af noder. Nodesøgningen tager kun tonehøjder i betragtning, ikke rytme. 
            Der kan indtastes op til 12 toner.</p>
            <p>Søgningen kan indsnævres eller udvides ved et antal valgmuligheder: </p>
            <ul>
                <li>Alle transpositioner: Udvider søgningen til at finde den angivne intervalfølge i alle transpositioner</li>
                <li>Begynder med: Indsnævrer søgningen til kun at søge på melodiernes begyndelse</li>
                <li>Ignorer tonegentagelser: Udvider søgningen ved at se bort fra tonegentagelser, sådan at f.eks. en underdeling af en tone på grund af 
                afvigende antal tekststavelser også findes</li>
                <li>Præcision: Der kan tillades op til to afvigelser fra den angivne søgefrase. Som afvigelser tæller manglende toner, ekstra toner samt afvigende tonehøjder.</li>
            </ul>
            <p>EKSEMPEL: <a href="https://salmer.dsl.dk/mei_search.xq?a=77-77-77-72-76-77-74-72&amp;x=&amp;e=1&amp;f=2" title="Søg efter: Vor Gud han er så fast en borg">Søgning efter de første otte toner af <em>Vor Gud han er 
            så fast en borg</em></a> efter den i dag kendte melodi kræver, at der tillades op til to afvigelser, da femte tone afviger (d i stedet for e) og der er en ektra gennegmgangstone (mellem f og d)
            i den gamle melodiform.</p>
            
            <p><img style="float:right; margin: 0 0 20px 20px;" src="/style/img/search_phrase.png" title="Markering og søgning" alt="Markering"/>Nodesøgningen kan også aktiveres 
            direkte fra salmebøgerne eller noderne i salmebasen: Klik på en node og derefter en anden node for at markere en frase. 
            Klik derefter på markeringen for at søge efter tilsvarende fraser i alle melodierne.</p>
            
            </div>
        </div>

	    <!-- Page footer -->
	    {doc(concat($database,"/assets/magenta/footer.html"))}

    </body>
</html>

return $output