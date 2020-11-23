<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" version="1.0" exclude-result-prefixes="m xsl">
    
    <!-- Prepare MEI for MIDI playback -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <xsl:param name="repeat" select="'true'"/>
    <xsl:param name="online" select="'no'"/>
    
    <!-- Adjustments for the online MIDI player -->
    
    <!-- Add a rest before the first note to make the first note play (apparently a bug in MIDI player) -->
    <xsl:template match="m:note[not(preceding::m:note)]">
        <xsl:if test="$online='yes'">
            <rest xmlns="http://www.music-encoding.org/ns/mei" dur="4"/>
        </xsl:if>
        <xsl:apply-templates select="." mode="check_if_neume"/>
    </xsl:template>
    
    <!-- Add a rest at the end too to prevent the MIDI player from stopping too early -->
    <xsl:template match="m:note[not(following::m:note)]">
        <xsl:apply-templates select="." mode="check_if_neume"/>
        <xsl:if test="$online='yes'">
            <rest xmlns="http://www.music-encoding.org/ns/mei" dur="4"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="m:note">
        <xsl:apply-templates select="." mode="check_if_neume"/>
    </xsl:template>
    
    <xsl:template match="m:note" mode="check_if_neume">
        <!-- When playing neumes, try to phrase the music just a little by adding a rest between phrases -->
        <xsl:if test="@type='neume' and $online='yes'">
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::m:note) and ancestor::m:measure/preceding-sibling::m:measure[1]/@right!='invis'">
                    <!-- First note after a vertical line; add rest -->
                    <rest xmlns="http://www.music-encoding.org/ns/mei" dur="breve"/>
                </xsl:when>
                <xsl:when test="m:verse/m:syl/text() and preceding::m:note[m:verse/m:syl/text()][1]//m:syl[substring(.,string-length(.),1)=',' or substring(.,string-length(.),1)='.']">
                    <!-- First note after a comma or stop; add short rest -->
                    <rest xmlns="http://www.music-encoding.org/ns/mei" dur="1"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <note xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:copy-of select="@*[not(substring(name(),1,3)='dur')]"/>
            <xsl:choose>
                <!-- Play neumes (stemless quarters) at 1/4 tempo to match tempo in mixed notation-->
                <xsl:when test="@type='neume'">
                    <xsl:choose>
                        <!-- @dur.ges has highest priority -->
                        <xsl:when test="number(@dur.ges) &gt;= 4">
                            <xsl:attribute name="dur"><xsl:value-of select="number(@dur.ges) div 4"/></xsl:attribute>
                        </xsl:when>
                        <!-- values longer than 4: make it a breve -->
                        <xsl:when test="number(@dur.ges) &gt; 0">
                            <xsl:attribute name="dur">breve</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="number(@dur) &gt;= 4">
                            <xsl:attribute name="dur"><xsl:value-of select="number(@dur) div 4"/></xsl:attribute>
                        </xsl:when>
                        <xsl:when test="number(@dur) &gt; 0">
                            <xsl:attribute name="dur">breve</xsl:attribute>
                        </xsl:when>
                        <!-- breve and longa keep their encoded value -->
                        <xsl:when test="@dur.ges">
                            <xsl:attribute name="dur"><xsl:value-of select="@dur.ges"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="@dur"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="@dur"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="node()"/>
        </note>
    </xsl:template>
    
    <!-- Play repeat -->
    <xsl:template match="*[@right='rptend']">
        <xsl:copy-of select="."/>
        <xsl:if test="$repeat='true'">
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::m:measure[@left='rptstart'] or @left='rptstart')">
                    <!-- No start repetition sign; repeat from beginning -->
                    <xsl:copy-of select="preceding-sibling::* | ."/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Between two reptition signs -->
                    <xsl:variable name="start-repeat" select="(preceding-sibling::m:measure | .)[@left='rptstart'][1]/@xml:id"/>
                    <xsl:copy-of select="preceding-sibling::*[not(following-sibling::m:measure[@xml:id=$start-repeat])] | ."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- MIDI playback tempo already set in show.xsl -->
    <!-- <xsl:template match="m:scoreDef">
        <xsl:variable name="noteValues">
        <xsl:for-each select="//m:note[not(@dur = following::m:note/@dur) and not(@type='neume')]">
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
        <xsl:variable name="count" select="count(//m:note[@dur = $dur and not(@type='neume')])"/>
        <value weight="{count(//m:note[@dur = $dur and not(@type='neume')]) div $val}"/>
        </xsl:for-each>
        <value weight="{count(//m:note[@type='neume'])}"/>
        </xsl:variable>
        <xsl:variable name="tempo" select="ceiling((300 * sum($noteValues//@weight)) div count(//m:note))"/>
        <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <xsl:attribute name="midi.bpm">
        <xsl:value-of select="$tempo"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()"/>
        </xsl:copy>
        </xsl:template>-->
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>