$out = $PSScriptRoot
$dest = Split-Path $out -Parent

# Bo mau: p = hong (nu), b = xanh (nam). Cung hinh ve, khac mau & kieu toc.
$pal = @{
    p = @{ hair = '#FFB3CF'; hairD = '#FF8FB6'; outfit = '#FF8FB6'; outfit2 = '#FFD1E3'; acc = '#7FB8FF'; eye = '#E8559A'; cheek = '#FF8FAB' }
    b = @{ hair = '#5B8FE6'; hairD = '#3B63B5'; outfit = '#7FB8FF'; outfit2 = '#DCECFF'; acc = '#FF8FB6'; eye = '#2F5FBF'; cheek = '#9CC4FF' }
}

function Eyes($kind, $c) {
    switch ($kind) {
        'tired' {
            return @"
<circle cx="96" cy="130" r="15" fill="#fff" stroke="#3a2a3f" stroke-width="4"/><circle cx="160" cy="130" r="15" fill="#fff" stroke="#3a2a3f" stroke-width="4"/>
<path d="M96 130 m-8 0 a8 8 0 1 1 8 8 a4 4 0 1 1 -4 -4" stroke="#3a2a3f" stroke-width="3" fill="none"/><path d="M160 130 m-8 0 a8 8 0 1 1 8 8 a4 4 0 1 1 -4 -4" stroke="#3a2a3f" stroke-width="3" fill="none"/>
<path d="M112 164 q8 -9 16 0 q8 9 16 0" stroke="#d6547a" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M206 96 q-10 16 0 24 q10 -8 0 -24 z" fill="#8FD0FF"/>
"@
        }
        'shock' {
            return @"
<ellipse cx="96" cy="128" rx="16" ry="21" fill="#fff" stroke="#3a2a3f" stroke-width="4"/><ellipse cx="160" cy="128" rx="16" ry="21" fill="#fff" stroke="#3a2a3f" stroke-width="4"/>
<circle cx="96" cy="130" r="6" fill="#3a2a3f"/><circle cx="160" cy="130" r="6" fill="#3a2a3f"/>
<ellipse cx="128" cy="166" rx="9" ry="12" fill="#d6547a"/>
<text x="204" y="56" font-size="40" font-weight="900" fill="#FF4D6D">!</text>
"@
        }
        'wink' {
            return @"
<ellipse cx="96" cy="128" rx="14" ry="19" fill="#3a2a3f"/><ellipse cx="96" cy="132" rx="10" ry="14" fill="$($c.eye)"/><circle cx="91" cy="121" r="6" fill="#fff"/><circle cx="101" cy="137" r="3" fill="#fff"/>
<path d="M144 130 Q160 116 176 130" stroke="#3a2a3f" stroke-width="6" fill="none" stroke-linecap="round"/>
<path d="M116 156 Q128 170 140 156" stroke="#d6547a" stroke-width="4" fill="#ff9db5" stroke-linecap="round" stroke-linejoin="round"/>
"@
        }
        default {
            $g = ''
            if ($kind -eq 'glasses') { $g = '<circle cx="96" cy="128" r="23" fill="#fff" fill-opacity=".25" stroke="#3a2a3f" stroke-width="4"/><circle cx="160" cy="128" r="23" fill="#fff" fill-opacity=".25" stroke="#3a2a3f" stroke-width="4"/><path d="M119 128 H137" stroke="#3a2a3f" stroke-width="4"/>' }
            return @"
<ellipse cx="96" cy="128" rx="14" ry="19" fill="#3a2a3f"/><ellipse cx="160" cy="128" rx="14" ry="19" fill="#3a2a3f"/>
<ellipse cx="96" cy="132" rx="10" ry="14" fill="$($c.eye)"/><ellipse cx="160" cy="132" rx="10" ry="14" fill="$($c.eye)"/>
<circle cx="91" cy="121" r="6" fill="#fff"/><circle cx="155" cy="121" r="6" fill="#fff"/><circle cx="101" cy="137" r="3" fill="#fff"/><circle cx="165" cy="137" r="3" fill="#fff"/>
<path d="M118 156 Q128 168 138 156" stroke="#d6547a" stroke-width="4" fill="#ff9db5" stroke-linecap="round" stroke-linejoin="round"/>
$g
"@
        }
    }
}

function Prop($kind, $c) {
    $a = $c.acc
    switch ($kind) {
        'camera' { return "<g transform='translate(150 176)'><rect width='70' height='46' rx='9' fill='#555'/><rect x='8' y='-8' width='22' height='10' rx='3' fill='#555'/><circle cx='35' cy='24' r='15' fill='#9bd' stroke='#fff' stroke-width='4'/><circle cx='35' cy='24' r='7' fill='#357'/></g>" }
        'rocket' { return "<g transform='translate(178 160) rotate(28)'><path d='M0 0 Q14 -26 28 0 L28 40 L0 40 Z' fill='#fff' stroke='#c9c9d6' stroke-width='3'/><circle cx='14' cy='14' r='7' fill='$a'/><path d='M0 28 L-12 46 L0 40 Z M28 28 L40 46 L28 40 Z' fill='$a'/><path d='M6 44 Q14 66 22 44 Z' fill='#FFB300'/></g>" }
        'plug' { return "<g transform='translate(160 176)'><rect x='0' y='12' width='46' height='30' rx='8' fill='#555'/><rect x='10' y='0' width='7' height='16' fill='#aaa'/><rect x='29' y='0' width='7' height='16' fill='#aaa'/><path d='M23 42 Q23 64 44 64' stroke='#555' stroke-width='6' fill='none'/></g>" }
        'loupe' { return "<g transform='translate(150 168)'><circle cx='26' cy='26' r='24' fill='#E6F3FF' fill-opacity='.8' stroke='$a' stroke-width='7'/><path d='M44 46 L68 72' stroke='$a' stroke-width='9' stroke-linecap='round'/></g>" }
        'book' { return "<g transform='translate(144 186)'><rect width='76' height='52' rx='5' fill='$a'/><rect x='6' y='6' width='64' height='40' rx='3' fill='#fff'/><path d='M38 6 V46' stroke='#ccd' stroke-width='3'/><path d='M12 16 H32 M12 26 H32 M44 16 H64 M44 26 H64' stroke='#dde' stroke-width='3'/></g>" }
        'laptop' { return "<g transform='translate(140 184)'><rect x='8' width='64' height='40' rx='5' fill='#556'/><rect x='13' y='5' width='54' height='30' rx='3' fill='#CFE8FF'/><text x='40' y='28' font-size='20' text-anchor='middle' fill='$a'>&#10022;</text><path d='M0 44 H80 L74 54 H6 Z' fill='#99a'/></g>" }
        'check' { return "<g transform='translate(152 178)'><rect width='56' height='66' rx='7' fill='#fff' stroke='$a' stroke-width='4'/><rect x='16' y='-5' width='24' height='12' rx='4' fill='$a'/><path d='M14 32 L24 42 L42 22' stroke='#3CB371' stroke-width='7' fill='none' stroke-linecap='round' stroke-linejoin='round'/></g>" }
        'box' { return "<g transform='translate(150 182)'><rect width='66' height='56' rx='5' fill='#E8B77A'/><rect width='66' height='16' fill='#D9A25E'/><rect x='27' width='12' height='56' fill='$a'/></g>" }
        'timer' { return "<g transform='translate(160 178)'><circle cx='30' cy='34' r='26' fill='#fff' stroke='$a' stroke-width='6'/><rect x='24' y='0' width='12' height='9' fill='$a'/><path d='M30 34 V18 M30 34 L42 40' stroke='#555' stroke-width='5' stroke-linecap='round'/></g>" }
        'heart' { return "<text x='176' y='222' font-size='46' fill='#FF6F9C'>&#10084;</text>" }
        default { return '' }
    }
}

function Chibi($sex, $style, $scn, $expr, $prop) {
    $c = $pal[$sex]
    $hair = $c.hair; $hd = $c.hairD
    $back = ''; $front = ''; $acc = ''; $body = ''
    if ($sex -eq 'p') {
        if ($style -eq 1) {
            $back = "<ellipse cx='48' cy='150' rx='26' ry='52' fill='$hair' transform='rotate(14 48 150)'/><ellipse cx='208' cy='150' rx='26' ry='52' fill='$hair' transform='rotate(-14 208 150)'/><circle cx='40' cy='198' r='9' fill='$hd'/><circle cx='216' cy='198' r='9' fill='$hd'/><ellipse cx='128' cy='104' rx='84' ry='80' fill='$hair'/>"
            $acc = "<g transform='translate(176 52)'><path d='M0 0 L-30 -18 Q-40 0 -30 18 Z' fill='$($c.acc)'/><path d='M0 0 L30 -18 Q40 0 30 18 Z' fill='$($c.acc)'/><circle r='9' fill='#fff' opacity='.9'/></g>"
        } else {
            $back = "<circle cx='128' cy='30' r='28' fill='$hair'/><circle cx='128' cy='30' r='12' fill='$hd' opacity='.5'/><ellipse cx='128' cy='108' rx='84' ry='78' fill='$hair'/><ellipse cx='52' cy='150' rx='16' ry='34' fill='$hair'/><ellipse cx='204' cy='150' rx='16' ry='34' fill='$hair'/>"
            $acc = "<g transform='translate(128 62)'><path d='M0 0 L-24 -14 Q-32 0 -24 14 Z' fill='$($c.acc)'/><path d='M0 0 L24 -14 Q32 0 24 14 Z' fill='$($c.acc)'/><circle r='7' fill='#fff'/></g>"
        }
        $front = "<path d='M54 110 Q60 44 128 40 Q196 44 202 110 Q186 84 168 78 Q150 96 128 82 Q104 98 86 78 Q68 84 54 110 Z' fill='$hair'/><path d='M60 100 Q70 62 100 52' stroke='#fff' stroke-width='5' fill='none' opacity='.45' stroke-linecap='round'/>"
        $body = "<path d='M82 196 Q128 182 174 196 L190 244 Q128 254 66 244 Z' fill='$($c.outfit)'/><path d='M104 198 Q128 212 152 198 L146 190 Q128 200 110 190 Z' fill='#fff'/>"
    } else {
        if ($style -eq 1) {
            $back = "<ellipse cx='128' cy='100' rx='80' ry='72' fill='$hair'/>"
            $front = "<path d='M50 120 Q46 46 128 38 Q210 46 206 120 Q192 82 174 90 L162 56 L146 88 L128 50 L112 88 L96 56 L84 90 Q64 84 50 120 Z' fill='$hair'/><path d='M62 104 Q72 66 100 56' stroke='#fff' stroke-width='5' fill='none' opacity='.4' stroke-linecap='round'/>"
        } else {
            $back = "<ellipse cx='128' cy='102' rx='80' ry='74' fill='$hair'/>"
            $front = "<path d='M52 118 Q52 44 130 40 Q206 44 204 118 Q182 70 122 84 Q82 92 52 118 Z' fill='$hair'/><path d='M126 44 Q116 12 150 10' stroke='$hair' stroke-width='7' fill='none' stroke-linecap='round'/><path d='M62 102 Q74 64 102 56' stroke='#fff' stroke-width='5' fill='none' opacity='.4' stroke-linecap='round'/>"
        }
        $acc = "<path d='M60 92 Q128 70 196 92' stroke='$($c.acc)' stroke-width='9' fill='none' stroke-linecap='round'/>"
        $body = "<path d='M82 196 Q128 182 174 196 L190 244 Q128 254 66 244 Z' fill='$($c.outfit)'/><path d='M104 196 L128 218 L152 196 L140 188 L128 198 L116 188 Z' fill='#fff'/><path d='M122 214 L134 214 L138 242 L128 248 L118 242 Z' fill='$($c.acc)'/>"
    }
    $eyes = Eyes $expr $c
    $pr = Prop $prop $c
    @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
<ellipse cx="128" cy="249" rx="62" ry="6" fill="#000" opacity=".08"/>
$back
$body
<circle cx="76" cy="212" r="12" fill="#FFE4D6"/><circle cx="180" cy="212" r="12" fill="#FFE4D6"/>
<ellipse cx="128" cy="124" rx="72" ry="66" fill="#FFE9DC"/>
$front
$acc
$eyes
<ellipse cx="74" cy="154" rx="14" ry="8" fill="$($c.cheek)" opacity=".55"/><ellipse cx="182" cy="154" rx="14" ry="8" fill="$($c.cheek)" opacity=".55"/>
$pr
</svg>
"@
}

$defs = @(
    @('hero1', 1, 'normal', 'heart'), @('hero2', 2, 'wink', ''),
    @('tired', 1, 'tired', ''), @('alarm', 2, 'shock', ''), @('camera', 1, 'wink', 'camera'), @('rocket', 2, 'normal', 'rocket'),
    @('plug', 1, 'normal', 'plug'), @('loupe', 2, 'glasses', 'loupe'), @('book', 1, 'glasses', 'book'), @('laptop', 2, 'normal', 'laptop'),
    @('check', 1, 'glasses', 'check'), @('box', 2, 'wink', 'box'), @('timer', 1, 'shock', 'timer')
)
$cur = @{ p = '#C2185B'; b = '#1E40AF' }
foreach ($s in 'p', 'b') {
    foreach ($d in $defs) {
        (Chibi $s $d[1] $d[0] $d[2] $d[3]) | Set-Content -Encoding UTF8 (Join-Path $out "chibi-$s-$($d[0]).svg")
    }
    @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40" width="40" height="40">
<path d="M5 3 L5 30 L12 24 L17 36 L23 34 L18 22 L28 22 Z" fill="$($cur[$s])" stroke="#fff" stroke-width="2.5" stroke-linejoin="round"/>
<circle cx="10.5" cy="14" r="1.6" fill="#fff"/><circle cx="15" cy="14" r="1.6" fill="#fff"/><path d="M10 18 Q12.7 21 15.5 18" stroke="#fff" stroke-width="1.5" fill="none" stroke-linecap="round"/>
<circle cx="8.5" cy="17" r="1.4" fill="#FF8FAB" opacity=".8"/><circle cx="17" cy="17" r="1.4" fill="#FF8FAB" opacity=".8"/>
</svg>
"@ | Set-Content -Encoding UTF8 (Join-Path $out "cursor-$s.svg")
}

$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
$names = @()
foreach ($s in 'p', 'b') { foreach ($d in $defs) { $names += , @("chibi-$s-$($d[0])", 256) }; $names += , @("cursor-$s", 40) }
foreach ($n in $names) {
    $sz = $n[1]
    $html = Join-Path $out "$($n[0]).html"
    "<html><body style='margin:0;background:transparent'><img src='$($n[0]).svg' width=$sz height=$sz></body></html>" | Set-Content -Encoding UTF8 $html
    & $edge --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 "--window-size=$sz,$sz" "--screenshot=$dest\$($n[0]).png" ("file:///" + $html.Replace('\', '/')) | Out-Null
    Start-Sleep -Milliseconds 700
    Remove-Item $html
}
(Get-ChildItem $dest -Filter 'chibi-?-*.png').Count
(Get-ChildItem $dest -Filter 'cursor-*.png').Count
