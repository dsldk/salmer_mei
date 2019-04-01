<xsl:stylesheet version="2.0" 
    xmlns="http://www.music-encoding.org/ns/mei" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:m="http://www.music-encoding.org/ns/mei"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes="m exsl">
    
    <!-- Common templates -->
    <xsl:import href="rense_sib-mei.xsl"/>
    
    <xsl:output indent="yes"/>
    

    <!-- Neume-specific templates -->

    <!-- Associate MEI Neumes XML schema -->
    <xsl:template match="/">
        <xsl:text>
</xsl:text>
        <xsl:processing-instruction name="xml-model">href="https://music-encoding.org/schema/4.0.0/mei-all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
        <xsl:processing-instruction name="xml-model">href="https://music-encoding.org/schema/4.0.0/mei-all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:text>
</xsl:text>
        <!-- 1st run: make @xml:ids unique by adding the file name -->
        <xsl:variable name="unique_ids">
            <xsl:apply-templates mode="new_ids"/>
        </xsl:variable>
        <xsl:variable name="data" select="exsl:node-set($unique_ids)"/>
        <xsl:copy>
            <xsl:apply-templates select="$data/*"/>
        </xsl:copy>
    </xsl:template>

    <!-- Remove <measure> container element -->
    <xsl:template match="m:measure" priority="1">
            <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Delete slur elements (will be converted to <uneume> groups of notes) -->
    <xsl:template match="m:slur"/>
    
    <!-- Move <fermata> into <staff> (includes fermatas becoming <dir> elements)-->
    <xsl:template match="m:fermata"/>
    
    <!-- Add a <barLine> to <layer> if needed -->
    <xsl:template match="m:layer">
        <xsl:copy>
            <xsl:apply-templates select="@* | *"/>
            <xsl:if test="not(ancestor::m:measure[@right='invis'])">
                <xsl:variable name="form">
                    <xsl:choose>
                        <xsl:when test="ancestor::m:measure/@right">
                            <xsl:value-of select="ancestor::m:measure/@right"/>
                        </xsl:when>
                        <xsl:otherwise>single</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <barLine>
                    <xsl:attribute name="form"><xsl:value-of select="$form"/></xsl:attribute>
                </barLine>
            </xsl:if>
        </xsl:copy>        
    </xsl:template>
    
    <!-- Turn note/verse/syl structures into syllable/neume/nc or neume/nc -->
    <xsl:template match="m:note">
        <xsl:choose>
            <xsl:when test="m:verse/m:syl/text()">
                <syllable>
                    <xsl:attribute name="xml:id"><xsl:value-of select="m:verse[m:syl/text()][1]/@xml:id"/>_syl</xsl:attribute>
                    <xsl:apply-templates select="m:verse[m:syl/text()]"/>
                    <xsl:variable name="syllables_left" select="count(following-sibling::m:note[m:verse])"/>
                    <xsl:apply-templates select=". | following-sibling::m:note[not(m:verse) and count(following-sibling::m:note[m:verse])=$syllables_left]" mode="makeNeumes"/>          
                </syllable>        
            </xsl:when>
            <xsl:when test="not(ancestor::m:layer//m:verse/m:syl/text())">
                <!-- A layer without vocal text; make each note a neume -->
                <xsl:apply-templates select="." mode="makeNeumes"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Skip; the note should be taken care of already under the <syllable> above -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="m:note" mode="makeNeumes">
        <!-- Group notes into neumes according to the 'ligature slurs' -->
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:variable name="under_slur">
            <xsl:call-template name="under_slur">
                <xsl:with-param name="id" select="$id"/> 
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$under_slur='no' or $under_slur='start'">
            <neume>
                <xsl:attribute name="xml:id"><xsl:value-of select="concat('neume_',generate-id())"/></xsl:attribute>
                <xsl:apply-templates select="." mode="addToNeume"/>
                <!-- Add remaining notes under the same slur (ligature) -->
                <xsl:if test="$under_slur='start'">
                    <xsl:variable name="slur" select="$slurs/m:slur[translate(@startid,'#','')=$id]"/>
                    <xsl:apply-templates select="following-sibling::m:note[@xml:id=translate($slur/@endid,'#','') or following-sibling::m:note[@xml:id=translate($slur/@endid,'#','')]]" mode="addToNeume"/>
                </xsl:if>
            </neume>                         
        </xsl:if>
    </xsl:template>

    <xsl:template match="m:note" mode="addToNeume">
        <nc>
            <xsl:apply-templates select="@*[not(local-name()='dur' or local-name()='dur.ges')]"/>
            <xsl:apply-templates select="m:accid/@accid | m:accid/@accid.ges"/>
            <!-- Store duration as @label in case it will be needed at rendering time -->
            <xsl:attribute name="label">dur<xsl:value-of select="@dur"/></xsl:attribute>
        </nc>
    </xsl:template>
    
    <xsl:template name="under_slur">
        <!-- Determine whether a note is placed at the start, middle, or end of a slur - or not under a slur at all -->
        <xsl:param name="id"/>
        <xsl:variable name="doc" select="/"/>
        <xsl:choose>
            <xsl:when test="$slurs/m:slur[translate(@startid,'#','')=$doc//m:note[@xml:id=$id]/preceding-sibling::m:note/@xml:id and translate(@endid,'#','')=$doc//m:note[@xml:id=$id]/following-sibling::m:note/@xml:id]">middle</xsl:when>
            <xsl:when test="$slurs/m:slur[@startid=concat('#',$id)]">start</xsl:when>
            <xsl:when test="$slurs/m:slur[@endid=concat('#',$id)]">end</xsl:when>
            <xsl:otherwise>no</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>