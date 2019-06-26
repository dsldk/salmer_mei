I mappen <https://github.com/dsldk/dsl-tei/tree/master/xslt> findes
XSLT-stilark til transformation af dokumenter, der validerer med
dsl-tei.rnc. Mappen indeholder følgende to stylesheets:

1. `main.xsl` -- hovedstilark for en række moduler, som genererer
   HTML-version af et TEI-DSL-dokument. Formålet er at levere en
   redaktionel kopi af teksten til gennemlæsning og korrektur 
2. `filter.xsl` -- enkeltstående stilark, der bortfiltrerer forskellige
   former for metadata og tekstdata, således at kun tekst og basale
   oplysninger fremgår

# Forudsætninger

# Installation

## Linux

	$ apt-get update && apt-get install saxon
 
## Mac OSX

Installer Homebrew:

	$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Opdater pakkelisten

	$ brew update

Installér saxon

	$ brew install saxon
	

# Fremgangsmåde

	$ saxon -o /html/test.html /xml/14021010001.xml /xslt/main.xsl


