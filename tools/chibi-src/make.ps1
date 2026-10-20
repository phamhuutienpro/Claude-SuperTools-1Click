$out = $PSScriptRoot
function Girl($name,$hair,$hairDark,$dress,$bow,$eye,$flower) {
@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
<ellipse cx="128" cy="248" rx="62" ry="7" fill="#000" opacity=".08"/>
<ellipse cx="48" cy="150" rx="26" ry="52" fill="$hair" transform="rotate(14 48 150)"/>
<ellipse cx="208" cy="150" rx="26" ry="52" fill="$hair" transform="rotate(-14 208 150)"/>
<circle cx="40" cy="198" r="9" fill="$hairDark"/><circle cx="216" cy="198" r="9" fill="$hairDark"/>
<path d="M82 196 Q128 182 174 196 L190 244 Q128 254 66 244 Z" fill="$dress"/>
<path d="M104 198 Q128 212 152 198 L146 190 Q128 200 110 190 Z" fill="#fff"/>
<circle cx="76" cy="212" r="12" fill="#FFE4D6"/><circle cx="180" cy="212" r="12" fill="#FFE4D6"/>
<ellipse cx="128" cy="104" rx="84" ry="80" fill="$hair"/>
<ellipse cx="128" cy="124" rx="72" ry="66" fill="#FFE9DC"/>
<path d="M54 110 Q60 44 128 40 Q196 44 202 110 Q186 84 168 78 Q150 96 128 82 Q104 98 86 78 Q68 84 54 110 Z" fill="$hair"/>
<path d="M60 100 Q70 62 100 52" stroke="#fff" stroke-width="5" fill="none" opacity=".45" stroke-linecap="round"/>
<ellipse cx="96" cy="128" rx="14" ry="19" fill="#3a2a3f"/><ellipse cx="160" cy="128" rx="14" ry="19" fill="#3a2a3f"/>
<ellipse cx="96" cy="132" rx="10" ry="14" fill="$eye"/><ellipse cx="160" cy="132" rx="10" ry="14" fill="$eye"/>
<circle cx="91" cy="121" r="6" fill="#fff"/><circle cx="155" cy="121" r="6" fill="#fff"/>
<circle cx="101" cy="137" r="3" fill="#fff"/><circle cx="165" cy="137" r="3" fill="#fff"/>
<ellipse cx="74" cy="154" rx="14" ry="8" fill="#FF8FAB" opacity=".55"/><ellipse cx="182" cy="154" rx="14" ry="8" fill="#FF8FAB" opacity=".55"/>
<path d="M118 156 Q128 168 138 156" stroke="#d6547a" stroke-width="4" fill="#ff9db5" stroke-linecap="round" stroke-linejoin="round"/>
<g transform="translate(176 52)"><path d="M0 0 L-30 -18 Q-40 0 -30 18 Z" fill="$bow"/><path d="M0 0 L30 -18 Q40 0 30 18 Z" fill="$bow"/><circle cx="0" cy="0" r="9" fill="#fff" opacity=".9"/></g>
$flower
<text x="214" y="40" font-size="22" fill="#FF6F9C">&#10084;</text><text x="26" y="52" font-size="16" fill="#7FB8FF">&#10022;</text>
</svg>
"@ | Set-Content -Encoding UTF8 (Join-Path $out "$name.svg")
}
$rose = '<g transform="translate(70 62)"><circle r="12" fill="#FF6F9C"/><circle r="6" fill="#FF9DBB"/><circle cx="-14" cy="-6" r="6" fill="#8AD6A5"/><circle cx="14" cy="-6" r="6" fill="#8AD6A5"/></g>'
$star = '<g transform="translate(70 62)"><path d="M0 -14 L4 -4 L15 -4 L6 3 L9 14 L0 7 L-9 14 L-6 3 L-15 -4 L-4 -4 Z" fill="#FFD76A"/></g>'
Girl "chibi-girl-pink" "#FFB3CF" "#FF8FB6" "#FF8FB6" "#7FB8FF" "#E8559A" $rose
Girl "chibi-girl-blue" "#A9D4FF" "#7FB8FF" "#7FB8FF" "#FF8FB6" "#4E8BE0" $star
@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
<ellipse cx="128" cy="246" rx="70" ry="8" fill="#000" opacity=".08"/>
<ellipse cx="86" cy="64" rx="22" ry="62" fill="#fff" stroke="#E3CFE0" stroke-width="3" transform="rotate(-10 86 64)"/><ellipse cx="86" cy="68" rx="11" ry="46" fill="#FFC2D6" transform="rotate(-10 86 68)"/>
<ellipse cx="170" cy="64" rx="22" ry="62" fill="#fff" stroke="#E3CFE0" stroke-width="3" transform="rotate(10 170 64)"/><ellipse cx="170" cy="68" rx="11" ry="46" fill="#FFC2D6" transform="rotate(10 170 68)"/>
<ellipse cx="128" cy="205" rx="58" ry="42" fill="#fff" stroke="#E3CFE0" stroke-width="3"/>
<ellipse cx="128" cy="140" rx="82" ry="68" fill="#fff" stroke="#E3CFE0" stroke-width="3"/>
<ellipse cx="90" cy="150" rx="9" ry="13" fill="#3a2a3f"/><ellipse cx="166" cy="150" rx="9" ry="13" fill="#3a2a3f"/>
<circle cx="86" cy="144" r="4" fill="#fff"/><circle cx="162" cy="144" r="4" fill="#fff"/>
<ellipse cx="70" cy="170" rx="13" ry="8" fill="#FF8FAB" opacity=".6"/><ellipse cx="186" cy="170" rx="13" ry="8" fill="#FF8FAB" opacity=".6"/>
<ellipse cx="128" cy="162" rx="6" ry="4.5" fill="#FF7FA3"/><path d="M128 167 Q118 180 108 172 M128 167 Q138 180 148 172" stroke="#d6547a" stroke-width="3.5" fill="none" stroke-linecap="round"/>
<path d="M128 232 C70 200 78 168 106 172 C118 174 128 186 128 186 C128 186 138 174 150 172 C178 168 186 200 128 232 Z" fill="#FF6F9C" transform="translate(128 232) scale(.6) translate(-128 -190)"/>
<path d="M100 184 Q106 178 114 180" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round" opacity=".7"/>
</svg>
"@ | Set-Content -Encoding UTF8 (Join-Path $out "chibi-bunny.svg")
@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
<path d="M128 228 C40 168 28 92 82 70 C108 60 128 82 128 82 C128 82 148 60 174 70 C228 92 216 168 128 228 Z" fill="#FF8FB6"/>
<path d="M70 96 Q84 76 106 82" stroke="#fff" stroke-width="9" fill="none" stroke-linecap="round" opacity=".6"/>
<g transform="translate(206 66)"><circle r="20" fill="#FFD76A"/><circle cx="0" cy="-26" r="14" fill="#fff"/><circle cx="25" cy="-8" r="14" fill="#fff"/><circle cx="15" cy="21" r="14" fill="#fff"/><circle cx="-15" cy="21" r="14" fill="#fff"/><circle cx="-25" cy="-8" r="14" fill="#fff"/><circle r="12" fill="#FFB300"/></g>
<g transform="translate(46 196)"><path d="M0 -20 L6 -6 L22 -6 L9 4 L14 20 L0 10 L-14 20 L-9 4 L-22 -6 L-6 -6 Z" fill="#7FB8FF"/></g>
</svg>
"@ | Set-Content -Encoding UTF8 (Join-Path $out "chibi-heart.svg")

$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
$dest = Split-Path $out -Parent
foreach ($n in "chibi-girl-pink","chibi-girl-blue","chibi-bunny","chibi-heart") {
  $svg = Join-Path $out "$n.svg"
  $html = Join-Path $out "$n.html"
  "<html><body style='margin:0;background:transparent'><img src='$n.svg' width=256 height=256></body></html>" | Set-Content -Encoding UTF8 $html
  & $edge --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 --window-size=256,256 --screenshot="$dest\$n.png" ("file:///" + $html.Replace('\','/')) | Out-Null
  Start-Sleep -Seconds 1
  Remove-Item $html
}
Get-ChildItem $dest -Filter chibi-*.png | Select Name,Length
