<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xsl:template match="tei:note[@place='left']|tei:note[@place='right']">
        <span class="marginal-note">
            <!--<span class="marginal-note-mark">$</span>
            <xsl:text> </xsl:text>-->
            <span class="marginal-note-content">
                <xsl:apply-templates/>
            </span>
        </span>
    </xsl:template>
    <xsl:template match="tei:note[@place='bottom']">
        <!--<xsl:variable name="note-identifier">-->
        <!--<xsl:text>Note</xsl:text>-->
        <!-- <xsl:number count="tei:note" level="any" from="tei:text" format="1"/>-->
        <!--</xsl:variable>-->
        <!--<span class="realnote" id="notelink{$note-identifier}" onclick="toggle({$note-identifier});">-->
        <span class="realnote">
            <sup>*
                <!--<xsl:value-of select="$note-identifier"/>--><!--[<xsl:call-template name="noteN"/>]-->
            </sup>
        </span>
        <!--<div id="{$note-identifier}" class="authorNote">-->
        <div class="authorNote">
            <sup>*) </sup>
            <xsl:apply-templates/>
            <xsl:apply-templates select="@xml:id"/>
        </div>
    </xsl:template>
    <xsl:template name="noteN">
        <xsl:number from="tei:text" level="any" format="1"/>
    </xsl:template>
</xsl:stylesheet>