<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" version="2.0" exclude-result-prefixes="m xsl">
    
    <!-- Reduce note and rest values. Files containing neumes notation (i.e. containing any @stem.len=0) are ignored -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <!-- The reduction factor: 1, 2, 4, ... -->
    <!--<xsl:param name="factor" select="1"/>-->
    <xsl:param name="factor" select="2"/>
    
    <xsl:variable name="durations" as="node()">
        <durations>
            <dur>long</dur>
            <dur>breve</dur>
            <dur>1</dur>
            <dur>2</dur>
            <dur>4</dur>
            <dur>8</dur>
            <dur>16</dur>
            <dur>32</dur>
            <dur>64</dur>
            <dur>128</dur>
            <dur>256</dur>
            <dur>512</dur>
            <dur>1024</dur>
            <dur>2048</dur>
        </durations>
    </xsl:variable>

    <xsl:variable name="divisor">
        <xsl:choose>
            <!-- Check that the reduction is a power of 2 within the range of $durations -->
            <xsl:when test="$durations/dur[.=string($factor)]">
                <xsl:value-of select="$factor"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>        
    
    <xsl:variable name="shift">
        <!-- Calculate how many steps to shift values. Actually a low-tech implementation of logarithm log2($divisor) -->
        <xsl:value-of select="count($durations/dur[.=$divisor]/preceding-sibling::dur) - 2"/>
    </xsl:variable>

    <!-- Adjust MIDI tempo -->
    <xsl:template match="@midi.bpm">
        <xsl:attribute name="midi.bpm">
            <xsl:value-of select=". div $divisor"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- change note and rest durations if not in neume type notation -->
    <xsl:template match="@dur[not((ancestor::m:chord | ancestor::m:note)[@stem.len=0])]">
        <xsl:attribute name="dur">
            <xsl:variable name="thisDur" select="."/>
            <xsl:choose>
                <xsl:when test="$divisor=1">
                    <xsl:value-of select="."/>
                </xsl:when>
                <!-- Longa is reduced to a whole note (or less), not breve -->
                <xsl:when test=".='long' and $divisor=2">1</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$durations/dur[.=$thisDur]/following-sibling::dur[number($shift)]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>    

    <xsl:template match="@dur.ges[not((ancestor::m:chord | ancestor::m:note)[@stem.len=0])]">
        <xsl:attribute name="dur.ges">
            <xsl:variable name="thisDur" select="."/>
            <xsl:variable name="reduced_dur">
                <xsl:value-of select="number(translate(.,'p','')) div $divisor"/>
            </xsl:variable>
            <xsl:value-of select="concat($reduced_dur,'p')"/>            
        </xsl:attribute>
    </xsl:template>
    
    <!-- color and comment mensuration and time signatures -->
    <xsl:template match="m:mensur | m:meterSig">
        <xsl:copy>
            <xsl:attribute name="label">Mensur/taktart korresponderer ikke med nodeværdier i denne visning</xsl:attribute>
            <xsl:attribute name="type">warning</xsl:attribute>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- move timestamped elements accordingly -->
    <xsl:template match="@tstamp[not(ancestor::m:measure//(m:chord | m:note)[@stem.len=0])]">
        <xsl:attribute name="tstamp">
            <xsl:variable name="thisTstamp" select="."/>
            <xsl:choose>
                <xsl:when test="$divisor=1 or not(number(.)=.)">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1 + (.-1) div $divisor"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>