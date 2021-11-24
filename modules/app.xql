xquery version "3.1";

(: 
 : Module for app-specific template functions
 :
 : Add your own templating functions here, e.g. if you want to extend the template used for showing
 : the browsing view.
 :)
module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare 
    %templates:wrap
function app:counts($node as node(), $model as map(*)) {
    map {
        "letters": count(collection($config:data-root || "/letters")/tei:TEI),
        "people": count(doc($config:data-root || "/people.xml")//tei:person)
    }
};

declare function app:view-bibliography($node as node(), $model as map(*)) {
    
    let $type := if ($model?name) then $model?name else 'Archivbestande'
    let $letter := if ($model?letter) then $model?letter else 'A'

    let $category := switch($type)
        case "Escheriana" return "escheriana"
        case "Ungedruckte-Quellen" return "unprinted_source"
        case "Gedruckte-Quellen" return "printed_source"
        case "Zeitungen-und-Zeitschriften" return "newspaper"
        case "Literatur" return "literature"
        case "Websites" return "online"
        case "Archivbestande" return "archive"
        default return "escheriana"

    let $hits := 
        switch ($category)
            case "escheriana" return
                collection($config:data-root || "/bibliography")//tei:bibl[@subtype="escheriana"]
            default return 
                collection($config:data-root || "/bibliography")/id($category)/tei:bibl
    
    let $matches := 
        switch($letter)
            case "Alle" return 
                $hits
            default return 
                $hits[starts-with(./tei:bibl, $letter)]


    for $group in $matches
        let $initial := upper-case(substring(normalize-space($group/tei:bibl), 1, 1))
        group by $initial 
        order by $initial
        return 
            <div class="bibentry">
                <h3 id="{$initial}">{$initial}</h3>
                <div>
                {
                    for $entry in $group
                    return 
                        <p>{$entry/tei:bibl} [{$entry/tei:abbr}]</p>
                }
                </div>
            </div>
};

declare function app:initial-bibliography($node as node(), $model as map(*)) {
        let $type := if ($model?name) then $model?name else 'Archivbestande'

        let $category := switch($type)
                case "Escheriana" return "escheriana"
                case "Ungedruckte-Quellen" return "unprinted_source"
                case "Gedruckte-Quellen" return "printed_source"
                case "Zeitungen-und-Zeitschriften" return "newspaper"
                case "Literatur" return "literature"
                case "Websites" return "online"
                case "Archivbestande" return "archive"
                default return "escheriana"
        

        let $foo := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        let $letters := 
            for $index in 1 to string-length($foo)
                return substring($foo, $index, 1)

        let $initials :=
                for $i in collection($config:data-root || "/bibliography")/id($category)//tei:bibl
                let $foo := upper-case(substring($i, 1, 1))
                group by $foo
                order by $foo
                return $foo[1]

        return 

            <div>
                <h1>Bibliographie: <pb-i18n key="label.{$category}">{$type}</pb-i18n></h1>
                {
                    for $i in $initials[.=$letters]
                        return
                    <a href="{$i}" class="initial">{$i}</a>
                }
                {
                    switch ($category) 
                        case "escheriana" return ()
                        default return <a href="Alle" class="initial"><pb-i18n key="label.all">All</pb-i18n></a>
                }
            </div>
            
};

declare function app:initial-abbreviations($node as node(), $model as map(*)) {
        let $type := if ($model?name) then $model?name else 'Quellen'
        let $type := 
            switch ($type)
                case "Quellen" return 'source'
                default return 'secondary'

        let $foo := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        let $letters := 
            for $index in 1 to string-length($foo)
                return substring($foo, $index, 1)

        let $initials :=
                for $i in collection($config:data-root || "/abbreviations")/id($type)//tei:catDesc
                let $foo := upper-case(substring($i, 1, 1))
                group by $foo
                order by $foo
                return $foo

        return 
            (for $i in $letters      
                return
                    <a href="{$i}" class="initial">{$i}</a>,
            <a href="other" class="initial">other</a>)
};

declare function app:view-abbreviations($node as node(), $model as map(*)) {
    let $type := if ($model?name) then $model?name else 'Quellen'

    let $type := 
        switch ($type)
            case "Quellen" return 'source'
            default return 'secondary'

    let $letter := if ($model?letter) then $model?letter else 'A'

    return 
        <div class="letter">
            <h3>{$letter}</h3>
            <table>
            {
            switch($letter) 
                case "other" return
                    for $entry in collection($config:data-root || "/abbreviations")/id($type)/tei:category[matches(tei:catDesc[@ana='abbr'], '^\W')]
                        return 
                            <tr><td>{$entry/tei:catDesc[@ana='abbr']/string()}</td><td>{$entry/tei:catDesc[@ana='full']/string()}</td></tr>
                default return
                    for $entry in collection($config:data-root || "/abbreviations")/id($type)/tei:category[starts-with(tei:catDesc, $letter)]
                        return 
                            <tr><td>{$entry/tei:catDesc[@ana='abbr']/string()}</td><td>{$entry/tei:catDesc[@ana='full']/string()}</td></tr>
            }
            </table>
        </div>
};
