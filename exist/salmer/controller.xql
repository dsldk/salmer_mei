xquery version "3.1";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


if ($exist:path eq '/') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<forward url="index.xq"/>
        </dispatch>
else if (starts-with($exist:path, "(/doc/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="doc.xq">
            <add-parameter name="filename" value="{$exist:resource}.xml"/>
        </forward>
    </dispatch>

else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist"/>
    
    
