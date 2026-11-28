#!/usr/bin/env python3
"""Draws the BattlePlan mark, All Sports (SPEC §7.1), in every form it ships.

All Sports is the app's B as a tank: a heavy leaning coral B riding a track
whose three wheels are a basketball, a soccer ball and a baseball, its gun
pointing up and to the right, every part in a thick ink edge on a hard ink
shadow, on an Army green tile under a dot grid (the owner's pick, 2026-11-27,
option 25 of the icon options: "let's do #25 instead."). Three balls, because
the app is for every sport. The B and its gun are the app's coral and the
basketball is yellow: option 25 had them yellow and orange, and the owner
asked to see it "if the yellow were coral instead and what was coral was
yellow", then took that ("Go ahead make the change from yellow to coral.").

Run from anywhere; it writes, all on the 1024 grid:

  assets/brand/icon.svg        the app icon: the tank on its square tile
  assets/brand/maskable.svg    the web app's maskable icon: the tank smaller,
                               inside the 80% circle any mask keeps
  assets/brand/foreground.svg  Android's adaptive icon foreground, no tile
                               (the icon tool insets it 16%)
  assets/brand/background.svg  Android's adaptive icon background: the tile
                               alone, drawn at two thirds, since Android
                               shows the middle two thirds of this layer
  assets/brand/monochrome.svg  Android's themed icon: the tank as one shape
  assets/brand/mark.svg        the splash screens' mark, no tile, inside the
                               circle Android 12 keeps
  website/logo.svg             the logo: the tank on no tile, see-through
                               around it, as wide as its square (the
                               website's header mark, the Play feature
                               graphic's and the link preview's)
  website/wordmark.svg         the name beside or under the logo: "BattlePlan"
                               in Lilita One's bubbly letters, white on a
                               navy drop, as Candy Pop's header titles were
  website/favicon.svg          the tank on the rounded tile, an app icon on a
                               page (the landing page; the web app's and the
                               website's 32 px favicon PNGs)
  website/favicon-small.svg    the browser-tab icon, simplified for 16 px:
  web/favicon-small.svg        the B, its gun, the track and the three balls
                               as plain discs, with heavy edges and no shadow
                               or tile
  web/index.html               the web app's loading mark, inline: the logo
                               and the name under it
  lib/core/widgets/brand_mark.dart  BrandMark and BrandWordmark, the logo and
                               the name painted in Flutter from the same
                               shapes (the sign-in screen's)

Only the app icons sit on the tile: Apple refuses an app icon with any
transparency, and Android draws every icon on a background layer. On the tile
the track is black. Off it, the track is the tile's own Army green
(OFF_TILE): the logo is mostly seen on black pages (the website's header, the
splash and loading screens, the sign-in screen in Black), where a black track
in a black edge would not be seen at all, and the owner didn't want a thin
light outline round the mark to show it.

tools/brand_icons.sh then renders the SVGs and makes every icon and splash
size from them. Only the standard library is needed: the B is Kanit Black
Italic's own outline and the name is Lilita One's, both copied in below.
"""
import math
import pathlib
import re
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent

# ---- colors: the app's ink and coral on Army green, and the three balls' own ----
INK = '#0B0B0A'          # every edge, and the hard shadow under the tank
WHITE = '#FFFFFF'        # the shine on the barrel
ARMY = '#4A5327'         # the tile: Army green
GLOW = '#74803C'         # a lighter green behind the tank, GLOW_ALPHA at the tile's
GLOW_ALPHA = 0.85        # centre and gone by GLOW_R of its width
GLOW_R = 0.66
DOT = '#1F2410'          # the tile's dot grid, at DOT_ALPHA
DOT_ALPHA = 0.30
LETTER = ('#FF9480', '#F2644C')            # the B, from its top to its foot: the app's coral (#FF7F66) between them
BARREL = ('#FF9480', '#E9573F')            # the gun's barrel, across it
MUZZLE = '#F2644C'
TRACK, TREAD = '#161612', '#3A3A32'        # on the tile: the track, and the lugs round its inside
OFF_TILE = dict(track='#4A5327', tread='#2F3619')   # off the tile: the track in Army green, darker lugs
# Each ball: its face, its shade, its markings. The basketball is yellow, not a basketball's
# orange, which is too near the B's coral to tell from it at an icon's size.
BASKETBALL = ('#FFDD55', '#EDAE00', '#2A1606')
SOCCER = ('#FFFFFF', '#D9DCE0', '#17181B')
BASEBALL = ('#FFF8EA', '#E6DAC0', '#D92B2B')
NAVY = '#0B1640'         # the name's hard drop, and its edge on a light page

# ---- the B: Kanit Black Italic's glyph (SIL Open Font License 1.1, Cadson Demak), in font ----
# units (1000 per em, y up from the baseline), and the box round it.
B_GLYPH = ('M-21 0L115 644L497 644Q574 644 622.5 604Q671 564 671 499Q671 479 667 462Q657 414 633.5 380Q610 346 578 326'
           'Q605 312 621 291.5Q637 271 637 236Q637 227 635.5 216.5Q634 206 632 195Q613 104 548.5 52Q484 0 365 0Z'
           'M290 397L380 397Q428 397 437 440Q438 444 438 450Q438 480 398 480L308 480Z'
           'M240 164L330 164Q378 164 387 207Q388 210 388 213Q388 216 388 218Q388 247 348 247L258 247Z')
B_BOX = (-21, 0, 671, 644)

# ---- the name: Lilita One's letters for "BattlePlan" (SIL Open Font License 1.1, Juan Montoreano), ----
# the bubbly title font of the Candy Pop scheme's header before Boot Camp Mix (#85): font units, 1000 per
# em, y down from the baseline, each with its advance (Lilita One has no kerning between these letters).
LILITA = {
    'B': (594, 'M541 -519Q541 -415 451 -361Q500 -343 533 -299Q566 -255 566 -174Q566 -94 506 -47Q447 0 336 0L100 0Q83 0 72 -12Q61 -23 61 -42L61 -682Q61 -693 64 -696Q68 -700 79 -700L307 -700Q541 -700 541 -519ZM253 -538L253 -407L258 -407Q354 -407 354 -471Q354 -506 336 -522Q317 -538 274 -538ZM253 -289L253 -159L271 -159Q314 -159 334 -175Q354 -191 354 -226Q354 -261 336 -275Q317 -289 274 -289Z'),
    'a': (517, 'M108 -363Q80 -413 80 -444Q80 -476 97 -485Q154 -510 254 -510Q353 -510 394 -464Q435 -417 435 -326L435 -168L469 -168Q486 -168 496 -148Q505 -128 505 -93Q505 -58 488 -24Q470 10 440 10Q386 10 353 -19Q338 -31 330 -48Q284 10 187 10Q114 10 64 -42Q14 -94 14 -165Q14 -328 209 -328L264 -328L264 -338Q264 -364 256 -372Q247 -379 216 -379Q178 -379 108 -363ZM188 -179Q188 -157 200 -146Q212 -134 230 -134Q249 -134 264 -149L264 -226L236 -226Q188 -226 188 -179Z'),
    't': (368, 'M275 -6Q275 6 191 6Q91 2 91 -7L91 -361L40 -361Q20 -361 20 -430Q20 -448 24 -474Q27 -500 38 -500L91 -500L91 -588Q91 -608 176 -608Q260 -608 260 -592L260 -528L261 -500L346 -500Q363 -500 363 -430Q363 -360 346 -360L275 -360Z'),
    'l': (272, 'M227 -8Q227 1 125 1Q45 0 45 -7L45 -688Q45 -703 142 -703Q227 -700 227 -693Z'),
    'e': (486, 'M423 -27Q360 10 261 10Q162 10 94 -58Q26 -125 26 -244Q26 -364 92 -437Q157 -510 257 -510Q357 -510 412 -459Q466 -408 466 -335Q466 -173 280 -173L211 -173Q211 -143 228 -132Q244 -120 276 -120Q346 -120 409 -152Q410 -153 418 -138Q442 -95 442 -66Q442 -36 423 -27ZM298 -316Q298 -358 257 -358Q238 -358 224 -346Q211 -335 211 -313L211 -282L265 -282Q298 -282 298 -316Z'),
    'p': (555, 'M260 182Q260 189 174 189Q89 189 89 182L89 -333L55 -333Q31 -333 22 -377Q19 -391 19 -413Q19 -435 33 -465Q53 -509 97 -509Q126 -509 150 -496Q175 -482 184 -470Q194 -459 194 -457Q261 -509 339 -509Q417 -509 473 -448Q529 -388 529 -262Q529 -135 473 -66Q417 4 331 4Q292 4 260 0ZM301 -334Q284 -334 268 -323L268 -146Q285 -144 296 -144Q306 -144 312 -144Q353 -148 353 -249Q353 -334 301 -334Z'),
    'P': (570, 'M137 2Q46 2 46 -18L46 -666Q46 -700 77 -700L253 -700Q401 -700 466 -639Q532 -578 532 -462Q532 -366 470 -286Q439 -246 379 -222Q319 -198 239 -198L239 -19Q239 -7 202 -2Q164 2 137 2ZM239 -526L239 -368L252 -368Q287 -368 311 -390Q335 -412 335 -452Q335 -492 318 -509Q302 -526 260 -526Z'),
    'n': (551, 'M254 -6Q254 1 182 1Q82 -2 82 -10L82 -334L56 -334Q30 -334 22 -378Q20 -391 20 -404Q20 -435 32 -466Q50 -510 88 -510Q126 -510 156 -492Q186 -474 196 -456Q259 -510 346 -510Q433 -510 472 -463Q511 -416 511 -309L511 -9Q511 3 426 3Q340 3 340 -9L340 -298Q340 -348 305 -348Q295 -348 277 -340Q259 -331 254 -327Z'),
}
WORD = 'BattlePlan'
WORD_DROP = 70     # the hard drop straight down, 0.07 em, as Candy Pop's header titles had it
WORD_EDGE = 90     # the navy edge (stroke width) the name takes on a light page


def _tokens(d):
    out, num = [], ''
    for ch in d:
        if ch.isalpha():
            if num: out.append(float(num)); num = ''
            out.append(ch)
        elif ch in ' ,':
            if num: out.append(float(num)); num = ''
        elif ch == '-' and num:
            out.append(float(num)); num = ch
        else:
            num += ch
    if num: out.append(float(num))
    return out


def _num(v):
    """A short number for path data: one decimal at most."""
    out = ('%.1f' % v).rstrip('0').rstrip('.')
    return '0' if out in ('-0', '') else out


def b_path(h, cx, cy):
    """The B, h tall, its box centred on (cx, cy), as an absolute M/L/Q/Z path."""
    k = h / (B_BOX[3] - B_BOX[1])
    X = lambda x: _num(cx + (x - (B_BOX[0] + B_BOX[2]) / 2) * k)
    Y = lambda y: _num(cy - (y - (B_BOX[1] + B_BOX[3]) / 2) * k)
    t, i, d = _tokens(B_GLYPH), 0, []
    while i < len(t):
        c = t[i]; i += 1
        if c in 'ML':
            d.append('%s%s %s' % (c, X(t[i]), Y(t[i + 1]))); i += 2
        elif c == 'Q':
            d.append('Q%s %s %s %s' % (X(t[i]), Y(t[i + 1]), X(t[i + 2]), Y(t[i + 3]))); i += 4
        elif c == 'Z':
            d.append('Z')
    return ''.join(d)


def _corners(pts, radii):
    """Each corner of a polygon as (where its curve starts, the corner, where it ends)."""
    out, m = [], len(pts)
    for i in range(m):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % m]

        def toward(a, b, dist):
            length = math.dist(a, b)
            dist = min(dist, length / 2)
            return (a[0] + (b[0] - a[0]) * dist / length, a[1] + (b[1] - a[1]) * dist / length)
        out.append((toward(p1, p0, radii[i]), p1, toward(p1, p2, radii[i])))
    return out


def rounded_polygon(pts, radii):
    """A polygon with each corner rounded by its own radius, as an absolute M/L/Q/Z path."""
    d = ''
    for i, (a, c, b) in enumerate(_corners(pts, radii)):
        d += '%s%s %s' % ('L' if i else 'M', _num(a[0]), _num(a[1]))
        d += 'Q%s %s %s %s' % (_num(c[0]), _num(c[1]), _num(b[0]), _num(b[1]))
    return d + 'Z'


def lugs(pts, radii, on, off, steps=8):
    """Short strokes along a rounded polygon's outline, `on` long with `off` between them, as one
    M/L path: drawn with a wide round-ended stroke and clipped to the polygon, they're the track's
    lugs. (The same as a dashed outline, spelled out, so Flutter can draw it too.)"""
    run = []
    for a, c, b in _corners(pts, radii):
        run.append(a)
        for s in range(1, steps + 1):
            t = s / steps
            run.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
                        (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]))
    run.append(run[0])
    along = [0.0]
    for i in range(1, len(run)):
        along.append(along[-1] + math.dist(run[i - 1], run[i]))

    def at(s):
        i = max(1, min(len(run) - 1, next(j for j in range(1, len(run)) if along[j] >= s)))
        f = (s - along[i - 1]) / ((along[i] - along[i - 1]) or 1)
        return (run[i - 1][0] + (run[i][0] - run[i - 1][0]) * f, run[i - 1][1] + (run[i][1] - run[i - 1][1]) * f)

    d, s = '', 0.0
    while s < along[-1]:
        e = min(s + on, along[-1])
        stroke = [at(s)] + [run[i] for i in range(len(run)) if s < along[i] < e] + [at(e)]
        d += 'M' + 'L'.join('%s %s' % (_num(x), _num(y)) for x, y in stroke)
        s += on + off
    return d


# ---- a tiny display list, so the SVGs and the Dart painter draw the same thing ----
# Shapes: ('rrect', x, y, w, h, r) · ('circle', cx, cy, r) · ('path', d)
# Ops:    ('draw', shape, fill, stroke, width, alpha): the fill, then the stroke over it, centred on
#             the shape's edge with round joins and ends; fill is a color or ('blend', x1, y1, x2, y2,
#             from, to), a color running into another between two points
#         ('push', transforms) · ('pop',): a group; a clip inside one ends with it
#         ('clip', shape) · ('glow', cx, cy, r, color, alpha) and ('dots', step, r, color, alpha),
#             the tile's soft light and its dot grid (SVG only)
# Transforms: ('t', dx, dy) · ('r', degrees, cx, cy) · ('s', k, cx, cy)

def draw(shape, fill=None, stroke=None, width=0, alpha=1.0):
    return ('draw', shape, fill, stroke, width, alpha)


def edged(shape, fill, edge, ink=INK):
    """A part of the tank: its face inside an ink edge `edge` wide all round it."""
    return [draw(shape, ink, ink, 2 * edge), draw(shape, fill)]


# ---- the tank, in the art's own grid: the 1024 tile as the owner picked it ----
B_AT = (500, 452, 446)                    # the B: its height, and its box's centre
TRACK_PTS = [(236, 676), (792, 676), (876, 746), (810, 876), (222, 876), (152, 746)]
TRACK_RADII = [40, 40, 60, 70, 70, 60]
GUN_AT = [('t', 604, 352), ('r', -13, 0, 0)]     # the gun's own frame: out of the B's shoulder, 13 degrees up
BARREL_BOX = ('rrect', 0, -34, 300, 68, 8)
MUZZLE_BOX = ('rrect', 276, -50, 84, 100, 16)
WHEELS = ((306, 778), (514, 778), (722, 778))    # where the three balls sit in the track
WHEEL_R = 68
EDGE = 26                                 # the ink edge round every part
SHADOW = (22, 26)                         # the hard shadow, down and to the right

# What the art covers on the tile, shadow and all (measured from a render), and the smallest circle
# round it: the icons that are cropped to a circle place the art by these.
ART_BOX = (142, 170, 1011, 928)
ART_CIRCLE = (582.5, 544.5, 506)


def _b():
    return ('path', b_path(*B_AT))


def _track():
    return ('path', rounded_polygon(TRACK_PTS, TRACK_RADII))


def _polar(x, y, r, degrees):
    a = math.radians(degrees)
    return (x + r * math.cos(a), y + r * math.sin(a))


def _line(*pts):
    return 'M' + 'L'.join('%s %s' % (_num(px), _num(py)) for px, py in pts)


def ball(x, y, r, colors, turn, marks, edge=12):
    """A ball as a wheel: an ink disc, then, clipped to the ball, its shade, its face a little up and
    to the left of that (so the shade is a crescent at the lower right), and its markings, turned."""
    face, shade, _ = colors
    return ([draw(('circle', x, y, r), INK, INK, edge), ('push', []), ('clip', ('rrect', x - r, y - r, 2 * r, 2 * r, r)),
             draw(('circle', x, y, r), shade), draw(('circle', round(x - r * .09, 1), round(y - r * .10, 1), r), face),
             ('push', [('r', turn, x, y)])] + marks + [('pop',), ('pop',)])


def basketball(x, y, r, turn):
    """A basketball: the two lines across it and the two curved ones either side."""
    col = BASKETBALL[2]
    lines = (_line((x, y - r), (x, y + r)) + _line((x - r, y), (x + r, y))
             + 'M%s %sQ%s %s %s %s' % tuple(_num(v) for v in (x - .66 * r, y - .8 * r, x - .2 * r, y, x - .66 * r, y + .8 * r))
             + 'M%s %sQ%s %s %s %s' % tuple(_num(v) for v in (x + .66 * r, y - .8 * r, x + .2 * r, y, x + .66 * r, y + .8 * r)))
    return ball(x, y, r, BASKETBALL, turn, [draw(('path', lines), None, col, 7)])


def soccer_ball(x, y, r, turn):
    """A soccer ball: a dark pentagon in the middle, a seam out from each of its corners to a dark
    patch at the edge, and a seam from each patch to the next."""
    col = SOCCER[2]
    patches = _line(*[_polar(x, y, .37 * r, -90 + 72 * i) for i in range(5)]) + 'Z'
    seams = ''
    for i in range(5):
        a = -90 + 72 * i
        patches += _line(_polar(x, y, .74 * r, a), _polar(x, y, .88 * r, a + 20), _polar(x, y, 1.25 * r, a + 22),
                         _polar(x, y, 1.25 * r, a - 22), _polar(x, y, .88 * r, a - 20)) + 'Z'
        seams += _line(_polar(x, y, .37 * r, a), _polar(x, y, .74 * r, a))
        seams += _line(_polar(x, y, .88 * r, a + 20), _polar(x, y, .88 * r, a + 52))
    return ball(x, y, r, SOCCER, turn, [draw(('path', patches), col), draw(('path', seams), None, col, 6)])


def _seam(cx, cy, r, side, bulge=.48, ang=38, reach=.82, count=7, lean=38):
    """One seam of a baseball seen face on: an arc near the right (side 1) or left (side -1) edge,
    bowed toward the middle, and the V stitches across it. Returns (the arc, the stitches) as paths."""
    a = math.radians(ang)
    ex, ey, mx = r * math.cos(a), r * math.sin(a), r * bulge
    c = (r * r - mx * mx) / (2 * (ex - mx))          # the seam's own circle: centre (c, 0), radius rs
    rs = c - mx
    a0 = math.atan2(ey, c - ex)
    tick, gap = r * .17, r * .03

    def pt(t):
        th = math.pi + t * a0
        return c + rs * math.cos(th), rs * math.sin(th), th
    arc = _line(*[(cx + side * pt(-1 + 2 * i / 40)[0], cy + pt(-1 + 2 * i / 40)[1]) for i in range(41)])
    stitches = ''
    for i in range(count):
        x, y, th = pt(-reach + 2 * reach * i / (count - 1))
        tx, ty, nx, ny = -math.sin(th), math.cos(th), math.cos(th), math.sin(th)
        for s in (1, -1):
            lean_r = math.radians(lean)
            x1, y1 = x + nx * gap * s, y + ny * gap * s
            x2 = x1 + (nx * s * math.cos(lean_r) - tx * math.sin(lean_r)) * tick
            y2 = y1 + (ny * s * math.cos(lean_r) - ty * math.sin(lean_r)) * tick
            stitches += _line((cx + side * x1, cy + y1), (cx + side * x2, cy + y2))
    return arc, stitches


def baseball(x, y, r, turn):
    """A baseball: its two seams, each with its red stitches."""
    col = BASEBALL[2]
    (arc1, stitches1), (arc2, stitches2) = _seam(x, y, r, 1), _seam(x, y, r, -1)
    return ball(x, y, r, BASEBALL, turn, [draw(('path', arc1 + arc2), None, col, 7), draw(('path', stitches1 + stitches2), None, col, 9)])


def wheels(plain=False):
    """The tank's three wheels, one for each of three sports: a basketball, a soccer ball and a
    baseball. `plain` draws them for 16 px: just each ball's face in a heavy ink edge."""
    (x1, y1), (x2, y2), (x3, y3) = WHEELS
    if plain:
        return [op for (x, y), colors in zip(WHEELS, (BASKETBALL, SOCCER, BASEBALL))
                for op in [draw(('circle', x, y, WHEEL_R), colors[0], INK, 22)]]
    return basketball(x1, y1, WHEEL_R, -24) + soccer_ball(x2, y2, WHEEL_R, 14) + baseball(x3, y3, WHEEL_R, 64)


def tank(edge=EDGE, plain=False, track=TRACK, tread=TREAD):
    """The tank itself: the gun behind, the B, the track over the B's foot, and the wheels. `plain`
    leaves out what a 16 px drawing can't show: the barrel's shine, the lugs and the balls' markings."""
    b, belt = _b(), _track()
    ops = [('push', GUN_AT)]
    ops += edged(BARREL_BOX, ('blend', 0, -34, 0, 34) + BARREL, edge)
    if not plain:
        ops.append(draw(('path', 'M90 -20L260 -20'), None, WHITE, 9, .5))
    ops += edged(MUZZLE_BOX, MUZZLE, edge) + [('pop',)]
    top, foot = B_AT[2] - B_AT[0] / 2, B_AT[2] + B_AT[0] / 2
    ops += edged(b, ('blend', 0, top, 0, foot) + LETTER, edge)
    ops += edged(belt, track, edge)
    if not plain:
        ops += [('push', []), ('clip', belt),
                draw(('path', lugs(TRACK_PTS, TRACK_RADII, 22, 16)), None, tread, 34), ('pop',)]
    return ops + wheels(plain)


def under(color, reach, shift=(0, 0)):
    """The tank's whole outline in one color, `reach` out from every part: shifted, its hard shadow."""
    return [('push', [('t',) + tuple(shift)]), draw(_b(), color, color, 2 * reach), draw(_track(), color, color, 2 * reach),
            ('push', GUN_AT), draw(BARREL_BOX, color, color, 2 * reach), draw(MUZZLE_BOX, color, color, 2 * reach),
            ('pop',), ('pop',)]


def art(**kw):
    """All Sports as it's seen everywhere: the tank in its thick ink edge, on its hard ink shadow."""
    return under(INK, EDGE, SHADOW) + tank(**kw)


def placed(ops, k, centre, to=(512, 512)):
    """The ops scaled by k about `centre`, a point in the art's grid, with that point moved to `to`."""
    return [('push', [('t', to[0] - centre[0], to[1] - centre[1]), ('s', k, centre[0], centre[1])])] + ops + [('pop',)]


def in_circle(ops, r):
    """The art made to fit a circle of radius r about the middle of the 1024 square."""
    return placed(ops, round(r / ART_CIRCLE[2], 4), ART_CIRCLE[:2])


def tile(rounded=False, box=(0, 0, 1024, 1024)):
    """The tile: Army green, a lighter green in the middle, and the dot grid over both."""
    x0, y0, x1, y1 = box
    shape = ('rrect', x0, y0, x1 - x0, y1 - y0, 224 if rounded else 0)
    return [('clip', shape), draw(shape, ARMY), ('glow', 512, 512, round(GLOW_R * 1024, 1), GLOW, GLOW_ALPHA),
            ('dots', 64, 8, DOT, DOT_ALPHA, box)]


def background():
    """Android's adaptive icon background. Android shows only the middle two thirds of this layer
    (72 of its 108 dp; the rest is for the launcher's motion), so it's a tile half as wide again,
    drawn at two thirds: the part that shows is the tile at the icon's own scale, dots and all."""
    return [('clip', ('rrect', 0, 0, 1024, 1024, 0)), ('push', [('s', round(2 / 3, 5), 512, 512)])] + \
        tile(box=(-256, -256, 1280, 1280))[1:] + [('pop',)]


def logo():
    """The logo: the art on no tile, its track in Army green, as wide as the square it's drawn in
    and in its middle."""
    x0, y0, x1, y1 = ART_BOX
    return placed(art(**OFF_TILE), round(1016 / (x1 - x0), 4), ((x0 + x1) / 2, (y0 + y1) / 2))


def favicon_small():
    """For 16 px: the B, its gun, the track and the three balls as plain discs, with heavy edges and
    no shadow, lugs or markings, filling the square."""
    return placed(tank(edge=40, plain=True, **OFF_TILE), 1.17, (571.5, 536))


def monochrome():
    """Android's themed icon: one color. Every face of the tank is kept and every ink edge is cut
    away, so the gun, the B and the track read as three parts, with each ball a disc in a hole
    cut out of the track."""
    cut = '#000000'   # drawn into a mask: black is cut away, white is kept
    m = [('push', GUN_AT), draw(BARREL_BOX, WHITE), draw(MUZZLE_BOX, cut, cut, 2 * EDGE), draw(MUZZLE_BOX, WHITE), ('pop',)]
    m += [draw(_b(), cut, cut, 2 * EDGE), draw(_b(), WHITE)]
    m += [draw(_track(), cut, cut, 2 * EDGE), draw(_track(), WHITE)]
    for x, y in WHEELS:
        m += [draw(('circle', x, y, 66), cut), draw(('circle', x, y, 44), WHITE)]
    return in_circle(m, FOREGROUND_R)


# The circles the cropped icons keep, as radii on the 1024 square, each with a little room to spare:
# a maskable web icon's safe zone is the middle 80% (410); Android's adaptive icon, inset 16% by the
# icon tool, is safe within 460 and shown to 502; Android 12's splash keeps two thirds (341).
MASKABLE_R, FOREGROUND_R, SPLASH_R = 400, 452, 332


def word_path():
    """"BattlePlan" as one path, its pen starting at 0 on the baseline."""
    out, pen = [], 0
    for ch in WORD:
        advance, d = LILITA[ch]
        nums = 0
        for tok in _tokens(d):
            if isinstance(tok, str):
                out.append(tok); nums = 0
            else:
                out.append(('%g' % (tok + pen)) if nums % 2 == 0 else ('%g' % tok))
                out.append(' '); nums += 1
        pen += advance
    return ''.join(out).replace(' M', 'M').replace(' L', 'L').replace(' Q', 'Q').replace(' Z', 'Z').strip()


def word_box():
    """The name's box (x, y, w, h): its letters, the drop under them, and room for the edge."""
    pad = WORD_EDGE // 2
    pen = sum(LILITA[ch][0] for ch in WORD[:-1])
    left = 61                                  # the B's left side
    right = pen + 511                          # the last n's right side
    # 189 is the room the small p's tail took under the baseline (the name was "Battleplan" until
    # #120): kept, so the letters sit where they did beside and under the logo.
    return (left - pad, -703 - pad, right - left + 2 * pad, 703 + 189 + WORD_DROP + 2 * pad)


def wordmark():
    """The name as the logo writes it: white letters on a navy hard drop (no edge: for dark grounds)."""
    d = word_path()
    return [('push', [('t', 0, WORD_DROP)]), draw(('path', d), NAVY), ('pop',)] + [draw(('path', d), WHITE)]


# ---- SVG ----
def _svg_transform(ts):
    out = []
    for t in ts:
        if t[0] == 't': out.append('translate(%g %g)' % t[1:])
        elif t[0] == 'r': out.append('rotate(%g %g %g)' % t[1:])
        elif t[0] == 's': out.append('translate(%g %g) scale(%g) translate(%g %g)' % (t[2], t[3], t[1], -t[2], -t[3]))
    return ' '.join(out)


def _svg_shape(s, attrs):
    if s[0] == 'rrect':
        _, x, y, w, h, r = s
        return '<rect x="%g" y="%g" width="%g" height="%g" rx="%g"%s/>' % (x, y, w, h, r, attrs)
    if s[0] == 'circle':
        return '<circle cx="%g" cy="%g" r="%g"%s/>' % (s[1], s[2], s[3], attrs)
    return '<path d="%s"%s/>' % (s[1], attrs)


def to_svg(ops, prefix, comment, box=(0, 0, 1024, 1024)):
    body, defs, groups = [], [], [0]     # groups: how many <g> each open push holds (the first is the page)
    for op in ops:
        kind = op[0]
        if kind == 'push':
            t = _svg_transform(op[1])
            body.append('<g transform="%s">' % t if t else '<g>'); groups.append(1)
        elif kind == 'pop':
            body += ['</g>'] * groups.pop()
        elif kind == 'clip':
            cid = '%s-clip%s' % (prefix, len([d for d in defs if d.startswith('<clipPath')]) or '')
            defs.append('<clipPath id="%s">%s</clipPath>' % (cid, _svg_shape(op[1], '')))
            body.append('<g clip-path="url(#%s)">' % cid); groups[-1] += 1
        elif kind == 'glow':
            _, cx, cy, r, col, a = op
            gid = '%s-glow' % prefix
            defs.append('<radialGradient id="%s" gradientUnits="userSpaceOnUse" cx="%g" cy="%g" r="%g">'
                        '<stop offset="0" stop-color="%s" stop-opacity="%g"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
                        '</radialGradient>' % (gid, cx, cy, r, col, a, col))
            body.append('<circle cx="%g" cy="%g" r="%g" fill="url(#%s)"/>' % (cx, cy, r, gid))
        elif kind == 'dots':
            _, step, r, col, a, (x0, y0, x1, y1) = op
            pid = '%s-dots' % prefix
            defs.append('<pattern id="%s" width="%g" height="%g" patternUnits="userSpaceOnUse"><circle cx="%g" cy="%g" r="%g" fill="%s" fill-opacity="%g"/></pattern>'
                        % (pid, step, step, step / 2, step / 2, r, col, a))
            body.append('<rect x="%g" y="%g" width="%g" height="%g" fill="url(#%s)"/>' % (x0, y0, x1 - x0, y1 - y0, pid))
        elif kind == 'draw':
            _, shape, fill, stroke, width, alpha = op
            if isinstance(fill, tuple):          # a blend: a linear gradient in the shape's own frame
                gid = '%s-blend%d' % (prefix, len([d for d in defs if d.startswith('<linearGradient')]))
                defs.append('<linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="%g" y1="%g" x2="%g" y2="%g">'
                            '<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
                            % ((gid,) + fill[1:]))
                fill = 'url(#%s)' % gid
            a = ' fill="%s"' % (fill or 'none')
            if alpha != 1.0 and fill: a += ' fill-opacity="%g"' % alpha
            if stroke:
                a += ' stroke="%s" stroke-width="%g" stroke-linejoin="round" stroke-linecap="round"' % (stroke, width)
                if alpha != 1.0: a += ' stroke-opacity="%g"' % alpha
            body.append(_svg_shape(shape, a))
    body += ['</g>'] * groups.pop()
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%g %g %g %g" width="%g" height="%g">\n' % (box + box[2:])
            + '<!-- %s Made by tools/make_brand.py. -->\n' % comment
            + ('<defs>%s</defs>\n' % ''.join(defs) if defs else '') + '\n'.join(body) + '\n</svg>\n')


def mono_svg():
    """The themed icon as a white shape: the monochrome ops drawn into a mask over a white square."""
    inner = to_svg(monochrome(), 'bp-mono', '').split('\n')
    shapes = '\n'.join(l for l in inner if l and not l.startswith(('<svg', '<!--', '</svg', '<defs')))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">\n'
            '<!-- BattlePlan\'s themed Android icon: the tank as one shape. Made by tools/make_brand.py. -->\n'
            '<defs><mask id="bp-mono-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">\n'
            + shapes + '\n</mask></defs>\n<rect width="1024" height="1024" fill="#FFFFFF" mask="url(#bp-mono-mask)"/>\n</svg>\n')


# ---- Dart ----
def _hex(c, a=1.0):
    c = c.lstrip('#')
    return '0x%02X%s' % (round(a * 255), c.upper())


def to_dart(ops):
    """The painter's body: one cascade on the canvas, one step per op, in the SVG's order."""
    lines, paths = [], {}

    def path_name(d):
        assert 'C' not in d, 'the painter draws only M, L, Q and Z'
        return paths.setdefault(d, '_p%d' % len(paths))

    for op in ops:
        kind = op[0]
        if kind == 'push':
            lines.append('..save()')
            for t in op[1]:
                if t[0] == 't': lines.append('..translate(%g, %g)' % t[1:])
                elif t[0] == 'r': lines.append('..rotateAbout(%g, %g, %g)' % t[1:])
                elif t[0] == 's': lines.append('..scaleAbout(%g, %g, %g)' % t[1:])
        elif kind == 'pop':
            lines.append('..restore()')
        elif kind == 'clip':
            if op[1][0] == 'rrect':
                lines.append('..clipRRect(_rrect(%g, %g, %g, %g, %g))' % op[1][1:])
            else:
                lines.append('..clipPath(%s)' % path_name(op[1][1]))
        elif kind == 'draw':
            _, shape, fill, stroke, width, alpha = op
            if shape[0] == 'path':
                call = '..drawPath(%s, %%s)' % path_name(shape[1])
            elif shape[0] == 'rrect':
                call = '..drawRRect(_rrect(%g, %g, %g, %g, %g), %%s)' % shape[1:]
            else:
                call = '..drawCircle(const Offset(%g, %g), %g, %%s)' % shape[1:]
            if isinstance(fill, tuple):
                lines.append(call % ('_blend(const Offset(%g, %g), const Offset(%g, %g), const Color(%s), const Color(%s))'
                                     % (fill[1:5] + (_hex(fill[5]), _hex(fill[6])))))
            elif fill:
                lines.append(call % ('_fill(const Color(%s))' % _hex(fill, alpha)))
            if stroke:
                lines.append(call % ('_stroke(const Color(%s), %g)' % (_hex(stroke, alpha), width)))
        else:
            raise ValueError('the painter has no %s' % kind)
    return lines, paths


DART_HEAD = """// Made by tools/make_brand.py from the same shapes as website/logo.svg;
// change the mark there and run it again rather than editing this file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// The BattlePlan mark (SPEC §7.1), All Sports: the app's B as a tank, a
/// heavy leaning coral B on a track whose three wheels are a basketball, a
/// soccer ball and a baseball, its gun up and to the right, every part in a
/// thick ink edge on a hard ink shadow, on no tile: the page shows around it,
/// so the track is Army green here (it's black on the app icon's green tile),
/// to be seen on a black page. The same art as `website/logo.svg`, painted
/// from its shapes so it's sharp at any size and needs no image to load.
/// Decorative: screen readers skip it, as the app's name is always written
/// next to it.
class BrandMark extends StatelessWidget {
  const new({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  const new();

  // The art is drawn in the SVGs' 1024 coordinates.
  static const _tile = 1024.0;
"""

DART_TAIL = """
  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

/// A rounded rectangle from the SVG's x, y, width, height and corner radius.
RRect _rrect(double x, double y, double w, double h, double r) =>
    RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r));

Paint _fill(Color color) => Paint()..color = color;

/// A fill that runs from one color at [from] into another at [to], as the
/// SVGs' linear gradients do: the B from its top to its foot, the barrel
/// across it.
Paint _blend(Offset from, Offset to, Color first, Color last) =>
    Paint()..shader = ui.Gradient.linear(from, to, [first, last]);

/// An outline centred on the shape's edge, with round joins and round ends
/// like the SVGs'.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// The SVGs' transforms, so the painter is one cascade.
extension on Canvas {
  /// SVG's rotate(degrees cx cy).
  void rotateAbout(double degrees, double cx, double cy) => this
    ..translate(cx, cy)
    ..rotate(degrees * math.pi / 180)
    ..translate(-cx, -cy);

  /// Scales by k about (cx, cy).
  void scaleAbout(double k, double cx, double cy) => this
    ..translate(cx, cy)
    ..scale(k)
    ..translate(-cx, -cy);
}

/// A path from SVG path data with absolute M, L, Q and Z commands only, which
/// is all the mark uses.
Path _svgPath(String d) {
  final path = Path();
  final tokens = RegExp('[MLQZ]|-?[0-9.]+').allMatches(d).map((m) => m[0]!);
  final it = tokens.iterator;
  double next() {
    it.moveNext();
    return double.parse(it.current);
  }

  while (it.moveNext()) {
    switch (it.current) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'Q':
        path.quadraticBezierTo(next(), next(), next(), next());
      case 'Z':
        path.close();
    }
  }
  return path;
}
"""


WORD_DART = """
/// The app's name as the logo writes it (SPEC §7.1): "BattlePlan" in Lilita
/// One's bubbly letters, white on a navy hard drop straight down, the look of
/// the Candy Pop scheme's header titles. [outlined] gives the letters a navy
/// edge as well, for a light page. Painted from the same outlines as
/// `website/wordmark.svg`; screen readers hear [label].
class BrandWordmark extends StatelessWidget {
  const new({
    required this.label,
    this.height = 44,
    this.outlined = false,
    super.key,
  });

  final String label;

  /// The box's height: the letters' cap height is two thirds of it.
  final double height;

  final bool outlined;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: CustomPaint(
      size: Size(height * _WordmarkPainter.aspect, height),
      painter: _WordmarkPainter(outlined: outlined),
    ),
  );
}

class _WordmarkPainter extends CustomPainter {
  const new({required this.outlined});

  final bool outlined;

  /// The box round the letters, their drop and their edge, in font units.
  static const _box = Rect.fromLTWH(%(x)g, %(y)g, %(w)g, %(h)g);

  static double get aspect => _box.width / _box.height;

  static final Path _letters = _svgPath(
    '%(d)s',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final drop = _letters.shift(const Offset(0, %(drop)g));
    canvas
      ..save()
      ..scale(size.width / _box.width, size.height / _box.height)
      ..translate(-_box.left, -_box.top);
    if (outlined) {
      canvas
        ..drawPath(drop, _stroke(const Color(%(ink)s), %(edge)g))
        ..drawPath(_letters, _stroke(const Color(%(ink)s), %(edge)g));
    }
    canvas
      ..drawPath(drop, _fill(const Color(%(ink)s)))
      ..drawPath(_letters, _fill(const Color(%(white)s)))
      ..restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.outlined != outlined;
}
"""


def write_dart(ops):
    lines, paths = to_dart(ops)
    out = [DART_HEAD]
    for d, name in paths.items():
        out.append("  static final Path %s = _svgPath(\n    '%s',\n  );\n" % (name, d))
    out.append("""
  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)""")
    out += ['      %s' % l for l in lines]
    out.append('      ..restore();\n  }\n')
    out.append(DART_TAIL)
    x, y, w, h = word_box()
    out.append(WORD_DART % dict(x=x, y=y, w=w, h=h, d=word_path(), drop=WORD_DROP, edge=WORD_EDGE,
                                ink=_hex(NAVY), white=_hex(WHITE)))
    dart = ROOT / 'lib/core/widgets/brand_mark.dart'
    dart.write_text('\n'.join(out))
    # CI checks the formatting; format it the way dart format would, when Dart is here.
    if shutil.which('dart'):
        subprocess.run(['dart', 'format', str(dart)], check=False, capture_output=True)


def main():
    files = {
        'assets/brand/icon.svg': (tile() + art(), 'bp-icon', "BattlePlan's app icon, All Sports on its square tile."),
        'assets/brand/maskable.svg': (tile() + in_circle(art(), MASKABLE_R), 'bp-mask',
                                      "BattlePlan's maskable web icon: All Sports inside the 80% circle."),
        'assets/brand/foreground.svg': (in_circle(art(), FOREGROUND_R), 'bp-fg',
                                        "BattlePlan's adaptive Android icon foreground, on no tile."),
        'assets/brand/background.svg': (background(), 'bp-bg',
                                        "BattlePlan's adaptive Android icon background: the tile, at two thirds."),
        'assets/brand/mark.svg': (in_circle(art(**OFF_TILE), SPLASH_R), 'bp-mark',
                                  "BattlePlan's splash mark: All Sports on no tile, inside Android 12's circle."),
        'website/logo.svg': (logo(), 'bp-logo', "BattlePlan's logo, All Sports, on no tile."),
        'website/wordmark.svg': (wordmark(), 'bp-word', "BattlePlan's name as the logo writes it, in Lilita One (OFL).", word_box()),
        'website/favicon.svg': (tile(True) + art(), 'bp-fav', "BattlePlan's mark, All Sports, on its rounded tile."),
        'website/favicon-small.svg': (favicon_small(), 'bp-small', "BattlePlan's browser-tab icon, drawn for 16 px."),
        'web/favicon-small.svg': (favicon_small(), 'bp-small', "BattlePlan's browser-tab icon, drawn for 16 px."),
    }
    for path, (ops, prefix, comment, *box) in files.items():
        (ROOT / path).write_text(to_svg(ops, prefix, comment, *box))
    (ROOT / 'assets/brand/monochrome.svg').write_text(mono_svg())
    # The web app's loading screen draws the logo inline, so it shows before anything loads.
    inline = to_svg(logo(), 'bp-splash', '').split('\n', 2)[2].rstrip('\n')
    inline = '<svg class="mark" viewBox="0 0 1024 1024" aria-hidden="true">' + inline
    # ...and the name under it, as the logo writes it.
    x, y, w, h = word_box()
    name = to_svg(wordmark(), 'bp-splash-word', '', word_box()).split('\n', 2)[2].rstrip('\n')
    inline += '<svg class="name" viewBox="%g %g %g %g" aria-hidden="true">' % (x, y, w, h) + name
    index = ROOT / 'web/index.html'
    html, n = re.subn(r'<svg class="mark".*?</svg>(?:<svg class="name".*?</svg>|BattlePlan)', lambda m: inline,
                      index.read_text(), count=1, flags=re.S)
    assert n == 1, 'web/index.html has no <svg class="mark"> and name to replace'
    index.write_text(html)
    write_dart(logo())


if __name__ == '__main__':
    main()
