<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:dsl="http://www.dsl.dk" xmlns:m="http://www.music-encoding.org/ns/mei" version="2.0" exclude-result-prefixes="m h dsl xsl">
    
    
    <!-- Prepare MEI for viewing with Verovio -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="mdiv" select="''"/>
    
    <!-- Set MIDI base tempo (BPM) -->
    <xsl:variable name="midi_base_tempo" select="number('100')"/>
    
    <xsl:variable name="editorials" select="'add corr damage del gap orig reg sic supplied unclear annot'"/>
    
    <xsl:template match="m:body">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- Choose a specific <mdiv> element?  -->
            <xsl:choose>
                <xsl:when test="$mdiv!=''">
                    <xsl:apply-templates select="m:mdiv[@xml:id=$mdiv]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Choose only the first one or show all? -->
                    <!--<xsl:apply-templates select="m:mdiv[1]"/>-->
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="m:mdiv">
        <xsl:if test="$mdiv='' and count(//m:mdiv) &gt; 1">
            <!-- mark the beginning of the MDIV? -->
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="m:meterSigGrp[m:meterSig/@sym and m:meterSig/@count]">
        <!-- Verovio doesn't display both number and symbol yet (<meterSigGrp> is not supported, and an appropriate @meter.form value in <scoreDef> not yet available in MEI 3.0.0) -->
        <xsl:for-each select="m:meterSig[@sym or (@count and @unit)]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
        <xsl:apply-templates select="m:meterSig[@count and not(@unit)]"/>
    </xsl:template>
        
    <xsl:template match="m:meterSig[@count and not(@unit)]">
        <mensur xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="num">
                <xsl:value-of select="@count"/>
            </xsl:attribute>
            <xsl:copy-of select="@xml:id"/>
        </mensur>
    </xsl:template>
    
    <!-- Verovio doesn't display count-only time signatures. Convert to <mensur> within <layer> instead -->
    <xsl:template match="m:scoreDef/@meter.sym | m:scoreDef/@meter.count | m:scoreDef/@meter.unit"/>
    
    <xsl:template match="m:scoreDef" mode="scoredef_to_metersig">
        <xsl:choose>
            <xsl:when test="@meter.sym">
                <meterSig xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="sym">
                        <xsl:value-of select="@meter.sym"/>
                    </xsl:attribute>
                </meterSig>
            </xsl:when>
            <xsl:when test="@meter.count and @meter.unit">
                <meterSig xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="count">
                        <xsl:value-of select="@meter.count"/>
                    </xsl:attribute>
                    <xsl:attribute name="unit">
                        <xsl:value-of select="@meter.unit"/>
                    </xsl:attribute>
                </meterSig>
            </xsl:when>
            <xsl:when test="@meter.count">
                <mensur xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="num">
                        <xsl:value-of select="@meter.count"/>
                    </xsl:attribute>
                    <xsl:copy-of select="@xml:id"/>
                </mensur>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="m:layer">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- first measure: get the meter from initial scoreDef and convert it to meterSig/mensur elements -->
            <xsl:apply-templates select="ancestor::m:measure[not(preceding-sibling::m:measure)]/ancestor::m:section/preceding-sibling::m:scoreDef[1][@meter.sym or @meter.count]" mode="scoredef_to_metersig"/>
            <!-- later measures: see if there is a scoreDef element immediately before this measure -->
            <xsl:apply-templates select="ancestor::m:measure/preceding-sibling::*[1][name()='scoreDef' and (@meter.sym or @meter.count)]" mode="scoredef_to_metersig"/>
            <xsl:apply-templates select="*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Add a leading <pb> to make Verovio render encoded system breaks -->
    <xsl:template match="m:section">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(m:measure[1]/preceding-sibling::m:pb)">
                <pb xmlns="http://www.music-encoding.org/ns/mei"/>
            </xsl:if>
            <xsl:apply-templates select="*"/>
        </xsl:copy>
    </xsl:template>  
    
    
    <!-- Pad lyrics with spaces to compensate for Verovio's too narrow spacing -->
    <xsl:template match="m:syl[//text()]">
        <!-- Determine lyric line number (in case there is than one) -->
        <xsl:variable name="line" select="count(ancestor::m:verse/preceding-sibling::m:verse) + 1"/>
        <xsl:variable name="next_syl" select="ancestor::m:note/following-sibling::m:note[1]/m:verse[$line]/m:syl"/> 
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- Pad inner syllable with an extra space before text -->
            <!--<xsl:if test="@wordpos[.='m' or .='t']"><xsl:text> </xsl:text></xsl:if>-->
            <xsl:apply-templates select="node()"/>
            <!-- Pad before hyphen -->
            <!--<xsl:if test="$next_syl/@wordpos[.='m' or .='t']"><xsl:text> </xsl:text></xsl:if>-->
            <!-- Alternatives: -->
            <!-- If syllables are long, pad word beginnings and inner syllables with an extra space  -->
            <!--<xsl:if test="string-length(.//text()[1]) &gt; 2 or ($next_syl/@wordpos[.='m' or .='t'] and string-length(concat(.//text()[1],$next_syl[1]//text()[1])) &gt; 5)"><xsl:text> </xsl:text></xsl:if>-->
            <!-- Pad all syllables with an extra space -->
            <!--<xsl:text> </xsl:text>-->
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="m:bracketSpan">
        <xsl:copy>
            <xsl:attribute name="label">
                <xsl:choose>
                    <xsl:when test="@func = 'ligature'">Ligatur</xsl:when>
                    <xsl:when test="@func = 'coloration'">Kolorering</xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <!-- this should be changed in data instead -->
            <xsl:apply-templates select="@*[not(local-name()='lwidth')]"/>
        </xsl:copy>
    </xsl:template>
   
    <!-- Set MIDI playback tempo -->
    <xsl:template match="m:scoreDef">
        <xsl:variable name="noteValues">
            <xsl:for-each select="//m:note[@dur and not(@dur = following::m:note/@dur)]">
                <!-- For each note value, calculate the total "weight" of the notes (that is, total number / note value) -->
                <xsl:variable name="dur" select="@dur"/>
                <xsl:variable name="val">
                    <xsl:choose>
                        <xsl:when test="contains($dur,'brev')">0.5</xsl:when>
                        <xsl:when test="contains($dur,'long')">0.25</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$dur"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="count" select="count(//m:note[@dur = $dur])"/>
                <value weight="{count(//m:note[@dur = $dur]) div $val}"/>
            </xsl:for-each>
            <!-- Neumes are counted as semibreves (duration = 1) -->
            <value weight="{count(//m:nc)}"/>
        </xsl:variable>
        <xsl:variable name="tempo" select="ceiling((4 * $midi_base_tempo * sum($noteValues//@weight)) div count(//(m:note | m:nc)))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="midi.bpm">
                <xsl:value-of select="$tempo"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    

    <!-- HANDLING EDITORIAL MARKUP -->
    
    <xsl:template match="m:staff[ancestor::m:measure]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <!-- Add editorial comments after <staff>; -->
        <!-- process them in reverse order and from inside out to get the right stacking in Verovio -->
        <xsl:for-each select=".//m:annot"><!-- comments inside staff -->
            <!-- reverse order to stack references in correct order in Verovio -->
            <xsl:sort select="position()" order="descending" data-type="number"/>
            <xsl:apply-templates select="." mode="add_comment"/>
        </xsl:for-each>
        <xsl:apply-templates select="../(m:annot | *[contains($editorials, name(.))]/m:annot)" mode="add_comment"/><!-- comments in measure -->
        <xsl:apply-templates select="ancestor::m:measure[not(preceding-sibling::m:staff or preceding-sibling::m:measure) or name(preceding-sibling::*[1])='sb' or name(preceding-sibling::*[1])='pb']/             ../(m:annot | *[contains($editorials, name(.))]/m:annot)" mode="add_comment"/><!-- comments in section; to appear at the beginning of each system -->
        <xsl:apply-templates select="ancestor::m:measure[not(preceding-sibling::m:staff or preceding-sibling::m:measure)]/ancestor::m:score/             (m:annot | *[contains($editorials, name(.))]/m:annot)" mode="add_comment"/><!-- comments in score; show only in first measure -->
    </xsl:template>
    
    <xsl:template match="m:add | m:corr | m:damage | m:del |  m:gap | m:orig | m:reg | m:sic | m:supplied | m:unclear">
        <!-- skip any editorial markup; any comments inside will go into <measure> -->
        <xsl:apply-templates select="*[not(name()='annot')] | text()"/>
    </xsl:template>
    
    <xsl:template match="m:music//m:annot">
        <!-- annotations are moved to <dir> markers -->
    </xsl:template>
    
    <xsl:template match="m:music//m:annot" mode="add_comment">
        <xsl:variable name="annot" select="."/>
        <!-- Get the annotation's number -->
        <xsl:variable name="no" select="count(preceding::m:annot[ancestor::m:music]) + 1"/>
        <xsl:variable name="context" as="node()">
            <xsl:choose>
                <xsl:when test="not(../*[name()!='annot'])">
                    <!-- annot has no sibling elements - make the containing editorial markup the point of departure instead -->
                    <xsl:value-of select="name(..)"/>
                </xsl:when>
                <xsl:otherwise>annot</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Change context node if necessary -->
        <xsl:for-each select="ancestor-or-self::*[name()=$context]">
            <!-- Place a marker -->
            <dir xmlns="http://www.music-encoding.org/ns/mei" place="above" type="comment textcriticalnote annotation-marker"><!-- class was: comment notelink -->
                <xsl:if test="descendant-or-self::m:annot/@xml:id">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="concat(descendant-or-self::m:annot/@xml:id,'_dir')"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:choose>
                    <!-- comments at the end of the measure -->
                    <xsl:when test="ancestor-or-self::*[parent::m:measure][not(name()='staff' or following-sibling::m:staff)]">
                        <xsl:attribute name="tstamp">
                            <xsl:choose>
                                <xsl:when test="ancestor-or-self::m:staff">
                                    <xsl:value-of select="dsl:measure_length(ancestor::m:staff)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="dsl:measure_length(ancestor::m:measure/m:staff[1])"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </xsl:when>
                    <!-- comments at the end of a layer are also placed at the end of the measure (for neume notation) -->
                    <xsl:when test="parent::m:layer and not(following-sibling::*[name()!='annot'])">
                        <xsl:attribute name="tstamp">
                            <xsl:value-of select="dsl:measure_length(ancestor::m:staff)"/>
                        </xsl:attribute>
                    </xsl:when>
                    <!-- other section and measure comments are placed at timestamp=0 -->
                    <xsl:when test="parent::m:section or parent::m:measure or parent::m:score or parent::m:staff or following-sibling::m:layer">
                            <xsl:attribute name="tstamp">0</xsl:attribute>
                    </xsl:when>
                    <!-- all others are attached to the first non-annotation following sibling element (or its descendants) having an xml:id -->
                    <xsl:otherwise>
                        <xsl:attribute name="startid">
                            <xsl:value-of select="concat('#', (following-sibling::*/descendant-or-self::*[not(name()='annot' or name()='syllable'                                  or name()='verse' or name()='syl' or name()='neume') and @xml:id])[1]/@xml:id)"/>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="concat('[',$no,']')"/>
                <!-- The actual comment is left out here; an HTML version is placed elsewhere when loading the page -->
            </dir>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="dsl:editorial_context">
        <!-- Return the name of the node containing the editorial markup -->
        <xsl:param name="node" as="node()"/>
        <xsl:value-of select="name($node/ancestor::*[not(contains('add corr damage del gap orig reg sic supplied unclear', name()))][1])"/>
    </xsl:function>
    
    
    <!-- HANDLING NEUMES -->
    <!-- Neumes are converted into CWN for rendering -->
    <xsl:template match="processing-instruction()" priority="2"/>
    
    <!-- Wrap <staff> in <measure> for Verovio -->
    <xsl:template match="m:staff[not(ancestor::m:measure)]">
        <measure xmlns="http://www.music-encoding.org/ns/mei">
            <!-- Add bar line if needed -->
            <xsl:attribute name="right">
                <xsl:choose>
                    <xsl:when test="not(m:layer/m:barLine)">invis</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="m:layer/m:barLine/@form"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- Copy most of the staff elements here -->
            <xsl:copy>
                <xsl:apply-templates select="@* | node()[name()!='annot']"/>
            </xsl:copy>
            <!-- Add slurs -->
            <xsl:apply-templates select="*//m:neume[count(.//m:nc)&gt;1]" mode="add_slur"/>
            <!-- Move fermata and dir elements out of <staff> and <layer> and add them to the <measure> -->
            <xsl:copy-of select=".//m:dir"/>
            <xsl:copy-of select=".//m:fermata"/>
            <!-- Editorial comments -->
            <xsl:for-each select=".//m:annot"><!-- comments inside <staff> -->
                <!-- Process in reverse order and from inside out to get the right stacking in Verovio -->
                <xsl:sort select="position()" order="descending" data-type="number"/>
                <xsl:apply-templates select="." mode="add_comment"/>
            </xsl:for-each>
            <!-- Comments in <section>; show at the beginning of every system -->
            <xsl:apply-templates select=".[not(preceding-sibling::m:staff) or name(preceding-sibling::*[1])='sb' or name(preceding-sibling::*[1])='pb']/ancestor::m:section/(m:annot | *[contains($editorials, name(.))]/m:annot)" mode="add_comment"/>
            <xsl:if test="not(preceding-sibling::m:staff)">
                <!-- Comments in <score>; show only in first measure -->
                <xsl:apply-templates select="ancestor::m:score/(m:annot | *[contains($editorials, name(.))]/m:annot)" mode="add_comment"/>
            </xsl:if>
        </measure>
    </xsl:template>
    
    <!-- <barLine> elements are turned into measure attributes; delete element -->
    <xsl:template match="m:barLine"/>
    
    <!-- Fermatas and directives move out of staff/layer -->
    <xsl:template match="m:fermata[not(ancestor::m:measure)] | m:dir[not(ancestor::m:measure)]"/>
    
    <!-- Render ligatures as slurs -->
    <xsl:template match="m:neume" mode="add_slur">
        <slur xmlns="http://www.music-encoding.org/ns/mei" layer="1" staff="1">
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="concat(@xml:id,'_slur')"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test=".//m:nc">
                <xsl:attribute name="startid">#<xsl:value-of select="./descendant::m:nc[1]/@xml:id"/>
                </xsl:attribute>
                <xsl:attribute name="endid">#<xsl:value-of select="./descendant::m:nc[position()=last()]/@xml:id"/>
                </xsl:attribute>
            </xsl:if>
        </slur>
    </xsl:template>
    
    <!-- Turn syllable/uneume/note structures into note/verse/syl -->
    <xsl:template match="m:syllable">
        <xsl:apply-templates select="*[not(local-name()='syl' or local-name()='verse')]"/>
    </xsl:template>
    
    <!-- Wrap <syl> in <verse> if necessary -->
    <xsl:template match="m:syl[not(parent::m:verse)]">
        <verse xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        </verse>
    </xsl:template>
    
    <xsl:template match="m:neume">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="m:nc">
        <note xmlns="http://www.music-encoding.org/ns/mei" type="neume">
            <xsl:apply-templates select="@*[not(local-name()='label')]"/>
            <xsl:variable name="dur" select="substring-after(@label,'dur')"/>
            <xsl:attribute name="dur">
                <xsl:choose>
                    <xsl:when test="$dur = '8'">4</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$dur"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="$dur='4'">
                <xsl:attribute name="stem.dir">down</xsl:attribute>
                <xsl:attribute name="stem.len">0</xsl:attribute>
                <xsl:attribute name="head.shape">square</xsl:attribute>
                <xsl:attribute name="head.fill">solid</xsl:attribute>
                <!--<xsl:attribute name="colored">true</xsl:attribute>-->
            </xsl:if>
            <xsl:if test="$dur='long'">
                <xsl:attribute name="colored">true</xsl:attribute>
                <!--<xsl:attribute name="color">#800</xsl:attribute>-->
            </xsl:if>
            <xsl:if test="@xml:id=ancestor::m:syllable/descendant::m:neume[1]/descendant::m:nc[1]/@xml:id">
                <xsl:apply-templates select="ancestor::m:syllable/m:verse | ancestor::m:syllable/m:syl"/>
            </xsl:if>
        </note>
    </xsl:template>
    
    <!-- Calculate measure length -->
    <xsl:function name="dsl:measure_length">
        <xsl:param name="staff" as="node()?"/>
        <xsl:choose>
            <xsl:when test="$staff/m:layer[1]//@dur.ppq">
                <xsl:value-of select="(sum($staff/m:layer[1]//@dur.ppq) div 256) + 1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="count($staff/m:layer//m:nc[@label='dur4' or @label='dur8']) + count($staff/m:layer//m:nc[@label='durlong'])*16 + 1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="@*|*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
</xsl:stylesheet>