<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:m="http://www.music-encoding.org/ns/mei" version="2.0" exclude-result-prefixes="m h xsl">
    
    
    <!-- Prepare MEI for viewing with Verovio -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="mdiv" select="''"/>
    
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
            <!-- mark the beginning of the MDIV -->
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
        <xsl:for-each select="m:meterSig[@count and not(@unit)]">
            <mensur xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="num">
                    <xsl:value-of select="@count"/>
                </xsl:attribute>
                <xsl:copy-of select="@xml:id"/>
            </mensur>
        </xsl:for-each>
    </xsl:template>
    
    
    <!-- Set MIDI playback tempo -->
    <xsl:template match="m:scoreDef">
        <xsl:variable name="noteValues">
            <xsl:for-each select="//m:note[not(@dur = preceding-sibling::m:note/@dur or @dur = ancestor::m:measure/preceding-sibling::*//m:note/@dur)]">
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
                <value count="{count(//m:note[@dur = $dur])}">
                    <xsl:value-of select="$val"/>
                </value>
            </xsl:for-each>
            <value count="{count(//m:note[not(@dur)])}">4</value>
        </xsl:variable>
        <xsl:variable name="mostFrequentValue" select="$noteValues/*[@count = max($noteValues//@count)][1]/string()"/>
        <xsl:variable name="tempo">
            <xsl:choose>
                <xsl:when test="string(number($mostFrequentValue)) != 'NaN'">
                    <xsl:value-of select="400 div number($mostFrequentValue)"/>
                </xsl:when>
                <xsl:otherwise>100</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- temporary eXist 2.2 solution: 
            <xsl:variable name="mostFrequentValue">
            <xsl:choose>
            <xsl:when test="count(//m:note[not(@dur)]) > count(//m:note[@dur='1'])"
            >120</xsl:when>
            <xsl:when test="count(//m:note[@dur='1']) > count(//m:note[@dur='2'])"
            >480</xsl:when>
            <xsl:when test="count(//m:note[@dur='2']) > count(//m:note[@dur='4'])"
            >240</xsl:when>
            <xsl:otherwise>80</xsl:otherwise>
            </xsl:choose>
            </xsl:variable>
            <xsl:variable name="tempo" select="$mostFrequentValue"/>
            end temporary -->
        <xsl:copy>
            <xsl:attribute name="midi.bpm">
                <xsl:value-of select="$tempo"/>
            </xsl:attribute>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Pad lyrics with spaces to compensate for Verovio's too narrow spacing -->
    <xsl:template match="m:syl[text()]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!--<xsl:text> </xsl:text>-->
            <xsl:if test="not(ancestor::m:note/following-sibling::m:note//m:syl[text()] or parent::m:syllable/following-sibling::m:syllable/m:syl[text()])">
                <!-- Extra space before last syllable -->
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
            <xsl:text> </xsl:text>
            <xsl:if test="count(ancestor::m:note/following-sibling::m:note//m:syl[text()]) = 1">
                <!-- Extra space after penultimate syllable -->
                <xsl:text> </xsl:text>
            </xsl:if>
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

    
    <!-- HANDLING EDITORIAL MARKUP -->
    
    <xsl:template match="m:staff[ancestor::m:measure]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <!-- Add editorial comments -->
        <xsl:apply-templates select=".//m:annot" mode="add_comment"/>
    </xsl:template>
        
    <xsl:template match="m:add | m:corr | m:damage | m:del |  m:gap | m:orig | m:sic | m:unclear | m:supplied">
        <!-- skip any editorial markup here -->
        <xsl:apply-templates select="*[not(name()='annot')] | text()"/>
    </xsl:template>
    
    <xsl:template match="m:annot">
        <!-- annotations are moved to <dir> markers -->
    </xsl:template>
    
    <xsl:template match="m:annot" mode="add_comment">
        <!-- Place a marker -->
        <dir xmlns="http://www.music-encoding.org/ns/mei" place="above" type="comment">
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="concat(@xml:id,'_dir')"/>
                </xsl:attribute>
            </xsl:if>
            <!-- attach it to the first non-annotation following sibling element having an xml:id -->
            <xsl:attribute name="startid">
                <xsl:value-of select="concat('#',following-sibling::*[not(name()='annot') and @xml:id][1]/@xml:id)"/>
            </xsl:attribute>
            
            <!-- Get the annotation's number -->
            <xsl:variable name="annots" select="string-join(/*//m:annot/@xml:id,'¤')"/>
            <xsl:variable name="no" select="count(tokenize(substring-before($annots,concat('¤',@xml:id)),'¤')) + 1"/>
            <xsl:value-of select="concat('[',$no,']')"/>
            <!-- The actual comment is left out here; an HTML version is placed elsewhere when loading the page -->
        </dir>
    </xsl:template>
 
    <!-- HANDLING NEUMES -->
    <!-- Neumes are converted into CWN for rendering -->
    <xsl:template match="processing-instruction()" priority="2"/>
    
    <!-- Wrap <staff> in <measure> -->
    <xsl:template match="m:staff[not(ancestor::m:measure)]">
        <measure xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="right">
                <xsl:choose>
                    <xsl:when test="not(m:layer/m:barLine)">invis</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="m:layer/m:barLine/@form"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:copy>
                <xsl:apply-templates select="@* | node()[not(name()='sb' or name()='pb' or name()='fermata')]"/>
            </xsl:copy>
            <!-- MEI 3.0.0: <xsl:apply-templates select="*//m:uneume[count(m:note)>1]" mode="add_slur"/>-->
            <xsl:apply-templates select="*//m:uneume[count(m:note)&gt;1] | *//m:neume[count(m:nc)&gt;1]" mode="add_slur"/>
            <!-- Move fermata and dir elements out of <staff> and <layer> -->
            <!--<xsl:apply-templates select="m:layer/m:sb[not(@label='editorial')] | m:layer/m:pb[not(@label='editorial')]" mode="breaks_to_dir"/>-->
            <xsl:copy-of select=".//m:dir"/>
            <xsl:copy-of select=".//m:fermata"/>
            <!-- Add editorial comments -->
            <xsl:apply-templates select="m:layer/m:add | m:layer/m:corr | m:layer/m:damage | m:layer/m:del |  m:layer/m:gap | m:layer/m:orig | m:layer/m:sic | m:layer/m:unclear" mode="add_comment"/>
        </measure>
    </xsl:template>
    
    <!-- <barLine> elements are turned into measure attributes -->
    <xsl:template match="m:barLine"/>
    
    <!-- Fermatas and directives move out of staff/layer -->
    <xsl:template match="m:fermata[not(ancestor::m:measure)] | m:dir[not(ancestor::m:measure)]"/>
    
    <!-- Render ligatures as slurs -->
    <xsl:template match="m:uneume | m:neume" mode="add_slur">
        <slur xmlns="http://www.music-encoding.org/ns/mei" layer="1" staff="1">
            <xsl:choose>
                <xsl:when test="m:note">
                    <!-- MEI 3.0.0 -->
                    <xsl:attribute name="startid">#<xsl:value-of select="m:note[1]/@xml:id"/>
                    </xsl:attribute>
                    <xsl:attribute name="endid">#<xsl:value-of select="m:note[position()=last()]/@xml:id"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="m:nc">
                    <!-- MEI 4.0.0 -->
                    <xsl:attribute name="startid">#<xsl:value-of select="m:nc[1]/@xml:id"/>
                    </xsl:attribute>
                    <xsl:attribute name="endid">#<xsl:value-of select="m:nc[position()=last()]/@xml:id"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
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
    
    <!-- MEI 3.0.0: <xsl:template match="m:uneume"> -->
    <!-- MEI 4.0.0: <xsl:template match="m:neume"> -->
    <xsl:template match="m:uneume | m:neume">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- MEI 3.0.0: <xsl:template match="m:note[not(ancestor::m:measure)]"> -->
    <!-- MEI 4.0.0: <xsl:template match="m:nc"> -->
    <xsl:template match="m:nc">
        <note xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*[not(local-name()='label')]"/>
            <xsl:variable name="dur" select="substring-after(@label,'dur')"/>
            <xsl:attribute name="dur">
                <xsl:value-of select="$dur"/>
            </xsl:attribute>
            <xsl:if test="$dur='4'">
                <xsl:attribute name="stem.dir">down</xsl:attribute>
                <xsl:attribute name="stem.len">0</xsl:attribute>
                <xsl:attribute name="head.shape">square</xsl:attribute>
                <!--                <xsl:attribute name="head.fill">solid</xsl:attribute>-->
                <!--                <xsl:attribute name="colored">true</xsl:attribute>-->
            </xsl:if>
            <!-- MEI 3.0.0: <xsl:if test="@xml:id=ancestor::m:syllable//*[m:note][1]/m:note[1]/@xml:id">-->
            <!-- MEI 4.0.0: <xsl:if test="@xml:id=ancestor::m:syllable//m:nc[1]/@xml:id">-->
            <xsl:if test="@xml:id=ancestor::m:syllable/m:neume[1]/m:nc[1]/@xml:id">
                <xsl:apply-templates select="ancestor::m:syllable/m:verse | ancestor::m:syllable/m:syl"/>
            </xsl:if>
        </note>
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>