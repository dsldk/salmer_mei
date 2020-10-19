<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xsl:include href="ab.xsl"/>
    <xsl:include href="abstract.xsl"/>
    <xsl:include href="additions.xsl"/>
    <xsl:include href="app.xsl"/>
    <xsl:include href="appInfo.xsl"/>
    <xsl:include href="application.xsl"/>
    <xsl:include href="back.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="body.xsl"/>
    <xsl:include href="byline.xsl"/>
    <xsl:include href="c.xsl"/>
    <xsl:include href="cit.xsl"/>
    <xsl:include href="closer.xsl"/>
    <xsl:include href="condition.xsl"/>
    <xsl:include href="creation.xsl"/>
    <xsl:include href="damage.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="dateline.xsl"/>
    <xsl:include href="dimensions.xsl"/>
    <xsl:include href="div.xsl"/>
    <xsl:include href="docAuthor.xsl"/>
    <xsl:include href="docImprint.xsl"/>
    <xsl:include href="docTitle.xsl"/>
    <xsl:include href="emph.xsl"/>
    <xsl:include href="encodingDesc.xsl"/>
    <xsl:include href="epigraph.xsl"/>
    <xsl:include href="ex.xsl"/>
    <xsl:include href="extent.xsl"/>
    <xsl:include href="figure.xsl"/>
    <xsl:include href="front.xsl"/>
    <xsl:include href="gap.xsl"/>
    <xsl:include href="handDesc.xsl"/>
    <xsl:include href="head.xsl"/>
    <xsl:include href="height.xsl"/>
    <xsl:include href="hi.xsl"/>
    <xsl:include href="history.xsl"/>
    <xsl:include href="imprimatur.xsl"/>
    <xsl:include href="item.xsl"/>
    <xsl:include href="keywords.xsl"/>
    <xsl:include href="l.xsl"/>
    <xsl:include href="langUsage.xsl"/>
    <xsl:include href="lb.xsl"/>
    <xsl:include href="lg.xsl"/>
    <xsl:include href="list.xsl"/>
    <xsl:include href="listBibl.xsl"/>
    <xsl:include href="listWit.xsl"/>
    <xsl:include href="msDesc.xsl"/>
    <xsl:include href="msIdentifier.xsl"/>
    <xsl:include href="notatedMusic.xsl"/>
    <xsl:include href="note.xsl"/>
    <xsl:include href="objectDesc.xsl"/>
    <xsl:include href="orig.xsl"/>
    <xsl:include href="p.xsl"/>
    <xsl:include href="pb.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="physDesc.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="profileDesc.xsl"/>
    <xsl:include href="projectDesc.xsl"/>
    <xsl:include href="q.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="reg.xsl"/>
    <xsl:include href="samplingDecl.xsl"/>
    <xsl:include href="sealDesc.xsl"/>
    <xsl:include href="signed.xsl"/>
    <xsl:include href="sourceDesc.xsl"/>
    <xsl:include href="sp.xsl"/>
    <xsl:include href="speaker.xsl"/>
    <xsl:include href="stage.xsl"/>
    <xsl:include href="supplied.xsl"/>
    <xsl:include href="support.xsl"/>
    <xsl:include href="supportDesc.xsl"/>
    <xsl:include href="table.xsl"/>
    <xsl:include href="text.xsl"/>
    <xsl:include href="textClass.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="titlePage.xsl"/>
    <xsl:include href="width.xsl"/>
    <xsl:include href="witness.xsl"/>
    <xsl:output method="html" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:p"/>
    <!-- Create identity template -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    <!-- Override identity template, so that only 
        1. elements both not containing children 
        + not containing an attribute, and
        2. elements not containing value 'empty' 
	are copied -->
    <xsl:template match="*[node()/self::text() = 'empty'] | comment()" priority="1"/>
    <!-- Match root element -->
    <xsl:template match="/">
        <xsl:apply-templates select="tei:TEI"/>
    </xsl:template>
    <xsl:template match="tei:TEI">
        <html>
            <head>
                <title>
                    <xsl:value-of select="tei:teiHeader//tei:title"/>
                </title>
                <link>
                    <xsl:attribute name="rel">stylesheet</xsl:attribute>
                    <xsl:attribute name="href">../css/screen.css</xsl:attribute>
                    <xsl:attribute name="type">text/css</xsl:attribute>
                    <xsl:attribute name="media">screen</xsl:attribute>
                </link>
                <link>
                    <xsl:attribute name="rel">stylesheet</xsl:attribute>
                    <xsl:attribute name="href">../css/print.css</xsl:attribute>
                    <xsl:attribute name="type">text/css</xsl:attribute>
                    <xsl:attribute name="media">print</xsl:attribute>
                </link>
                <link>
                    <xsl:attribute name="src">../js/dropdown.js</xsl:attribute>
                </link>
                <xsl:call-template name="notatedMusic_head"/>
            </head>
            <body>
                <div class="summary">
                    <nav role="navigation">
                        <ul class="toc">
                            <!-- Title -->
                            <xsl:choose>
                                <xsl:when test="//tei:fileDesc//tei:title">
                                    <li class="">
                                        <a href=".">
                                            <xsl:value-of select="//tei:fileDesc//tei:title"/>
                                        </a>
                                    </li>
                                    <li class="divider"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <li>Title missing</li>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Metadata section -->
                            <xsl:if test="//tei:teiHeader">
                                <li class="chapter">
                                    <a href="#metadata-section">Metadata</a>
                                </li>
                            </xsl:if>
                            <xsl:if test="//tei:titlePage">
                                <li>
                                    <a href="#titlepage-section">Titelblad</a>
                                </li>
                            </xsl:if>

                            <xsl:for-each select="//tei:front/tei:div">
                                <xsl:variable name="section-id">
                                    <xsl:value-of select="@xml:id"/>
                                </xsl:variable>
                                <li>
                                    <a href="#{$section-id}">
                                        <xsl:value-of select="tei:head[@type = 'add']"/>
                                    </a>
                                </li>
                            </xsl:for-each>
                            <!-- Text body -->
                            <xsl:for-each select="//tei:body/tei:div">
                                <xsl:variable name="section-id">
                                    <xsl:value-of select="@xml:id"/>
                                </xsl:variable>
                                <li>
                                    <a href="#{$section-id}">
                                        <xsl:if test="@n">
                                            <b>
                                                <xsl:value-of select="@n"/> </b>
                                        </xsl:if>
                                        <xsl:value-of select="tei:head[@type = 'add']"/>
                                    </a>
                                    <!-- If there's a subsection -->
                                    <xsl:if test="tei:div">
                                        <ul class="dropdown-container">
                                            <button class="dropbtn">
                                                <i class="fa fa-caret-down"/>
                                            </button>
                                            <xsl:for-each select="tei:div">
                                                <xsl:variable name="subsection-id">
                                                  <xsl:value-of select="@xml:id"/>
                                                </xsl:variable>
                                                <li>
                                                  <a href="#{$subsection-id}">
                                                  <xsl:if test="@n">
                                                  <b>
                                                  <xsl:value-of select="@n"/>  </b>
                                                  </xsl:if>
                                                  <xsl:value-of select="tei:head[@type = 'add']"/>
                                                  </a>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                    </xsl:if>
                                </li>
                            </xsl:for-each>

                            <!--<xsl:choose>
                                <xsl:when test="//tei:teiHeader">
                                    <li class="chapter">
                                        <a href="#metadata-section">Metadata</a>
                                    </li>
                                </xsl:when>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="//tei:titlePage">
                                    <li class="chapter">
                                        <a href="#titlepage-section">Title page</a>
                                    </li>
                                </xsl:when>
                            </xsl:choose>
                            <li>1. Indledning</li>
                            <li>2. Metadata</li>-->
                        </ul>
                    </nav>
                </div>
                <div class="content fixed">
                    <div class="content-inner">
                        <div class="text-header"><!--Her skal være et eller andet--></div>
                        <div class="text-wrapper">
                            <div class="text-inner">
                                <div class="metadata" id="metadata-section">

                                    <h1>Metadata</h1>
                                    <div>
                                        <p> Denne fil, <code>
                                                <xsl:value-of select="tei:teiHeader//tei:publicationStmt/tei:idno[1]"/>.xml</code>, er en DSL-basis-version (v. 0.1) af
                                                  <strong>
                                                <xsl:value-of select="tei:teiHeader//tei:title"/>
                                            </strong>
                                            finansieret af <xsl:value-of select="tei:teiHeader//tei:titleStmt/tei:funder"/>
                                        </p>
                                        <p> Redaktør: 
                                            <xsl:for-each select="tei:teiHeader//tei:titleStmt/tei:editor">
                                                <xsl:value-of select="tei:name//tei:forename"/>
                                                <xsl:text> </xsl:text>
                                                <xsl:value-of select="tei:name//tei:surname"/>
                                                <xsl:if test="position() != last()">, </xsl:if>
                                                <xsl:if test="position() = last() and child::node() != 'empty'">. </xsl:if>
                                            </xsl:for-each><!--<xsl:value-of
                                                select="tei:teiHeader//tei:editor/tei:name/@xml:id"
                                            />-->
                                        </p>
                                        <p> Dokumentets historik: </p>
                                    </div>
                                    <div>
                                        <xsl:apply-templates select="tei:teiHeader/tei:encodingDesc"/>
                                    </div>
                                    <div>
                                        <xsl:apply-templates select="tei:teiHeader/tei:profileDesc"/>
                                    </div>
                                    <div>
                                        <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc"/>
                                    </div>

                                </div>
                                <div class="text-container">
                                    <xsl:apply-templates select="tei:text"/>
                                </div>
                                <xsl:if test="//tei:note">
                                    <div>
                                        <h2>Fodnoter</h2>
                                        <xsl:apply-templates select="//tei:note[@place = 'bottom']" mode="footnoteApparatus"/>
                                    </div>
                                </xsl:if>
                                <xsl:if test="//tei:app">
                                    <div>
                                        <h2>Kritisk apparat</h2>
                                        <xsl:apply-templates select="//tei:app" mode="apparatusCriticus"/>
                                    </div>
                                </xsl:if>
                                <xsl:if test="//tei:cit">
                                    <div>
                                        <h2>Citater</h2>
                                        <xsl:apply-templates select="//tei:cit" mode="quotationApparatus"/>
                                    </div>
                                </xsl:if>

                                <!--<xsl:if test="//tei:note[@type='add']">
                    <div>
                        <h3>Kommentarer</h3>
                        <xsl:apply-templates select="//tei:note[@type='add']"/>
                    </div>
                </xsl:if>-->

                            </div>
                        </div>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>