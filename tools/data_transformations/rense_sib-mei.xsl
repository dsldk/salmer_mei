<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.music-encoding.org/ns/mei" xmlns="http://www.music-encoding.org/ns/mei"
    xmlns:local="http://this.file" xmlns:exsl="http://exslt.org/common"
    xmlns:math="http://exslt.org/math" extension-element-prefixes="math"
    exclude-result-prefixes="m exsl local">

    <xsl:output indent="yes"/>

    <!-- Get the file name -->
    <xsl:variable name="file" select="tokenize(base-uri(),'/')[last()]"/>


    <xsl:template match="/">
        <xsl:text>
</xsl:text>
        <xsl:processing-instruction name="xml-model">href="https://music-encoding.org/schema/4.0.0/mei-all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
        <xsl:processing-instruction name="xml-model">href="https://music-encoding.org/schema/4.0.0/mei-all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
        <!-- Add local schema -->
        <!--<xsl:call-template name="add_local_schema"/>-->    
        <!-- 1st run: make @xml:ids unique by adding the file name -->
        <xsl:variable name="unique_ids">
            <xsl:apply-templates mode="new_ids"/>
        </xsl:variable>
        <xsl:variable name="data" select="exsl:node-set($unique_ids)"/>
        <xsl:copy>
            <xsl:apply-templates select="$data/*"/>
        </xsl:copy>
        <!--<xsl:copy-of select="$data"/>-->
    </xsl:template>

    <!-- First transformation: make unique @xml:id values -->
    <xsl:template match="@startid | @endid" mode="new_ids">
        <xsl:attribute name="{local-name()}"
            select="concat('#',substring-before($file,'.'),'_',substring-after(.,'#'))"/>
    </xsl:template>

    <xsl:template match="*|text()|@*" mode="new_ids">
        <xsl:copy>
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id"
                    select="concat(substring-before($file,'.'),'_',@xml:id)"/>
            </xsl:if>
            <xsl:apply-templates select="node()|@*[not(name()='xml:id')]" mode="new_ids"/>
        </xsl:copy>
    </xsl:template>


    <!-- Main transformation -->

    <xsl:template name="add_local_schema">
        <!-- Associate local MEI XML schema -->
        <xsl:processing-instruction name="xml-model">href="file:/P:/MEI/schema/MEI%204.0/mei-all.rng" type="application/xml"schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
        <xsl:processing-instruction name="xml-model">href="file:/P:/MEI/schema/MEI%204.0/mei-all.rng" type="application/xml"schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
    </xsl:template>
    

    <xsl:template match="m:mei">
        <xsl:copy>
            <xsl:attribute name="meiversion">4.0.0</xsl:attribute>
            <xsl:apply-templates select="@*[name()!='meiversion'] | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- migrating to MEI 4.0.0 -->
    
    <!-- omit workDesc (changed to workList in MEI 4.0 but not used here) -->
    <xsl:template match="m:workDesc"/>
    
    <!-- move pulses-per-quarter duration from @dur.ges to @dur.ppq -->
    <!-- (SibMei uses quarter = 256 ) -->
    <xsl:template match="@dur.ges">
        <xsl:attribute name="dur.ppq"><xsl:value-of select="translate(.,'p','')"/></xsl:attribute>
    </xsl:template>
    
    <!-- End MEI 4.0.0 migration -->
    

    <!-- Determine meter; default to 4/4 -->
    <xsl:template name="get_meter_count">
        <xsl:variable name="meter_count">
            <xsl:choose>
                <xsl:when
                    test="ancestor-or-self::m:measure/preceding-sibling::m:scoreDef[1]/@meter.count">
                    <xsl:value-of
                        select="ancestor-or-self::m:measure/preceding-sibling::m:scoreDef[1]/@meter.count"
                    />
                </xsl:when>
                <xsl:when
                    test="ancestor-or-self::m:section/preceding-sibling::m:scoreDef[1]/@meter.count">
                    <!-- first scoreDef is one level higher -->
                    <xsl:value-of
                        select="ancestor-or-self::m:section/preceding-sibling::m:scoreDef[1]/@meter.count"
                    />
                </xsl:when>
                <xsl:otherwise>4</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$meter_count"/>
    </xsl:template>

    <xsl:template name="get_meter_unit">
        <xsl:variable name="meter_unit">
            <xsl:choose>
                <xsl:when
                    test="ancestor-or-self::m:measure/preceding-sibling::m:scoreDef[1]/@meter.unit">
                    <xsl:value-of
                        select="ancestor-or-self::m:measure/preceding-sibling::m:scoreDef[1]/@meter.unit"
                    />
                </xsl:when>
                <xsl:when
                    test="ancestor-or-self::m:section/preceding-sibling::m:scoreDef[1]/@meter.unit">
                    <xsl:value-of
                        select="ancestor-or-self::m:section/preceding-sibling::m:scoreDef[1]/@meter.unit"
                    />
                </xsl:when>
                <xsl:otherwise>4</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$meter_unit"/>
    </xsl:template>
    
    <xsl:template name="get_latest_staff_attr">
        <!-- get current value of @key.sig, @clef.shape and other staff-related attributes -->
        <xsl:param name="attr"/>
        <xsl:choose>
            <xsl:when test="name(following-sibling::*[name()='scoreDef' or name()='measure'][1]) = 'scoreDef' and 
                following-sibling::m:scoreDef[1]/@*[local-name()=$attr]">
                <!-- 1st measure in a section; if there is a <scoreDef> before it having the desired attribute, move the attribute to the new main <scoreDef> -->
                <xsl:apply-templates select="following-sibling::m:scoreDef[1]/@*[local-name()=$attr]"/>
            </xsl:when>
            <xsl:when test="preceding-sibling::*//*[local-name()=substring-before($attr,'.')]/@*[local-name()=substring-after($attr,'.')]">
                <!-- else see if there is a preceding <clef> element (keySig probably not used by SibMei) re-defining the attribute -->
                <xsl:value-of select="preceding-sibling::*//*[local-name()=substring-before($attr,'.')][1]/@*[local-name()=substring-after($attr,'.')]"/>
            </xsl:when>
            <xsl:when test="preceding-sibling::*[@*[local-name()=$attr]]">
                <!-- else see if there is a preceding sibling element (scoreDef) re-defining the attribute -->
                <xsl:value-of select="preceding-sibling::*[@*[local-name()=$attr]][1]/@*[local-name()=$attr]"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- otherwise go back to the top-level scoreDef to get it -->
                <xsl:value-of select="//m:body/m:mdiv[1]/m:score[1]/m:scoreDef//m:staffDef[1]/@*[local-name()=$attr]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <!-- Turn <pb/> elements into <mdiv> wrappers                                   -->
    <!-- Adapted from https://github.com/bleierr/XSLT-turn-milestones-into-wrapper-elements/ -->
    <xsl:template match="m:mdiv[m:score/m:section/m:pb]">
        <!-- If the score contains any page breaks, turn pages into separate mdivs -->
        <mdiv xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*[name()!='xml:id' and name()!='n']"/>
            <xsl:attribute name="n">1</xsl:attribute>
            <xsl:attribute name="xml:id">mdiv-01</xsl:attribute>
            <score>
                <xsl:apply-templates select="m:score/@*"/>
                <scoreDef>
                    <xsl:apply-templates select="m:score/m:scoreDef/@*"/>
                    <staffGrp>
                        <xsl:apply-templates select="m:score/m:scoreDef/m:staffGrp/@*[not(name()='symbol')]"/><!-- omit any piano brace -->
                        <staffDef>
                            <xsl:apply-templates
                                select="m:score/m:scoreDef/m:staffGrp//m:staffDef/@*[not(name()='label')]"/><!-- omit instrument label -->
                        </staffDef>
                    </staffGrp>
                </scoreDef>
                <section>
                    <xsl:apply-templates
                        select="m:score/m:section/@* | m:score/m:section/node()[not(preceding-sibling::m:pb) and not(name()='pb')]"/>
                    <pb/>
                </section>
            </score>
        </mdiv>
        <xsl:for-each select="m:score/m:section/m:pb">
            <!-- loops over all pb elements and turns them into div@class=page_wrapper 
                the current pb node is then passed to the processNextNode template
                if the current pb node is the last pb, templates will be applied to its following siblings, and processing ends
            -->
            <mdiv xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:variable name="n" select="count(preceding-sibling::m:pb) + 2"/>
                <xsl:variable name="npadded" select="concat('00',$n)"/>
                <xsl:attribute name="xml:id"
                    select="concat('mdiv-',substring($npadded,string-length($npadded)-1,2))"/>
                <xsl:attribute name="n" select="$n"/>
                <score>
                    <scoreDef>
                        <staffGrp>
                            <staffDef n="1">
                                <!-- get current staff atributes -->
                                <xsl:attribute name="key.sig">
                                    <xsl:call-template name="get_latest_staff_attr">
                                        <xsl:with-param name="attr">key.sig</xsl:with-param>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <xsl:attribute name="clef.shape">
                                    <xsl:call-template name="get_latest_staff_attr">
                                        <xsl:with-param name="attr">clef.shape</xsl:with-param>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <xsl:attribute name="clef.line">
                                    <xsl:call-template name="get_latest_staff_attr">
                                        <xsl:with-param name="attr">clef.line</xsl:with-param>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <xsl:attribute name="lines">
                                    <xsl:call-template name="get_latest_staff_attr">
                                        <xsl:with-param name="attr">lines</xsl:with-param>
                                    </xsl:call-template>
                                </xsl:attribute>
                            </staffDef>
                        </staffGrp>
                    </scoreDef>
                    <section>
                        <xsl:choose>
                            <xsl:when test="position() = last()">
                                <xsl:apply-templates
                                    select="following-sibling::node()
                                    [not(local-name()='sb' and local-name(preceding-sibling::*[1])='pb')]"/>
                                <!-- process following nodes, but skip <sb/> after <pb/> -->
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="processNextNode">
                                    <xsl:with-param name="Node" select="."/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                        <pb/>
                    </section>
                </score>
            </mdiv>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="processNextNode">
        <!-- this template takes node as input and processes its next following sibling  -->
        <xsl:param name="Node"/>
        <xsl:variable name="nextNode" select="$Node/following-sibling::node()[1]"/>
        <xsl:choose>
            <xsl:when test="$nextNode/descendant-or-self::m:pb">
                <!-- if next node contains a pb as child go to foundPb template -->
                <xsl:call-template name="foundPb">
                    <xsl:with-param name="Node" select="$nextNode"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="not($nextNode)">
                        <!-- no next node - pass parent to processNextNode -->
                        <xsl:call-template name="processNextNode">
                            <xsl:with-param name="Node" select="$Node/parent::node()"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <!--  apply templates of next node and pass next node to processNextNode-->
                        <xsl:apply-templates
                            select="$nextNode[not(local-name()='sb' and 
                            local-name(preceding-sibling::*[1])='pb')]"/>
                        <!-- process following nodes, but skip <sb/> after <pb/> -->
                        <xsl:call-template name="processNextNode">
                            <xsl:with-param name="Node" select="$nextNode"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="foundPb">
        <xsl:param name="Node"/>
        <!-- choose the first child node of the node passed to this template -->
        <xsl:variable name="childNode" select="$Node/child::node()[1]"/>
        <xsl:choose>
            <xsl:when test="local-name($Node) = 'pb'">
                <!-- do nothing if node is pb -->
            </xsl:when>
            <xsl:when test="$Node//m:pb">
                <xsl:call-template name="foundPb">
                    <xsl:with-param name="Node" select="$childNode"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$Node"/>
                <xsl:call-template name="processNextNode">
                    <xsl:with-param name="Node" select="$Node"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- End <pb> processing -->


    <!-- Delete elements -->
    <xsl:template match="m:fileDesc/m:titleStmt/m:respStmt[not(m:resp or m:persName/@role)]"/>
    <xsl:template match="m:instrDef"/>
    <xsl:template match="m:accid"/>
    
    <!-- Keep only <scoreDef> elements if they change key signature and occur in the middle of a (new) <mdiv> -->
    <xsl:template match="m:scoreDef[not(* or @key.sig) or name(preceding-sibling::*[name()='pb' or name()='measure'][1]) = 'pb']"/>
    
    <!-- Delete attributes -->
    <xsl:template
        match="
        @meter.count |
        @meter.unit |
        @lyric.name |
        @music.name |
        @page.botmar |
        @page.height |
        @page.leftmar |
        @page.rightmar |
        @page.topmar |
        @page.width |
        @ppq |
        @text.name"/>
    <xsl:template match="@key.mode"/>
    <xsl:template match="m:measure/@label | m:measure/@metcon | m:measure/@n"/>

    <!-- Delete instrument comments -->
    <xsl:template match="m:staffDef/comment()"/>

    <!-- Delete initial system break -->
    <xsl:template match="m:section/m:sb[count(preceding-sibling::*)=0]"/>

    <!-- Add a page break at the end of each section to make Verovio recognize system breaks -->
    <xsl:template match="m:section">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <pb xmlns="http://www.music-encoding.org/ns/mei"/>
            <xsl:text>
            </xsl:text>
        </xsl:copy>
    </xsl:template>

    <!-- Verovio prefers accidentals defined as attributes, not elements -->
    <xsl:template match="m:note[m:accid]">
        <note xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="m:accid/@accid | m:accid/@accid.ges"/>
            <xsl:apply-templates select="node()"/>
        </note>
    </xsl:template>
    
    <!-- Ligature (= exported from Sibelius as tuplets with @num=@numbase) and coloration (Sibelius: Upbow/downbow) brackets  -->

    <!-- Use <bracketSpan> for ligature brackets, not tuplets -->
    <xsl:template match="m:tuplet[@num=@numbase]">
        <!-- remove note-spanning tuplet element  -->
        <xsl:apply-templates select="*"/>
    </xsl:template>
    
    <xsl:template match="@artic">
        <xsl:if test="not(.='upbow' or .='dnbow')">
            <!-- up- and downbow are treated as coloration markers elsewhere -->
            <xsl:attribute name="artic"><xsl:value-of select="."/></xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match="m:measure">
        <measure xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@* | node()"/>
            <!-- Add <bracketSpan> at the end of the measure -->
            <!-- Ligatures -->
            <xsl:for-each select=".//m:tuplet[@num=@numbase]">
                <bracketSpan>
                    <xsl:copy-of select="@xml:id"/>
                    <xsl:attribute name="func">ligature</xsl:attribute>
                    <xsl:attribute name="startid">
                        <xsl:value-of select="@startid"/>
                    </xsl:attribute>
                    <xsl:attribute name="endid">
                        <xsl:value-of select="@endid"/>
                    </xsl:attribute>
                    <xsl:attribute name="staff">
                        <xsl:value-of select="ancestor::m:staff/@n"/>
                    </xsl:attribute>
                    <xsl:attribute name="lwidth">medium</xsl:attribute>
                    <xsl:attribute name="lform">solid</xsl:attribute>
                </bracketSpan>
            </xsl:for-each>
            <!-- Coloration -->
            <xsl:for-each select=".//*[@artic='upbow']">
                <bracketSpan>
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="concat(@xml:id,'_coloration')"/>
                    </xsl:attribute>
                    <xsl:attribute name="func">coloration</xsl:attribute>
                    <xsl:attribute name="startid">
                        <xsl:value-of select="concat('#',@xml:id)"/>
                    </xsl:attribute>
                    <xsl:attribute name="endid">
                        <xsl:choose>
                            <xsl:when test="following-sibling::*[@artic='dnbow']">
                                <xsl:value-of select="concat('#',following-sibling::*[@artic='dnbow'][1]/@xml:id)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- if no coloration end is marked within the same measure, it it assumed that only one note is colored -->
                                <xsl:value-of select="concat('#',@xml:id)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="staff">
                        <xsl:value-of select="ancestor::m:staff/@n"/>
                    </xsl:attribute>
                    <xsl:attribute name="lwidth">medium</xsl:attribute>
                </bracketSpan>
            </xsl:for-each>
        </measure>
    </xsl:template>
    

    <xsl:template match="m:sb | m:pb">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="label">editorial</xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <!-- This template is needed in order to override behaviour when handling neumes -->
    <xsl:template match="m:fermata">
        <xsl:apply-templates select="." mode="fermata"/>
    </xsl:template>

   
    <!-- Interpret angle fermatas as system breaks and square fermatas as page breaks in the source -->
    <xsl:template match="m:fermata[@shape='angular' or @shape='square']" mode="fermata">
        <xsl:variable name="attached_to_id" select="translate(@startid,'#','')"/>
        <xsl:variable name="meter_count">
            <xsl:call-template name="get_meter_count"/>
        </xsl:variable>
        <xsl:variable name="meter_unit">
            <xsl:call-template name="get_meter_unit"/>
        </xsl:variable>
        <xsl:variable name="tstamps">
            <xsl:call-template name="tstamps"/>
        </xsl:variable>
        <xsl:variable name="bar_length_beats" select="sum($tstamps//@ticks) * $meter_unit div 1024"/>
        <xsl:variable name="attached_position"
            select="$tstamps/local:tstamp[@id=$attached_to_id]/@at_ticks"/>
        <xsl:variable name="duration" select="$tstamps/local:tstamp[@id=$attached_to_id]/@ticks"/>
        <xsl:variable name="position">
            <xsl:choose>
                <!--<xsl:when test="count(following-sibling::*[@dur.ges])=0">-->
                <xsl:when
                    test="not($tstamps/local:tstamp[@id=$attached_to_id]/following-sibling::*)">
                    <!-- if connected to last timed object in measure: place break at end of measure (with an offset for horizontal adjustment) -->
                    <xsl:value-of select="$attached_position + $duration - 64"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- in middle of measure: place halfway between this and the next timed object -->
                    <xsl:value-of select="$attached_position + ($duration div 2)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- as the original meter will be deleted from the file, timestamps need to be calculated using quarters as unit of measurement (Verovio's default) -->
        <xsl:variable name="tstamp"
            select="1 + ($position div 1024) * $meter_count * 4 div $bar_length_beats"/>
        <!-- render the system and page breaks as directives marking the breaks -->
        <xsl:choose>
            <xsl:when test="@shape='angular'">
                <dir type="sb" xmlns="http://www.music-encoding.org/ns/mei" tstamp="{$tstamp}"
                    place="above" label="Linjeskift" xml:id="{@xml:id}">ǀ</dir>
            </xsl:when>
            <xsl:otherwise>
                <dir type="pb" xmlns="http://www.music-encoding.org/ns/mei" tstamp="{$tstamp}"
                    place="above" label="Sideskift" xml:id="{@xml:id}">ǁ</dir>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="m:fermata[not(@shape='angular' or @shape='square')]" mode="fermata">
        <!-- The SibMei exporter erroneously exports both time stamp and start ID -->
        <fermata xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*[not(name()='tstamp')]"/>
        </fermata>
    </xsl:template>
    
    <!-- SLURS -->

    <!-- Convert slur endpoints from timestamps to ID refs and store them i a global variable (needed for neume handling) -->
    <xsl:variable name="slurs_old_ids">
        <xsl:for-each select="//m:slur">
            <xsl:call-template name="slur_with_endpoint-ids"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="slurs">
        <xsl:for-each select="exsl:node-set($slurs_old_ids)/m:slur">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="new_ids"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:variable>

    <!-- In non-neume notation: retain slurs, but replace timestamps with ID refs -->
    <xsl:template match="m:slur">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:copy-of select="$slurs/m:slur[@xml:id=$id]"/>
    </xsl:template>

    <xsl:template name="slur_with_endpoint-ids">
        <slur xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:variable name="tstamps">
                <xsl:call-template name="tstamps"/>
            </xsl:variable>
            <xsl:variable name="tstamp1" select="@tstamp"/>
            <xsl:attribute name="startid">#<xsl:value-of
                    select="ancestor-or-self::m:measure//node()[@xml:id=$tstamps/local:tstamp[round(@at*100)=round($tstamp1*100)]/@id]/@xml:id"
                /></xsl:attribute>
            <xsl:choose>
                <xsl:when test="@tstamp2">
                    <!-- It is assumed that slurs do not cross bar lines -->
                    <xsl:variable name="tstamp2" select="number(substring-after(@tstamp2,'m+'))"/>
                    <xsl:attribute name="endid">#<xsl:value-of
                            select="ancestor-or-self::m:measure//node()[@xml:id=$tstamps/local:tstamp[round(@at*100)=round($tstamp2*100)]/@id]/@xml:id"
                        /></xsl:attribute>
                    <xsl:apply-templates select="@*[not(name()='tstamp' or name()='tstamp2')]"/>
                </xsl:when>
                <xsl:when test="@dur.ges">
                    <xsl:variable name="slur_dur"
                        select="number(translate(@dur.ges,'p','')) div 1024"/>
                    <xsl:attribute name="endid">#<xsl:value-of
                            select="ancestor-or-self::m:measure//m:note[@xml:id=$tstamps/local:tstamp[round(@at*100)=round(($tstamp1+$slur_dur)*100)]/@id]/@xml:id"
                        /></xsl:attribute>
                    <xsl:apply-templates select="@*[not(name()='tstamp' or name()='dur.ges')]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*"/>
                </xsl:otherwise>
            </xsl:choose>
        </slur>
    </xsl:template>


    <!-- VARIOUS CALCULATIONS RELATED TO TIME STAMPS AND DURATIONS -->

    <!-- Calculate duration of context node -->
    <xsl:template name="duration">
        <xsl:param name="meter_unit"/>
        <xsl:variable name="dots">
            <xsl:choose>
                <xsl:when test="@dots">
                    <xsl:value-of select="@dots"/>
                </xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="(number($meter_unit) div @dur) * math:power(1.5 , round($dots))"/>
    </xsl:template>

    <!-- Generate list of duration elements in measure -->
    <xsl:template name="duration_elements">
        <elements xmlns="http://this.file">
            <xsl:for-each select="ancestor-or-self::m:measure/m:staff/m:layer[@n='1']//*[@dur]">
                <element xmlns="http://this.file">
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="ticks" select="number(translate(@dur.ges,'p',''))"/>
                </element>
                <xsl:text>
                    </xsl:text>
            </xsl:for-each>
        </elements>
    </xsl:template>

    <xsl:template name="get_id_at_tstamp">
        <xsl:param name="tstamp"/>
        <xsl:variable name="tstamps">
            <xsl:call-template name="tstamps"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$tstamps/local:tstamp[@at=$tstamp]/@id">
                <xsl:value-of select="$tstamps/local:tstamp[@at=$tstamp]/@id"/>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Convert value of @dur.ges to timestamp value -->
    <xsl:template name="dur_to_tstamp">
        <xsl:param name="dur"/>
        <xsl:variable name="elements">
            <xsl:call-template name="duration_elements"/>
        </xsl:variable>
        <xsl:variable name="meter_count">
            <xsl:call-template name="get_meter_count"/>
        </xsl:variable>
        <xsl:variable name="meter_unit">
            <xsl:call-template name="get_meter_unit"/>
        </xsl:variable>
        <xsl:variable name="bar_length_beats" select="sum($elements//@ticks) * $meter_unit div 1024"/>
        <xsl:variable name="tstamp"
            select="($dur div 1024) * $meter_count * $meter_unit div $bar_length_beats"/>
        <xsl:value-of select="$tstamp"/>
    </xsl:template>

    <!-- Generate list of ids with their duration and tstamp position in measure (layer 1 only) -->
    <xsl:template name="tstamps">
        <xsl:variable name="meter_count">
            <xsl:call-template name="get_meter_count"/>
        </xsl:variable>
        <xsl:variable name="meter_unit">
            <xsl:call-template name="get_meter_unit"/>
        </xsl:variable>
        <xsl:variable name="elements">
            <xsl:call-template name="duration_elements"/>
        </xsl:variable>
        <xsl:variable name="bar_length_beats" select="sum($elements//@ticks) * $meter_unit div 1024"/>
        <xsl:variable name="tstamps">
            <xsl:for-each select="$elements/local:elements/*">
                <xsl:variable name="pos" select="position()"/>
                <tstamp xmlns="http://this.file">
                    <xsl:attribute name="id" select="@xml:id"/>
                    <xsl:attribute name="ticks" select="@ticks"/>
                    <xsl:variable name="position_ticks"
                        select="sum($elements/local:elements/local:element[$pos]/preceding-sibling::*/@ticks) "/>
                    <xsl:attribute name="at_ticks" select="$position_ticks"/>
                    <xsl:variable name="tstamp_offset"
                        select="($position_ticks div 1024) * $meter_count * $meter_unit div $bar_length_beats"/>
                    <!-- timestamp position -->
                    <xsl:attribute name="at" select="1 + $tstamp_offset"/>
                </tstamp>
                <xsl:text>
        </xsl:text>
            </xsl:for-each>
        </xsl:variable>
        <xsl:copy-of select="$tstamps"/>
    </xsl:template>



    <xsl:template match="*|text()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>
