<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:detail>Licensed by Thomas Hansen under the Creative Commons Attribution-Share Alike
                3.0 United States license. You are free to copy, distribute, transmit, and remix
                this work, provided you attribute the work to Thomas Hansen as the original author
                and reference the Society for Danish Language and Literature [http://dsl.dk] for the
                work. If you alter, transform, or build upon this work, you may distribute the
                resulting work only under the same, similar or a compatible license. Any of the
                above conditions can be waived if you get permission from the copyright holder. For
                any reuse or distribution, you must make clear to others the license terms of this
                work. The best way to do this is with a link to the license
                [http://creativecommons.org/licenses/by-sa/3.0/deed.en].</xd:detail>
            <xd:p><xd:b>Created on:</xd:b> Jan 5, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> Thomas Hansen</xd:p>
            <xd:copyright>2010, Society for Danish Language and Literature</xd:copyright>
        </xd:desc>
    </xd:doc>
    <!-- Level 1 head -->
    <xsl:template
        match="tei:front/tei:div/tei:head | tei:body/tei:div/tei:head | tei:back/tei:div/tei:head">
        <xsl:choose>
		<xsl:when test="@type = 'add'">
			<!--<h1 class="metadata">
                    <xsl:if test="@n">
                        <b>
                            <xsl:value-of select="@n"/>&#8194;
                        </b>
                    </xsl:if>
                    <xsl:apply-templates/>
		</h1>-->
	    </xsl:when>
            <xsl:when test="@type = 'original'">
                <h1>
                    <xsl:apply-templates/>
                </h1>
            </xsl:when>
            <xsl:when test="not(@type)">
                <h1>
                    <xsl:apply-templates/>
                </h1>
            </xsl:when>
            <xsl:when test="tei:orig">
                <h1>
                    <xsl:apply-templates/>
                </h1>
            </xsl:when>
	    <!--<xsl:otherwise>
                <h1>
                    <xsl:apply-templates/>
                </h1>
	    </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    <!-- Level 2 head -->
    <xsl:template
        match="tei:front/tei:div/tei:div/tei:head | tei:body/tei:div/tei:div/tei:head | tei:back/tei:div/tei:div/tei:head">
        <xsl:choose>
		<xsl:when test="@type = 'add'">
			<!--<h2 class="metadata">
                    <xsl:if test="@n">
                        <b>
                            <xsl:value-of select="@n"/>&#8194;
                        </b>
                    </xsl:if>
                    <xsl:apply-templates/>
		</h2>-->
	    </xsl:when>
            <xsl:when test="@type = 'original'">
                <h2>
                    <xsl:apply-templates/>
                </h2>
            </xsl:when>
            <xsl:when test="not(@type)">
                <h2>
                    <xsl:apply-templates/>
                </h2>
            </xsl:when>
            <xsl:when test="tei:orig">
                <h2>
                    <xsl:apply-templates/>
                </h2>
            </xsl:when>
	    <!--<xsl:otherwise>
                <h2>
                    <xsl:apply-templates/>
                </h2>
	    </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    <!-- Level 3 head -->
    <xsl:template
        match="tei:front/tei:div/tei:div/tei:div/tei:head | tei:body/tei:div/tei:div/tei:div/tei:head | tei:back/tei:div/tei:div/tei:div/tei:head">
        <xsl:choose>
		<xsl:when test="@type = 'add'">
			<!--<h3 class="metadata">
                    <xsl:apply-templates/>
		</h3>-->
	    </xsl:when>
            <xsl:when test="@type = 'original'">
                <h3>
                    <xsl:apply-templates/>
                </h3>
            </xsl:when>
            <xsl:when test="not(@type)">
                <h3>
                    <xsl:apply-templates/>
                </h3>
            </xsl:when>
            <xsl:when test="tei:orig">
                <h3>
                    <xsl:apply-templates/>
                </h3>
            </xsl:when>
	    <!--<xsl:otherwise>
                <h3>
                    <xsl:apply-templates/>
                </h3>
	    </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    <!-- Level 4 head -->
    <xsl:template
        match="tei:front/tei:div/tei:div/tei:div/tei:div/tei:head | tei:body/tei:div/tei:div/tei:div/tei:div/tei:div/tei:head | tei:back/tei:div/tei:div/tei:div/tei:div/tei:head">
        <xsl:choose>
		<xsl:when test="@type = 'add'">
			<!--<h4 class="metadata">
                    <xsl:apply-templates/>
		</h4>-->
	    </xsl:when>
            <xsl:when test="@type = 'original'">
                <h4>
                    <xsl:apply-templates/>
                </h4>
            </xsl:when>
            <xsl:when test="not(@type)">
                <h4>
                    <xsl:apply-templates/>
                </h4>
            </xsl:when>
            <xsl:when test="tei:orig">
                <h4>
                    <xsl:apply-templates/>
                </h4>
            </xsl:when>
	    <!--<xsl:otherwise>
                <h4>
                    <xsl:apply-templates/>
                </h4>
	    </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    <!-- Level 5 head -->
    <xsl:template
        match="tei:front/tei:div/tei:div/tei:div/tei:div/tei:div/tei:head | tei:body/tei:div/tei:div/tei:div/tei:div/tei:div/tei:div/tei:head | tei:back/tei:div/tei:div/tei:div/tei:div/tei:div/tei:head">
        <xsl:choose>
		<xsl:when test="@type = 'add'">
			<!--<h4 class="metadata">
                    <xsl:apply-templates/>
		</h4>-->
	    </xsl:when>
            <xsl:when test="@type = 'original'">
                <h5>
                    <xsl:apply-templates/>
                </h5>
            </xsl:when>
            <xsl:when test="not(@type)">
                <h5>
                    <xsl:apply-templates/>
                </h5>
            </xsl:when>
            <xsl:when test="tei:orig">
                <h5>
                    <xsl:apply-templates/>
                </h5>
            </xsl:when>
	    <!--<xsl:otherwise>
                <h4>
                    <xsl:apply-templates/>
                </h4>
	    </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:lg/tei:head">
        <p class="center">
            <strong>
                <xsl:apply-templates/>
            </strong>
        </p>
    </xsl:template>
</xsl:stylesheet>
