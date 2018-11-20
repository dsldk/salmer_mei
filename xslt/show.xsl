<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" version="2.0" exclude-result-prefixes="m xsl">
    
    
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
    
    
    <!-- Pad lyrics with spaces to compensate for Verovio's too narrow spacing -->
    <xsl:template match="m:syl[text()]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:text> </xsl:text>
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
   
    
    <!-- Delete the following template when Verovio supports <bracketSpan> (MEI 4.0.0+) -->
    <xsl:template match="m:layer[m:bracketSpan]">
        <!-- Turn <bracketSpan> elements into tuplets for Verovio rendering -->
        <layer xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*"/>
            <xsl:variable name="layer" select="."/>
            <xsl:for-each select="*[name()!='bracketSpan']">
                <xsl:variable name="id" select="@xml:id"/>
                <xsl:choose>
                    <xsl:when test="../m:bracketSpan[translate(@startid,'#','')=$id]">
                        <xsl:variable name="bracket" select="../m:bracketSpan[translate(@startid,'#','')=$id]"/>
                        <!-- a variable containing the nodes to be wrapped in a tuplet -->
                        <xsl:variable name="elements" select=". | following-sibling::*[not(preceding-sibling::*[@xml:id=translate($bracket/@endid,'#','')])]"/>                        
                        <!-- start tuplet -->
                        <tuplet num="2" numbase="2" bracket.visible="true" bracket.place="above" num.visible="false" label="Ligatur" type="cursorHelp">
                            <xsl:attribute name="xml:id">
                                <xsl:value-of select="$bracket/@xml:id"/>
                            </xsl:attribute>
                            <xsl:copy-of select="$elements"/>
                        </tuplet>
                    </xsl:when>
                    <xsl:when test="../m:bracketSpan[translate(@startid,'#','')=$layer/*[@xml:id=$id]/preceding-sibling::*/@xml:id and translate(@endid,'#','')=$layer/*[@xml:id=$id]/following-sibling::*/@xml:id]">
                        <!-- skip elements inside a tuplet -->
                    </xsl:when>
                    <xsl:when test="../m:bracketSpan[translate(@endid,'#','')=$id]">
                        <!-- skip last element in tuplet -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </layer>
    </xsl:template>
    
    <xsl:template match="m:staff[ancestor::m:measure]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <!-- Add editorial comments -->
        <xsl:apply-templates select="m:layer/m:add | m:layer/m:corr | m:layer/m:damage | m:layer/m:del |  m:layer/m:gap | m:layer/m:orig | m:layer/m:sic | m:layer/m:unclear" mode="add_comment"/>
    </xsl:template>
    
    
    
    <!-- HANDLING EDITORIAL MARKUP -->
    <xsl:template match="m:add | m:corr | m:damage | m:del |  m:gap | m:orig | m:sic | m:unclear">
        <!-- skip any editorial markup here -->
        <xsl:apply-templates select="*[not(name()='annot')] | text()"/>
    </xsl:template>
    
    <xsl:template match="m:add | m:corr | m:damage | m:del |  m:gap | m:orig | m:sic | m:unclear" mode="add_comment">
        <!-- Place a marker -->
        <dir xmlns="http://www.music-encoding.org/ns/mei" place="above" type="comment">
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:if>
            <!-- attach it to the first non-annotation child element having an xml:id -->
            <xsl:attribute name="startid">
                <xsl:value-of select="concat('#',*[not(name()='annot') and @xml:id][1]/@xml:id)"/>
            </xsl:attribute>
            <xsl:text>*</xsl:text>
            <xsl:apply-templates select="m:annot"/>
        </dir>
    </xsl:template>
    
    
    <!-- HANDLING NEUMES -->
    <!-- Neumes are converted into CWN for rendering -->
    <xsl:template match="processing-instruction()" priority="2"/>
    
    <!-- Associate non-neumes MEI XML schema - mostly for debugging -->
    <!--<xsl:template match="/">
        <xsl:text>
        </xsl:text>
        <xsl:processing-instruction name="xml-model">href="http://www.music-encoding.org/schema/3.0.0/mei-all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:text>
        </xsl:text>
        <xsl:processing-instruction name="xml-model">href="http://www.music-encoding.org/schema/3.0.0/mei-all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:text>
        </xsl:text>
        <xsl:copy>
        <xsl:apply-templates/>
        </xsl:copy>
        </xsl:template>-->
    
    <!-- Wrap <staff> in <measure> -->
    <xsl:template match="m:staff[not(ancestor::m:measure)]">
        <measure xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()[not(name()='sb' or name()='pb' or name()='fermata')]"/>
            </xsl:copy>
            <xsl:apply-templates select="*//m:uneume[count(m:note)&gt;1]" mode="add_slur"/>
            <!-- Move fermata and dir elements out of <staff> -->
            <!--<xsl:apply-templates select="m:layer/m:sb[not(@label='editorial')] | m:layer/m:pb[not(@label='editorial')]" mode="breaks_to_dir"/>-->
            <xsl:copy-of select="m:layer/m:dir"/>
            <xsl:copy-of select="m:layer/m:fermata"/>
            <!-- Add editorial comments -->
            <xsl:apply-templates select="m:layer/m:add | m:layer/m:corr | m:layer/m:damage | m:layer/m:del |  m:layer/m:gap | m:layer/m:orig | m:layer/m:sic | m:layer/m:unclear" mode="add_comment"/>
        </measure>
    </xsl:template>
    
    <!-- Fermatas and directives move out of staff/layer -->
    <xsl:template match="m:fermata[not(ancestor::m:measure)] | m:dir[not(ancestor::m:measure)]"/>
    
    <!-- Render ligatures as slurs -->
    <xsl:template match="m:uneume" mode="add_slur">
        <slur xmlns="http://www.music-encoding.org/ns/mei" layer="1" staff="1">
            <xsl:attribute name="startid">#<xsl:value-of select="m:note[1]/@xml:id"/>
            </xsl:attribute>
            <xsl:attribute name="endid">#<xsl:value-of select="m:note[position()=last()]/@xml:id"/>
            </xsl:attribute>
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
    
    <xsl:template match="m:uneume">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="m:note[not(ancestor::m:measure)]">
        <xsl:copy>
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
            <xsl:if test="@xml:id=ancestor::m:syllable//*[m:note][1]/m:note[1]/@xml:id">
                <xsl:apply-templates select="ancestor::m:syllable/m:verse | ancestor::m:syllable/m:syl"/>
                <!--<xsl:element name="verse" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="ancestor::m:syllable/@xml:id"/>
                    <xsl:apply-templates select="ancestor::m:syllable/m:verse | ancestor::m:syllable/m:syl"/>
                </xsl:element>-->
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>