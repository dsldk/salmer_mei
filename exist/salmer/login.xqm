xquery version "3.0" encoding "UTF-8";
module namespace login="http://dsl.dk/salmer/login";

declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare function login:function() as xs:boolean
{
  let $lgin := xmldb:login("/db", "YourAdminUserName", "YourAdminPassword")
  return $lgin
};


