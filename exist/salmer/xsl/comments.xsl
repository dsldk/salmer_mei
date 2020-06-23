<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xl="http://www.w3.org/1999/xlink" 
    xmlns:h="http://www.w3.org/1999/xhtml" 
    xmlns:m="http://www.music-encoding.org/ns/mei" 
    version="2.0" 
    exclude-result-prefixes="m h xl xsl">
    
    
    <!-- Extract MEI annotations and transform them to HTML -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2019 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="/">
        <mei xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@* | .//m:annot"/>
        </mei>
    </xsl:template>
    
    <!-- HANDLING TEXT INSIDE ANNOTATIONS -->
    <!-- Convert annotation contents to HTML -->    
    <xsl:template match="m:annot">
            <!-- wrap content in HTML <span> element -->
            <span xmlns="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/>_content</xsl:attribute>
                <xsl:apply-templates select="node()"/>
                <!-- create a hidden dummy input element to absorb the focus -->
                <input type="hidden" autofocus="autofocus" />
            </span>
    </xsl:template>
<!--    
    <xsl:template match="m:lb" priority="1">
        <br xmlns="http://www.w3.org/1999/xhtml"/>
    </xsl:template>

    <xsl:template match="m:ref" priority="1">
        <a xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="href"><xsl:value-of select="@target"/></xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="@label"/></xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </a>
    </xsl:template>-->
    
    <!-- Formatted text and links -->
    <xsl:template match="m:lb">
        <br xmlns="http://www.w3.org/1999/xhtml"/>
    </xsl:template>
    <xsl:template match="m:p[normalize-space(.)]">
        <p xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="m:p[not(child::text()) and not(child::node())]">
        <!-- ignore -->
    </xsl:template> 
    <xsl:template match="m:rend[@fontweight = 'bold'][normalize-space(.)]">
        <b xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></b>
    </xsl:template>
    <xsl:template match="m:rend[@fontstyle = 'italic' or @rend = 'italic'][normalize-space(.)]">
        <i xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></i>
    </xsl:template>
    <xsl:template match="m:rend[@rend = 'underline'][normalize-space(.)]">
        <u xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></u>
    </xsl:template>
    <xsl:template match="m:rend[@rend = 'underline(2)'][normalize-space(.)]">
        <span xmlns="http://www.w3.org/1999/xhtml" style="border-bottom: 3px double;"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="m:rend[@rend = 'line-through'][normalize-space(.)]">
        <span xmlns="http://www.w3.org/1999/xhtml" style="text-decoration: line-through;"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="m:rend[@rend = 'sub'][normalize-space(.)]">
        <sub xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></sub>
    </xsl:template>
    <xsl:template match="m:rend[@rend = 'sup'][normalize-space(.)]">
        <sup xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates/></sup>
    </xsl:template>
    <xsl:template match="m:rend[@fontfam or @fontsize or @color][normalize-space(.)]">
        <xsl:variable name="atts">
            <xsl:if test="@fontfam">
                <xsl:value-of select="concat('font-family:',@fontfam,';')"/>
            </xsl:if>
            <xsl:if test="@fontsize">
                <xsl:value-of select="concat('font-size:',@fontsize,';')"/>
            </xsl:if>
            <xsl:if test="@color">
                <xsl:value-of select="concat('color:',@color,';')"/>
            </xsl:if>
        </xsl:variable>
        <xsl:element name="span" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="style">
                <xsl:value-of select="$atts"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="m:ref[@target][normalize-space(.)]">
        <xsl:element name="a" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="href">
                <xsl:value-of select="@target"/>
            </xsl:attribute>
            <xsl:attribute name="target">
                <xsl:choose>
                    <xsl:when test="@xl:show='new'">_blank</xsl:when>
                    <xsl:when test="@xl:show='replace'">_self</xsl:when>
                    <xsl:otherwise><xsl:value-of select="@xl:show"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="@label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="m:rend[@halign][normalize-space(.)]">
        <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="style">text-align:<xsl:value-of select="@halign"/>;</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="m:list">
        <xsl:choose>
            <xsl:when test="@form = 'simple'">
                <ul xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="m:li">
                        <li><xsl:apply-templates/></li>
                    </xsl:for-each>
                </ul>
            </xsl:when>
            <xsl:when test="@form = 'ordered'">
                <ol xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="m:li">
                        <li><xsl:apply-templates/></li>
                    </xsl:for-each>
                </ol>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="m:fig[m:graphic[@target!='']]">
        <xsl:element name="img" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="src">
                <xsl:value-of select="m:graphic/@target"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    <!-- END TEXT HANDLING -->
    
    <!-- TO DO: Add templates for converting <rend> to HTML -->
    
    <!-- Keep attributes -->
    <xsl:template match="@*">
        <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    
    <!-- Keep anything inside annotation -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Skip any other elements -->
    <xsl:template match="*[.//m:annot]">
        <xsl:apply-templates select="*"/>
    </xsl:template>    
    
</xsl:stylesheet>