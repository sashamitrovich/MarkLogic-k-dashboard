xquery version "1.0-ml";

module namespace datetime = "http://marklogic.com/datetime";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false"; (::)

declare function datetime:parse-date(
  $str as xs:string
)
  as xs:date?
{
  datetime:parse-date($str, ())
};

declare function datetime:parse-date(
  $str as xs:string,
  $lang as xs:string?
)
  as xs:date?
{
  datetime:parse-date($str, $lang, true())
};

declare private function datetime:apply-simple-date-patterns(
  $str as xs:string
)
  as xs:string
{
  (: simple patterns :)

  (: clean up US MDY date order, recognized by / :)
  (:
    03/18/2015
    3/18/2015
    3/8/2015
  :)
  let $str := replace($str, "^(0?\d|1[0-2])/(0?\d|[1-3]\d)/(\d{4})", "$3-$1-$2")

  (: clean up date separator :)
  (:
    2015/08/03
    2000:09:13
    2000.09.13
  :)
  let $str := replace($str, "^(\d{1,4})[/:.](\d{1,4})[/:.](\d{1,4})", "$1-$2-$3")

  (: clean up date order :)
  (:
    18-03-2015 (DMY most common!)
  :)
  let $str := replace($str, "^(\d{1,2})-(\d{1,2})-(\d{4})", "$3-$2-$1")

  (: append (guessed) century to year :)
  (:
    18-03-15 (DMY most common!)
  :)
  (: Note: this pattern was used most *before* 2000, taking 50/50 split around that year :)
  let $str := replace($str, "^(\d{2})-(\d{2})-([5-9]\d)", "19$3-$2-$1")
  let $str := replace($str, "^(\d{2})-(\d{2})-([0-4]\d)", "20$3-$2-$1")

  (: clean up missing zeros :)
  (:
    2015-3-8
    2015-3-18
    2015-11-8
  :)
  let $str := replace($str, "^(\d{4})-(\d)-(\d{1,2})", "$1-0$2-$3")
  let $str := replace($str, "^(\d{4})-(\d{2})-(\d$|\d[^\d])", "$1-$2-0$3")

  return $str
};

declare private function datetime:apply-simple-timezone-patterns(
  $str as xs:string
) as xs:string
{
  (: normalize timezone separator :)
  (:
    +02'00'
    -05'00'
  :)
  let $str := replace($str, "([+\-]\d{2})'(\d{2})'$", "$1:$2")

  (: add missing timezone separator :)
  (:
    +0200
    -0500
  :)
  let $str :=
    (: skip over anything that might look like a date :)
    if (matches($str, "^[^-]+-[^-]+-[^-]+$")) then
      $str
    else
      replace($str, "([+\-]\d{2})(\d{2})$", "$1:$2")

  (: translate timezone indication (if any) :)
  (:
    (UTC)
    (GMT)
    (BST)
    CET
    CEST
  :)
  let $str :=
    if (matches($str, "\s[(]?" || $timezones-pattern || "[)]?$")) then
      let $match := replace($str, "^.*(\s[(]?" || $timezones-pattern || "[)]?)$", "$1")
      let $abbrev := upper-case(replace($str, "^.*(\s[(]?" || $timezones-pattern || "[)]?)$", "$2"))
      return replace($str, replace($match, "([()])", "\\$1"), map:get($timezones, $abbrev))
    else
      $str

  (: strip whitespace in front of timezone :)
  let $str := replace($str, "\s+([+\-]\d{2}:\d{2})$", "$1")

  return $str
};

declare private function datetime:apply-simple-time-patterns(
  $str as xs:string
)
  as xs:string
{
  let $str := replace($str, "(^|:|T)(\d)(:|$)", "$10$2$3")
  let $str := replace($str, "(^|:|T)(\d)(:|$)", "$10$2$3") (: apply twive because of overlapping patterns :)
  let $str := replace($str, "(^|T)(\d{2}:\d{2})($|[+-])", "$1$2:00$3")
  return $str
};

(:
Converted_Date=23-Sep-1999
:)
declare private function datetime:parse-date(
  $org-str as xs:string,
  $lang as xs:string?,
  $recurse as xs:boolean
)
  as xs:date?
{
  (: general string clean-up :)
  let $str := normalize-space($org-str)
  return

  (: castable :)
  if ($str castable as xs:date) then
    xs:date($str)
  else

    let $str := datetime:apply-simple-date-patterns($str)

    let $str := datetime:apply-simple-timezone-patterns($str)

    return

    if ($str castable as xs:date) then
      xs:date($str)
    else

      (: complex patterns :)

      let $str := replace(replace(translate($str, ",", ""), "^D:", "", "i"), "\s*Z$", "-00:00", "i")
      let $date := try {
        (: 23-Sep-1999 :)
        if (matches($str, "^\d{1,2}-\w{3,}-\d{4}$")) then
          xs:date(xdmp:parse-dateTime("[D1]-[Mn]-[Y0001]", lower-case($str), $lang))
        (: Fri Jul 05 2002 :)
        else if (matches($str, "^\w{2,} \w{3,} \d{1,2} \d{4}$")) then
          xs:date(xdmp:parse-dateTime("[Fn] [Mn] [D1] [Y0001]", lower-case($str), $lang))
        (: 6 Feb 2001-00:00 :)
        else if (matches($str, "^\d{1,2} \w{3,} \d{4}[+\-]\d{2}:\d{2}$")) then
          xs:date(xdmp:parse-dateTime("[D1] [Mn] [Y0001][Z]", lower-case($str), $lang))
        (: Fri 27 Apr 2001 :)
        else if (matches($str, "^\w{2,} \d{1,2} \w{3,} \d{4}$")) then
          xs:date(xdmp:parse-dateTime("[Fn] [D1] [Mn] [Y0001]", lower-case($str), $lang))
        (: Fri 6 Oct 2000-07:00 :)
        else if (matches($str, "^\w{2,} \d{1,2} \w{3,} \d{4}[+\-]\d{2}:\d{2}$")) then
          xs:date(xdmp:parse-dateTime("[Fn] [D1] [Mn] [Y0001][Z]", lower-case($str), $lang))
        (: Friday January 28 2000 :)
        else if (matches($str, "^\w{2,} \w{3,} \d{1,2} \d{4}$")) then
          xs:date(xdmp:parse-dateTime("[Fn] [Mn] [D1] [Y0001]", lower-case($str), $lang))
        else
          ()
      } catch ($e) {
        xdmp:log($e)
      }
      let $date :=
        if (empty($date) and $recurse) then
          (: last resort, try parsing as date :)
          datetime:parse-dateTime($org-str, $lang, false())
        else
          $date
      where exists($date)
      return xs:date($date)
};

(:
Fail:
CreationDate=1910/10/30 11:10:752
Creation_Date=xxx
Creation_Date=00:00

Castable:
xmp_pdf_CreationDate=2001-04-26T17:49:38Z
xmp_pdf_CreationDate=2002-02-19T23:46:50Z
xmp_pdf_ModDate=2001-04-26T13:12:40-05:00
xmp_pdf_ModDate=2002-02-19T18:52:09-05:00
xmp_xap_CreateDate=2001-04-26T17:49:38Z
xmp_xap_CreateDate=2002-02-19T23:46:50Z
xmp_xap_MetadataDate=2001-04-26T13:12:40-05:00
xmp_xap_MetadataDate=2002-02-19T18:52:09-05:00
xmp_xap_ModifyDate=2001-04-26T17:49:38Z
xmp_xap_ModifyDate=2002-02-19T18:52:09-05:00

Simple:
CreationDate=2000/02/10 18:18:52
CreationDate=2000/03/21 15:40:04
CreationDate=2001/05/10 08:26:43
CreationDate=2001/05/18 14:12:15
CreationDate=2013/05/27 17:09:27+02'00'
CreationDate=2015/02/05 08:07:14 (UTC)
CreationDate=2015/02/05 08:07:14Z
CreationDate=2015/08/03 14:25:36-05'00'
Date=2000:09:13 13:05:25
Date=2000:09:30 18:22:51
Date=2001:10:14 14:47:40
Date=2002:01:15 19:31:10
Date=2002:03:23 15:18:44
ModDate=2000/11/01 18:41:08-05'00'
ModDate=2001/04/10 17:43:22
ModDate=2001/05/23 10:39:00
ModDate=2001/05/29 10:56:12+01'00'
ModDate=2015/02/05 08:07:14 (UTC)
Original_Date_Time=2002:03:23 15:18:44

Complex:
CreationDate=D:Fri Jul 05 15:52:53 2002
CreationDate=Friday, January 28, 2000 9:52:22 AM
Creation_Date=Mon, 18 Dec 2000 9:53:00 PM (UTC)
Creation_Date=Sun, 13 Sep 1999 4:46:00 PM
Creation_Date=Sun, 22 Feb 2000 8:54:00 AM
Date=6 Feb 2001 00:22:15 -0000
Date=Fri, 27 Apr 2001 3:23:39 PM (UTC)
Date=Fri, 6 Oct 2000 09:20:25 -0700
Date=Mon, 24 Apr 2000 11:25:41 PM (UTC)
Date=Mon, 5 Mar 2001 12:42:29 -0800
Date=Thu, 1 Mar 2001 09:13:00 -0700
Date=Wed, 13 Dec 2000 15:55:35 -0800
Date=Wed, 15 Nov 2000 18:12:53 -0800
Date=Wed, 22 Mar 2000 8:46:52 PM (UTC)
Date_created=Wed, 14 Mar 2001 10:26:00 PM (UTC)
Date_modified=Wed, 26 Sep 2001 3:45:00 PM (UTC)
Last_Edited_Date=Sun, 13 Sep 1999 4:46:00 PM
Last_Edited_Date=Sun, 22 Feb 2000 8:54:00 AM
Last_Saved_Date=Sat, 23 Dec 2000 1:33:00 AM (UTC)
Last_Saved_Date=Thu, 31 Jan 2002 5:21:36 PM (UTC)
Sent_Date=Fri, 27 Apr 2001 10:23:39 AM
Sent_Date=Mon, 24 Apr 2000 6:25:41 PM
Sent_Date=Wed, 22 Mar 2000 5:46:52 PM

International:
Date=vrijdag, 6 oktober 2000 09:20:25 -0700, nl
Date=vendredi, 6 octobre 2000 09:20:25 -0700, fr
:)
declare function datetime:parse-dateTime(
  $str as xs:string
)
  as xs:dateTime?
{
  datetime:parse-dateTime($str, ())
};

declare function datetime:parse-dateTime(
  $str as xs:string,
  $lang as xs:string?
)
  as xs:dateTime?
{
  datetime:parse-dateTime($str, $lang, true())
};

declare private function datetime:parse-dateTime(
  $org-str as xs:string,
  $lang as xs:string?,
  $recurse as xs:boolean
)
  as xs:dateTime?
{
  (: general string clean-up :)
  let $str := normalize-space($org-str)
  return

  (: castable :)
  if ($str castable as xs:dateTime) then
    xs:dateTime($str)
  else

    let $str := datetime:apply-simple-date-patterns($str)

    (: clean up date-time separator :)
    (:
      2015-08-03 14:25:36
    :)
    let $str := replace($str, "^(\d{2,4})-(\d{2,4})-(\d{2,4})\s+", "$1-$2-$3T")

    let $str := datetime:apply-simple-timezone-patterns($str)

    let $str := datetime:apply-simple-time-patterns($str)

    return

    if ($str castable as xs:dateTime) then
      xs:dateTime($str)
    else
      let $str := replace(replace(translate($str, ",", ""), "^D:", "", "i"), "\s*(AM|PM)?Z$", "$1-00:00", "i")
      (: strip whitespace in front of AM/PM :)
      let $str := replace($str, "\s*(AM|PM)", "$1", "i")
      let $date := try {
        (: Fri Jul 05 15:52:53 2002 :)
        if (matches($str, "^\w{2,} \w{3,} \d{1,2} \d{1,2}:\d{2}:\d{2} \d{4}$")) then
          xdmp:parse-dateTime("[Fn] [Mn] [D1] [H1]:[m01]:[s01] [Y0001]", lower-case($str), $lang)
        (: 6 Feb 2001 00:22:15-00:00 :)
        else if (matches($str, "^\d{1,2} \w{3,} \d{4} \d{1,2}:\d{2}:\d{2}[+\-]\d{2}:\d{2}$")) then
          xdmp:parse-dateTime("[D1] [Mn] [Y0001] [H1]:[m01]:[s01][Z]", lower-case($str), $lang)
        (: Fri 6 Oct 2000 09:20:25-07:00 :)
        else if (matches($str, "^\w{2,} \d{1,2} \w{3,} \d{4} \d{1,2}:\d{2}:\d{2}[+\-]\d{2}:\d{2}$")) then
          xdmp:parse-dateTime("[Fn] [D1] [Mn] [Y0001] [H1]:[m01]:[s01][Z]", lower-case($str), $lang)
        (: Fri 27 Apr 2001 3:23:39PM :)
        else if (matches($str, "^\w{2,} [0-9]{1,2} \w{3,} [0-9]{4,4} [0-9]{1,2}:[0-9]{2,2}:[0-9]{2,2}(AM|PM)$", "i")) then
          xdmp:parse-dateTime("[Fn] [D1] [Mn] [Y0001] [h1]:[m01]:[s01][Pn]", lower-case($str), $lang)
        (: Fri 27 Apr 2001 3:23:39PM+02:00 :)
        else if (matches($str, "^\w{2,} [0-9]{1,2} \w{3,} [0-9]{4,4} [0-9]{1,2}:[0-9]{2,2}:[0-9]{2,2}(AM|PM)[+\-]\d{2}:\d{2}$", "i")) then
          xdmp:parse-dateTime("[Fn] [D1] [Mn] [Y0001] [h1]:[m01]:[s01][Pn][Z]", lower-case($str), $lang)
        (: Friday January 28 2000 9:52:22AM :)
        else if (matches($str, "^\w{2,} \w{3,} [0-9]{1,2} [0-9]{4,4} [0-9]{1,2}:[0-9]{2,2}:[0-9]{2,2}(AM|PM)$", "i")) then
          xdmp:parse-dateTime("[Fn] [Mn] [D1] [Y0001] [h1]:[m01]:[s01][Pn]", lower-case($str), $lang)
        else
          ()
      } catch ($e) {
        xdmp:log($e)
      }
      let $date :=
        if (empty($date) and $recurse) then
          (: last resort, try parsing as date :)
          datetime:parse-date($org-str, $lang, false())
        else
          $date
      where exists($date)
      return xs:dateTime($date)
};

declare function datetime:parse-time(
  $str as xs:string
)
  as xs:time?
{
  (: general string clean-up :)
  let $str := normalize-space($str)
  return
  if ($str castable as xs:time) then
    xs:time($str)
  else if ($str castable as xs:date) then
    xs:time(xs:date($str))
  else if ($str castable as xs:dateTime) then
    xs:time(xs:dateTime($str))
  else

    let $str := datetime:apply-simple-timezone-patterns($str)
    let $str := datetime:apply-simple-time-patterns($str)
    let $_ := xdmp:log($str)
    where $str castable as xs:time
    return
      xs:time($str)
};

declare function datetime:date-attrs($date as xs:date) {
  attribute datetime:date { $date },

  attribute datetime:year-quarter { xs:gYear($date) || "-" || xdmp:quarter-from-date($date) },
  attribute datetime:year-month { xs:gYearMonth($date) },

  attribute datetime:year { xs:gYear($date) },
  attribute datetime:quarter { xdmp:quarter-from-date($date) },
  attribute datetime:month { xs:gMonth($date) },
  attribute datetime:week { xdmp:week-from-date($date) },
  attribute datetime:day { xs:gDay($date) },

  attribute datetime:yearday { xdmp:yearday-from-date($date) },
  attribute datetime:weekday { xdmp:weekday-from-date($date) },

  attribute datetime:timezone { timezone-from-date($date) }
};

declare function datetime:time-attrs($time as xs:time) {
  attribute datetime:time { $time },

  attribute datetime:hours { hours-from-time($time) },
  attribute datetime:minutes { minutes-from-time($time) },
  attribute datetime:seconds { seconds-from-time($time) }
};

(:
Locates meta tags with date information from the supplied HTML document.
The order of preference for the date node is:

  1) 'Modification Date' / 'SaveDate'
  2) 'Creation Date'
  3) 'Original Date'
  4) Any other node with 'Date' in it

:)
declare function datetime:get-html-date(
  $html as node()*
)
  as element()?
{
  (
    let $dates := (
      $html//*:meta[contains(@name, "Date") and (contains(@name, "Mod") or contains(@name, "Save"))],
      $html//*:meta[contains(@name, "Date") and contains(@name, "Creat")],
      $html//*:meta[contains(@name, "Date") and contains(@name, "Orig")],
      $html//*:meta[contains(@name, "Date")]
    )
    for $date in $dates
    let $val := if ($date/@content) then $date/@content else $date
    where string-length($val) gt 0
    return $date
  )[1]
};

declare function datetime:enrich-date(
  $elem as element()
)
  as element()
{
  let $value := string(($elem/@content, $elem/@value, $elem)[1])
  return
    if (string-length($value) > 0) then
      let $date := datetime:parse-date($value)
      return
        element { node-name($elem) } {

          if (exists($date)) then
            datetime:date-attrs($date)
          else (),

          $elem/@*,
          $elem/node()
        }
    else $elem
};

declare function datetime:enrich-time(
  $elem as element()
)
  as element()
{
  let $value := string(($elem/@content, $elem/@value, $elem)[1])
  return
    if (string-length($value) > 0) then
      let $time := datetime:parse-time($value)
      return
        element { node-name($elem) } {

          if (exists($time)) then (
            datetime:time-attrs($time),
            attribute datetime:timezone { timezone-from-time($time) }
          ) else (),

          $elem/@*,
          $elem/node()
        }
    else $elem
};

declare function datetime:enrich-dateTime(
  $elem as element()
)
  as element()
{
  let $value := string(($elem/@content, $elem/@value, $elem)[1])
  return
    if (string-length($value) > 0) then
      let $dateTime := datetime:parse-dateTime($value)
      return
        element { node-name($elem) } {

          if (exists($dateTime)) then
            let $date := xs:date($dateTime)
            let $time := xs:time($dateTime)
            return (
              attribute datetime:dateTime { $dateTime },
              datetime:date-attrs($date),
              datetime:time-attrs($time)
            )
          else (),

          $elem/@*,
          $elem/node()
        }
    else $elem
};

declare function datetime:get-age($birthdate as xs:date) as xs:integer {
  let $now := current-date()
  let $current-year := year-from-date($now)
  let $birth-year := year-from-date($birthdate)
  let $current-year-birthdate := $birthdate + xs:yearMonthDuration( "P" || ($current-year - $birth-year) || "Y" )
  return
    $current-year - $birth-year - (if ($now ge $current-year-birthdate) then 0 else 1)
};

declare function datetime:from-epoch($epoch as xs:long) as xs:dateTime {
  xs:dateTime("1970-01-01T00:00:00-00:00") + xs:dayTimeDuration("PT" || ($epoch div 1000) || "S")
};

(: Based on: http://stackoverflow.com/a/7484211/918496 :)
declare function datetime:to-epoch($dateTime as xs:dateTime) as xs:long {
  ($dateTime - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration("PT0.001S")
};

declare function datetime:from-excel($date-numeric as xs:double)
{
  (: Note:
   : This function is unreliable for dates before March 1st, 1900, due to the so-called Lotes 1-2-3 bug.
   : There is a whole story behind the peculiar start date. This links explains where it comes from:
   :   https://blogs.msdn.microsoft.com/ericlippert/2003/09/16/erics-complete-guide-to-vt_date/
   : This link shows it with some code:
   :   https://stackoverflow.com/a/36378821/918496
   :)
  xs:dateTime('1899-12-30T00:00:00') + (xs:dayTimeDuration('P1D') * $date-numeric)
};

declare private variable $timezones := map:new((
  map:entry("ACDT", "+10:30"), map:entry("ACST", "+09:30"), map:entry("ADT", "-03:00"), map:entry("AEDT", "+11:00"), map:entry("AEST", "+10:00"), map:entry("AHDT", "-09:00"), map:entry("AHST", "-10:00"), map:entry("AST", "-04:00"), map:entry("AT", "-02:00"), map:entry("AWDT", "+09:00"), map:entry("AWST", "+08:00"), map:entry("BAT", "+03:00"), map:entry("BDST", "+02:00"), map:entry("BET", "-11:00"), map:entry("BST", "-03:00"), map:entry("BT", "+03:00"), map:entry("BZT2", "-03:00"), map:entry("CADT", "+10:30"), map:entry("CAST", "+09:30"), map:entry("CAT", "-10:00"), map:entry("CCT", "+08:00"), map:entry("CDT", "-05:00"), map:entry("CED", "+02:00"), map:entry("CET", "+01:00"), map:entry("CEST", "+02:00"), map:entry("CST", "-06:00"), map:entry("EAST", "+10:00"), map:entry("EDT", "-04:00"), map:entry("EED", "+03:00"), map:entry("EET", "+02:00"), map:entry("EEST", "+03:00"), map:entry("EST", "-05:00"), map:entry("FST", "+02:00"), map:entry("FWT", "+01:00"), map:entry("GMT", "-00:00"), map:entry("GST", "+10:00"), map:entry("HDT", "-09:00"), map:entry("HST", "-10:00"), map:entry("IDLE", "+12:00"), map:entry("IDLW", "-12:00"), map:entry("IST", "+05:30"), map:entry("IT", "+03:30"), map:entry("JST", "+09:00"), map:entry("JT", "+07:00"), map:entry("MDT", "-06:00"), map:entry("MED", "+02:00"), map:entry("MET", "+01:00"), map:entry("MEST", "+02:00"), map:entry("MEWT", "+01:00"), map:entry("MST", "-07:00"), map:entry("MT", "+08:00"), map:entry("NDT", "-02:30"), map:entry("NFT", "-03:30"), map:entry("NT", "-11:00"), map:entry("NST", "+06:30"), map:entry("NZ", "+11:00"), map:entry("NZST", "+12:00"), map:entry("NZDT", "+13:00"), map:entry("NZT", "+12:00"), map:entry("PDT", "-07:00"), map:entry("PST", "-08:00"), map:entry("ROK", "+09:00"), map:entry("SAD", "+10:00"), map:entry("SAST", "+09:00"), map:entry("SAT", "+09:00"), map:entry("SDT", "+10:00"), map:entry("SST", "+02:00"), map:entry("SWT", "+01:00"), map:entry("USZ3", "+04:00"), map:entry("USZ4", "+05:00"), map:entry("USZ5", "+06:00"), map:entry("USZ6", "+07:00"), map:entry("UT", "-00:00"), map:entry("UTC", "-00:00"), map:entry("UZ10", "+11:00"), map:entry("WAT", "-01:00"), map:entry("WET", "-00:00"), map:entry("WST", "+08:00"), map:entry("YDT", "-08:00"), map:entry("YST", "-09:00"), map:entry("ZP4", "+04:00"), map:entry("ZP5", "+05:00"), map:entry("ZP6", "+06:00")
));
declare private variable $timezones-pattern := "(" || string-join(map:keys($timezones), "|") || ")";
