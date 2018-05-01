<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.music-encoding.org/ns/mei"
    xmlns:exsl="http://exslt.org/common"
    version="1.0" exclude-result-prefixes="m exsl xsl">

    <!-- Prepare MEI for viewing with Verovio -->
  
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:param name="mdiv" select="''"/>
    
    <xsl:template match="m:body">
        <body xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*"/>
            <!-- Choose a specific <mdiv> element?  -->
            <xsl:choose>
                <xsl:when test="$mdiv!=''">
                    <xsl:apply-templates select="m:mdiv[@xml:id=$mdiv]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </xsl:template>
    
    
    <xsl:template match="m:meterSigGrp[m:meterSig/@sym and m:meterSig/@count]">
        <!-- Verovio doesn't display both number and symbol yet (<meterSigGrp> is not supported, and an appropriate @meter.form value in <scoreDef> not yet available in MEI 3.0.0) -->
        <xsl:for-each select="m:meterSig[@sym or (@count and @unit)]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
        <xsl:for-each select="m:meterSig[@count and not(@unit)]">
            <mensur xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="num"><xsl:value-of select="@count"/></xsl:attribute>
                <xsl:copy-of select="@xml:id"/>
            </mensur>
        </xsl:for-each>
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
                        <tuplet>
                            <xsl:attribute name="xml:id"><xsl:value-of select="$bracket/@xml:id"/></xsl:attribute>
                            <xsl:attribute name="num">2</xsl:attribute>
                            <xsl:attribute name="numbase">2</xsl:attribute>
                            <xsl:attribute name="bracket.visible">true</xsl:attribute>
                            <xsl:attribute name="num.visible">false</xsl:attribute>
                            <xsl:attribute name="label">ligature</xsl:attribute>
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
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>