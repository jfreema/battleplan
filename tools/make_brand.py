#!/usr/bin/env python3
"""Draws the Battleplan mark, the Sticker Pair (SPEC §7.1), in every form it ships.

The Sticker Pair is two candy dog tags on a white ball chain, each a die-cut
sticker with a thick white border in a navy edge: a yellow tag in front with
the white stencil B, and a coral one swung out behind it, with two twinkles,
on Candy Pop's royal blue under a dot grid (the owner's pick, 2026-11-24:
"Go ahead and replace the current icon and logo with 2E.").

Run from anywhere; it writes, all on the 1024 grid:

  assets/brand/icon.svg        the app icon: the art on its square blue tile
  assets/brand/maskable.svg    the web app's maskable icon: the art smaller,
                               inside the 80% circle any mask keeps
  assets/brand/foreground.svg  Android's adaptive icon foreground, no tile
                               (the icon tool insets it 16%; its background
                               is pubspec.yaml's adaptive_icon_background)
  assets/brand/monochrome.svg  Android's themed icon: the pair as one shape
  assets/brand/mark.svg        the splash screens' mark, no tile, inside the
                               circle Android 12 keeps, on a short chain
  website/logo.svg             the logo: the art on no tile, see-through
                               around it, its chain running off the top (the
                               website's header mark, the Play feature
                               graphic's and the link preview's)
  website/wordmark.svg         the name beside or under the logo: "Battleplan"
                               in Lilita One's bubbly letters, white on a
                               navy drop, as Candy Pop's header titles were
  website/favicon.svg          the art on the rounded tile, an app icon on a
                               page (the landing page; the web app's and the
                               website's 32 px favicon PNGs)
  website/favicon-small.svg    the browser-tab icon, simplified for 16 px:
  web/favicon-small.svg        the two tags and the B, no chain or tile
  web/index.html               the web app's loading mark, inline: the logo
                               and the name under it
  lib/core/widgets/brand_mark.dart  BrandMark and BrandWordmark, the logo and
                               the name painted in Flutter from the same
                               shapes (the sign-in screen's)

Only the app icons sit on the blue tile: Apple refuses an app icon with any
transparency, and Android draws every icon on a solid background layer.

tools/brand_icons.sh then renders the SVGs and makes every icon and splash
size from them. Only the standard library is needed: the B is Battleplan
Stencil's own outline (assets/fonts/battleplan_stencil), copied in below.
"""
import math
import pathlib
import re
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent

# ---- colors: Candy Pop's (CampPalette.candyPop before #90) plus the app's coral ----
INK = '#0B1640'          # every edge, the B's outline and the hard shadows
BLUE = '#1748D4'         # the tile
DOT = '#FFFFFF'          # the tile's dot grid, at DOT_ALPHA
DOT_ALPHA = 0.14
WHITE = '#FFFFFF'        # sticker borders, the B, the chain's beads
YELLOW, YELLOW_RIM = '#FFD43A', '#E0A800'
CORAL, CORAL_RIM = '#FF7F66', '#D9533B'
SHINE_ALPHA = 0.75

# ---- the B: Battleplan Stencil's glyph, in font units (2000 per em, cap 1600, advance 985) ----
B_GLYPH = ('M80 0V1600H380V0ZM480 0V264H490Q553 264 586.5 297.5Q620 331 620 394Q620 421 620.0 447.0Q620 473 620 500'
           'Q620 599 589.5 640.5Q559 682 490 682H480V946H490Q553 946 586.5 989.5Q620 1033 620 1112Q620 1141 620.0 1169.5'
           'Q620 1198 620 1226Q620 1279 586.5 1307.5Q553 1336 490 1336H480V1600H490Q714 1600 817.0 1509.5Q920 1419 920 1210'
           'Q920 1182 920.0 1156.0Q920 1130 918 1104Q912 995 869.5 930.5Q827 866 738 836V788Q830 758 873.0 692.5'
           'Q916 627 920 514Q922 481 922.0 453.0Q922 425 920 390Q911 182 812.5 91.0Q714 0 490 0Z')
B_CAP, B_ADVANCE = 1600, 985

# ---- the name: Lilita One's letters for "Battleplan" (SIL Open Font License 1.1, Juan Montoreano), ----
# the bubbly title font of the Candy Pop scheme's header before Boot Camp Mix (#85): font units, 1000 per
# em, y down from the baseline, each with its advance (Lilita One has no kerning between these letters).
LILITA = {
    'B': (594, 'M541 -519Q541 -415 451 -361Q500 -343 533 -299Q566 -255 566 -174Q566 -94 506 -47Q447 0 336 0L100 0Q83 0 72 -12Q61 -23 61 -42L61 -682Q61 -693 64 -696Q68 -700 79 -700L307 -700Q541 -700 541 -519ZM253 -538L253 -407L258 -407Q354 -407 354 -471Q354 -506 336 -522Q317 -538 274 -538ZM253 -289L253 -159L271 -159Q314 -159 334 -175Q354 -191 354 -226Q354 -261 336 -275Q317 -289 274 -289Z'),
    'a': (517, 'M108 -363Q80 -413 80 -444Q80 -476 97 -485Q154 -510 254 -510Q353 -510 394 -464Q435 -417 435 -326L435 -168L469 -168Q486 -168 496 -148Q505 -128 505 -93Q505 -58 488 -24Q470 10 440 10Q386 10 353 -19Q338 -31 330 -48Q284 10 187 10Q114 10 64 -42Q14 -94 14 -165Q14 -328 209 -328L264 -328L264 -338Q264 -364 256 -372Q247 -379 216 -379Q178 -379 108 -363ZM188 -179Q188 -157 200 -146Q212 -134 230 -134Q249 -134 264 -149L264 -226L236 -226Q188 -226 188 -179Z'),
    't': (368, 'M275 -6Q275 6 191 6Q91 2 91 -7L91 -361L40 -361Q20 -361 20 -430Q20 -448 24 -474Q27 -500 38 -500L91 -500L91 -588Q91 -608 176 -608Q260 -608 260 -592L260 -528L261 -500L346 -500Q363 -500 363 -430Q363 -360 346 -360L275 -360Z'),
    'l': (272, 'M227 -8Q227 1 125 1Q45 0 45 -7L45 -688Q45 -703 142 -703Q227 -700 227 -693Z'),
    'e': (486, 'M423 -27Q360 10 261 10Q162 10 94 -58Q26 -125 26 -244Q26 -364 92 -437Q157 -510 257 -510Q357 -510 412 -459Q466 -408 466 -335Q466 -173 280 -173L211 -173Q211 -143 228 -132Q244 -120 276 -120Q346 -120 409 -152Q410 -153 418 -138Q442 -95 442 -66Q442 -36 423 -27ZM298 -316Q298 -358 257 -358Q238 -358 224 -346Q211 -335 211 -313L211 -282L265 -282Q298 -282 298 -316Z'),
    'p': (555, 'M260 182Q260 189 174 189Q89 189 89 182L89 -333L55 -333Q31 -333 22 -377Q19 -391 19 -413Q19 -435 33 -465Q53 -509 97 -509Q126 -509 150 -496Q175 -482 184 -470Q194 -459 194 -457Q261 -509 339 -509Q417 -509 473 -448Q529 -388 529 -262Q529 -135 473 -66Q417 4 331 4Q292 4 260 0ZM301 -334Q284 -334 268 -323L268 -146Q285 -144 296 -144Q306 -144 312 -144Q353 -148 353 -249Q353 -334 301 -334Z'),
    'n': (551, 'M254 -6Q254 1 182 1Q82 -2 82 -10L82 -334L56 -334Q30 -334 22 -378Q20 -391 20 -404Q20 -435 32 -466Q50 -510 88 -510Q126 -510 156 -492Q186 -474 196 -456Q259 -510 346 -510Q433 -510 472 -463Q511 -416 511 -309L511 -9Q511 3 426 3Q340 3 340 -9L340 -298Q340 -348 305 -348Q295 -348 277 -340Q259 -331 254 -327Z'),
}
WORD = 'Battleplan'
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


def b_path(cap, cx, cy):
    """The B at cap height `cap`, centred on (cx, cy), as an absolute M/L/Q/Z path."""
    k = cap / B_CAP
    X = lambda x: cx + (x - B_ADVANCE / 2) * k
    Y = lambda y: cy + cap / 2 - y * k
    t, i, d, x, y = _tokens(B_GLYPH), 0, [], 0.0, 0.0
    while i < len(t):
        c = t[i]; i += 1
        if c in 'ML':
            x, y = t[i], t[i + 1]; i += 2; d.append('%s%.1f %.1f' % (c, X(x), Y(y)))
        elif c == 'H':
            x = t[i]; i += 1; d.append('L%.1f %.1f' % (X(x), Y(y)))
        elif c == 'V':
            y = t[i]; i += 1; d.append('L%.1f %.1f' % (X(x), Y(y)))
        elif c == 'Q':
            x1, y1, x, y = t[i:i + 4]; i += 4
            d.append('Q%.1f %.1f %.1f %.1f' % (X(x1), Y(y1), X(x), Y(y)))
        elif c == 'Z':
            d.append('Z')
    return ''.join(d)


def twinkle_path(cx, cy, r):
    """A four-point twinkle with pinched sides."""
    k = r * .28
    return ('M%g %gQ%g %g %g %gQ%g %g %g %gQ%g %g %g %gQ%g %g %g %gZ' % (
        cx, cy - r, cx + k, cy - k, cx + r, cy, cx + k, cy + k, cx, cy + r, cx - k, cy + k, cx - r, cy, cx - k, cy - k, cx, cy - r))


# ---- a tiny display list, so the SVGs and the Dart painter draw the same thing ----
# Shapes: ('rrect', x, y, w, h, r) · ('circle', cx, cy, r) · ('path', d)
# Ops:    ('draw', shape, fill, stroke, width, alpha) · ('push', transforms) · ('pop',)
#         ('clip', shape) · ('dots', step, r, color, alpha) · ('rect', color)
# Transforms: ('t', dx, dy) · ('r', degrees, cx, cy) · ('s', k, cx, cy)

def draw(shape, fill=None, stroke=None, width=0, alpha=1.0):
    return ('draw', shape, fill, stroke, width, alpha)


def sticker(shape, face, rim, edge, border):
    """A die-cut sticker: a navy edge, a thick white border, then the candy face with a darker rim."""
    return [draw(shape, WHITE, INK, edge), draw(shape, WHITE, WHITE, border), draw(shape, face, rim, 9)]


def shine(x, y, h):
    """The candy shine: a white capsule and a dot."""
    return [draw(('rrect', x, y, 40, h, 20), WHITE, alpha=SHINE_ALPHA),
            draw(('circle', x + 20, y + h + 46, 20), WHITE, alpha=SHINE_ALPHA)]


def outlined_b(cap, cx, cy, width, shadow):
    d = b_path(cap, cx, cy)
    ops = []
    if shadow:
        ops += [('push', [('t', shadow, shadow)]), draw(('path', d), INK, INK, width), ('pop',)]
    return ops + [draw(('path', d), INK, INK, width), draw(('path', d), WHITE)]


def chain(p0, p2, ctrl, r=16, sw=8, step=33):
    """Ball chain beads along a quadratic curve, spaced about `step` apart."""
    seg = 200
    pts = [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t * t * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t * t * p2[1]) for t in [i / seg for i in range(seg + 1)]]
    length = sum(math.dist(pts[i], pts[i + 1]) for i in range(seg))
    n = max(2, round(length / step))
    out = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t * t * p2[1]
        out.append(draw(('circle', round(x, 1), round(y, 1), r), WHITE, INK, sw))
    return out


PIVOT = (512, 250)       # where the chain runs through both tags' holes, in the art's own grid
SHIFT = (28, 50)         # the art sits a little right and low on the tile


def to_local(g, k):
    """A point on the tile, in the art's own grid when the art is scaled by k about the centre."""
    return ((g[0] - 512) / k + 512 - SHIFT[0], (g[1] - 512) / k + 512 - SHIFT[1])


def pair(k=1.0, ends=((40, -50), (984, -50)), twinkles=True):
    """The Sticker Pair at scale k about the tile's centre, its chain running to `ends` (tile points)."""
    ops = [('push', [('s', k, 512, 512), ('t', SHIFT[0], SHIFT[1])])]
    for e in ends:
        le = to_local(e, k)
        ctrl = (PIVOT[0] + .44 * (le[0] - PIVOT[0]), PIVOT[1] + 70)
        ops += chain(le, PIVOT, ctrl)
    back = ('rrect', 337, 212, 350, 530, 114)
    ops += [('push', [('t', 20, 24), ('r', 30, *PIVOT)]), draw(back, INK, INK, 88), ('pop',)]
    ops += [('push', [('r', 30, *PIVOT)])] + sticker(back, CORAL, CORAL_RIM, 88, 48)
    ops += [draw(('circle', 512, 250, 24), INK)] + shine(376, 310, 120) + [('pop',)]
    front = ('rrect', 317, 212, 390, 580, 128)
    ops += [('push', [('t', 24, 28), ('r', -10, *PIVOT)]), draw(front, INK, INK, 96), ('pop',)]
    ops += [('push', [('r', -10, *PIVOT)])] + sticker(front, YELLOW, YELLOW_RIM, 96, 54)
    ops += [draw(('circle', 512, 250, 28), INK)] + shine(355, 330, 130)
    ops += outlined_b(290, 528, 540, 38, 13) + [('pop',)]
    ops += [draw(('circle', 512, 250, 18), WHITE, INK, 8)]
    ops += [('pop',)]
    if twinkles:
        ops += [('push', [('s', k, 512, 512)]),
                draw(('path', twinkle_path(878, 440, 70)), WHITE, INK, 14),
                draw(('path', twinkle_path(168, 860, 46)), YELLOW, INK, 12), ('pop',)]
    return ops


def tile(rounded):
    r = 224 if rounded else 0
    shape = ('rrect', 0, 0, 1024, 1024, r)
    return [('clip', shape), draw(shape, BLUE), ('dots', 64, 8, DOT, DOT_ALPHA)]


def logo():
    """The logo: the pair on no tile, clipped to its square so the chain runs off the top edge."""
    return [('clip', ('rrect', 0, 0, 1024, 1024, 0))] + pair()


def favicon_small():
    """For 16 px: just the two tags and the B, with heavy edges and no chain, shine or tile."""
    back = ('rrect', 300, 170, 440, 680, 150)
    front = ('rrect', 282, 150, 480, 760, 160)
    ops = [('push', [('r', 22, 512, 200)])] + sticker(back, CORAL, CORAL_RIM, 110, 50) + [('pop',)]
    ops += [('push', [('r', -8, 512, 200)])] + sticker(front, YELLOW, YELLOW_RIM, 120, 56)
    ops += outlined_b(430, 522, 560, 64, 0) + [('pop',)]
    return ops


def monochrome():
    """Android's themed icon: one color. The back tag, the front tag cut free of it, the B and holes cut out."""
    k = .86
    back = ('rrect', 337, 212, 350, 530, 114)
    front = ('rrect', 317, 212, 390, 580, 128)
    cut = '#000000'   # drawn into a mask: black is cut away, white is kept
    m = [('push', [('s', k, 512, 512), ('t', SHIFT[0], SHIFT[1])])]
    for e in ((40, -50), (984, -50)):
        le = to_local(e, k)
        ctrl = (PIVOT[0] + .44 * (le[0] - PIVOT[0]), PIVOT[1] + 70)
        m += [o[:2] + (WHITE, None, 0, 1.0) for o in chain(le, PIVOT, ctrl)]
    m += [('push', [('r', 30, *PIVOT)]), draw(back, WHITE, WHITE, 88), draw(('circle', 512, 250, 24), cut), ('pop',)]
    m += [('push', [('r', -10, *PIVOT)]), draw(front, cut, cut, 150), draw(front, WHITE, WHITE, 96),
          draw(('path', b_path(290, 528, 540)), cut), draw(('circle', 512, 250, 28), cut), ('pop',)]
    m += [draw(('circle', 512, 250, 18), cut)]
    return m + [('pop',)]


def word_path():
    """"Battleplan" as one path, its pen starting at 0 on the baseline."""
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
    return (left - pad, -703 - pad, right - left + 2 * pad, 703 + 189 + WORD_DROP + 2 * pad)


def wordmark():
    """The name as the logo writes it: white letters on a navy hard drop (no edge: for dark grounds)."""
    d = word_path()
    return [('push', [('t', 0, WORD_DROP)]), draw(('path', d), INK), ('pop',)] + [draw(('path', d), WHITE)]


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
    body, defs, opened = [], [], 0
    for op in ops:
        kind = op[0]
        if kind == 'push':
            body.append('<g transform="%s">' % _svg_transform(op[1]))
        elif kind == 'pop':
            body.append('</g>')
        elif kind == 'clip':
            cid = '%s-clip' % prefix
            defs.append('<clipPath id="%s">%s</clipPath>' % (cid, _svg_shape(op[1], '')))
            body.append('<g clip-path="url(#%s)">' % cid); opened += 1
        elif kind == 'dots':
            _, step, r, col, a = op
            pid = '%s-dots' % prefix
            defs.append('<pattern id="%s" width="%g" height="%g" patternUnits="userSpaceOnUse"><circle cx="%g" cy="%g" r="%g" fill="%s" fill-opacity="%g"/></pattern>'
                        % (pid, step, step, step / 2, step / 2, r, col, a))
            body.append('<rect width="1024" height="1024" fill="url(#%s)"/>' % pid)
        elif kind == 'draw':
            _, shape, fill, stroke, width, alpha = op
            a = ' fill="%s"' % (fill or 'none')
            if alpha != 1.0: a += ' fill-opacity="%g"' % alpha
            if stroke: a += ' stroke="%s" stroke-width="%g" stroke-linejoin="round"' % (stroke, width)
            body.append(_svg_shape(shape, a))
    body += ['</g>'] * opened
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%g %g %g %g" width="%g" height="%g">\n' % (box + box[2:])
            + '<!-- %s Made by tools/make_brand.py. -->\n' % comment
            + ('<defs>%s</defs>\n' % ''.join(defs) if defs else '') + '\n'.join(body) + '\n</svg>\n')


def mono_svg():
    """The themed icon as a white shape: the monochrome ops drawn into a mask over a white square."""
    inner = to_svg(monochrome(), 'bp-mono', '').split('\n')
    shapes = '\n'.join(l for l in inner if l and not l.startswith(('<svg', '<!--', '</svg', '<defs')))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">\n'
            '<!-- Battleplan\'s themed Android icon: the Sticker Pair as one shape. Made by tools/make_brand.py. -->\n'
            '<defs><mask id="bp-mono-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">\n'
            + shapes + '\n</mask></defs>\n<rect width="1024" height="1024" fill="#FFFFFF" mask="url(#bp-mono-mask)"/>\n</svg>\n')


# ---- Dart ----
def _hex(c, a=1.0):
    c = c.lstrip('#')
    return '0x%02X%s' % (round(a * 255), c.upper())


def to_dart(ops):
    """The painter's body: one cascade on the canvas, one step per op, in the SVG's order.
    Runs of chain beads become one beads() call."""
    lines, paths, beads = [], {}, []

    def flush():
        if beads:
            r, sw = beads[0][2], beads[0][3]
            pts = ', '.join('Offset(%g, %g)' % (b[0], b[1]) for b in beads)
            lines.append('..beads(const [%s], %g, %g)' % (pts, r, sw))
            beads.clear()

    for op in ops:
        kind = op[0]
        if kind == 'draw' and op[1][0] == 'circle' and op[2] == WHITE and op[3] == INK and op[5] == 1.0 and op[1][3] == 16:
            beads.append((op[1][1], op[1][2], op[1][3], op[4]))
            continue
        flush()
        if kind == 'push':
            lines.append('..save()')
            for t in op[1]:
                if t[0] == 't': lines.append('..translate(%g, %g)' % t[1:])
                elif t[0] == 'r': lines.append('..rotateAbout(%g, %g, %g)' % t[1:])
                elif t[0] == 's': lines.append('..scaleAbout(%g, %g, %g)' % t[1:])
        elif kind == 'pop':
            lines.append('..restore()')
        elif kind == 'clip':
            _, x, y, w, h, r = op[1]
            lines.append('..clipRRect(_rrect(%g, %g, %g, %g, %g))' % (x, y, w, h, r))
        elif kind == 'dots':
            _, step, r, col, a = op
            lines.append('..dots(%g, %g, const Color(%s))' % (step, r, _hex(col, a)))
        elif kind == 'draw':
            _, shape, fill, stroke, width, alpha = op
            if shape[0] == 'path':
                name = paths.setdefault(shape[1], '_p%d' % len(paths))
                call = '..drawPath(%s, %%s)' % name
            elif shape[0] == 'rrect':
                call = '..drawRRect(_rrect(%g, %g, %g, %g, %g), %%s)' % shape[1:]
            else:
                call = '..drawCircle(const Offset(%g, %g), %g, %%s)' % shape[1:]
            if stroke:
                lines.append(call % ('_stroke(const Color(%s), %g)' % (_hex(stroke), width)))
            if fill:
                lines.append(call % ('_fill(const Color(%s))' % _hex(fill, alpha)))
    flush()
    return lines, paths


DART_HEAD = """// Made by tools/make_brand.py from the same shapes as website/logo.svg;
// change the mark there and run it again rather than editing this file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1), the Sticker Pair: two candy dog tags on a
/// white ball chain, each a die-cut sticker with a white border in a navy
/// edge, the yellow one in front with the white stencil B and a coral one
/// swung out behind it, with two twinkles, on no tile: the page shows around
/// it, and the chain runs off the top. The same art as `website/logo.svg` and
/// `assets/brand/*.svg`, painted from their shapes so it's sharp at any size
/// and needs no image to load. Decorative: screen readers skip it, as the
/// app's name is always written next to it.
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

/// An outline centred on the shape's edge, with round joins like the SVGs'.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round;

/// The SVGs' transforms and repeated parts, so the painter is one cascade.
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

  /// The tile's dot grid: a dot in the middle of every step-sized cell.
  void dots(double step, double r, Color color) {
    final paint = _fill(color);
    for (var y = step / 2; y < _MarkPainter._tile; y += step) {
      for (var x = step / 2; x < _MarkPainter._tile; x += step) {
        drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  /// The ball chain: white beads in a navy edge.
  void beads(List<Offset> centres, double r, double edge) {
    final fill = _fill(const Color(0xFFFFFFFF));
    final stroke = _stroke(const Color(0xFF0B1640), edge);
    for (final c in centres) {
      this
        ..drawCircle(c, r, fill)
        ..drawCircle(c, r, stroke);
    }
  }
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
/// The app's name as the logo writes it (SPEC §7.1): "Battleplan" in Lilita
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
    tail = DART_TAIL
    if not any(op[0] == 'dots' for op in ops):
        # No tile, so no dot grid: leave its helper out, as the analyzer refuses unused code.
        start = tail.index("  /// The tile's dot grid")
        tail = tail[:start] + tail[tail.index('  /// The ball chain'):]
    out.append(tail)
    x, y, w, h = word_box()
    out.append(WORD_DART % dict(x=x, y=y, w=w, h=h, d=word_path(), drop=WORD_DROP, edge=WORD_EDGE,
                                ink=_hex(INK), white=_hex(WHITE)))
    dart = ROOT / 'lib/core/widgets/brand_mark.dart'
    dart.write_text('\n'.join(out))
    # CI checks the formatting; format it the way dart format would, when Dart is here.
    if shutil.which('dart'):
        subprocess.run(['dart', 'format', str(dart)], check=False, capture_output=True)


def main():
    files = {
        'assets/brand/icon.svg': (tile(False) + pair(), 'bp-icon', "Battleplan's app icon, the Sticker Pair on its square tile."),
        'assets/brand/maskable.svg': (tile(False) + pair(.8, ((-60, -160), (1084, -160))), 'bp-mask',
                                      "Battleplan's maskable web icon: the Sticker Pair inside the 80% circle."),
        'assets/brand/foreground.svg': (pair(.86, ((60, -40), (964, -40))), 'bp-fg',
                                        "Battleplan's adaptive Android icon foreground, on no tile."),
        'assets/brand/mark.svg': (pair(.6, ((285, 310), (762, 310))), 'bp-mark',
                                  "Battleplan's splash mark: the Sticker Pair on a short chain, inside Android 12's circle."),
        'website/logo.svg': (logo(), 'bp-logo', "Battleplan's logo, the Sticker Pair, on no tile."),
        'website/wordmark.svg': (wordmark(), 'bp-word', "Battleplan's name as the logo writes it, in Lilita One (OFL).", word_box()),
        'website/favicon.svg': (tile(True) + pair(), 'bp-fav', "Battleplan's mark, the Sticker Pair, on its rounded tile."),
        'website/favicon-small.svg': (favicon_small(), 'bp-small', "Battleplan's browser-tab icon, drawn for 16 px."),
        'web/favicon-small.svg': (favicon_small(), 'bp-small', "Battleplan's browser-tab icon, drawn for 16 px."),
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
    html, n = re.subn(r'<svg class="mark".*?</svg>(?:<svg class="name".*?</svg>|Battleplan)', lambda m: inline,
                      index.read_text(), count=1, flags=re.S)
    assert n == 1, 'web/index.html has no <svg class="mark"> and name to replace'
    index.write_text(html)
    write_dart(logo())


if __name__ == '__main__':
    main()
