"""Draws the website's camouflage (website/images/camo-*.svg, #94 Camo HQ).

The app's header camouflage (Boot Camp Mix, SPEC §7.4) is a 400 x 140 tile of
three layers of soft blotches on a ground color. The website's hero and its
Playbook band are much bigger, so this draws the same kind of pattern on a
1600 x 900 tile with the blotches twice the app's size, as the header would
look at 2x, in two of the app's schemes: Black (the site's own) and Army
green (the Playbook band). Our own shapes from a seeded random walk, the same
every run; it copies no issued or trademarked pattern.

Run: python3 tools/make_web_camo.py
"""
import math
import pathlib
import random

OUT = pathlib.Path(__file__).resolve().parent.parent / 'website' / 'images'
W, H = 1600, 900


def blob(cx, cy, r, sx, rot, n=9):
    """One blotch: n jittered points round an ellipse, closed with a Catmull-Rom spline."""
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        rr = r * random.uniform(.62, 1.28)
        x, y = rr * math.cos(a) * sx, rr * math.sin(a)
        pts.append((cx + x * math.cos(rot) - y * math.sin(rot), cy + x * math.sin(rot) + y * math.cos(rot)))
    d = 'M%.0f %.0f' % pts[0]
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += 'C%.0f %.0f %.0f %.0f %.0f %.0f' % (c1 + c2 + p2)
    return d + 'Z'


def layer(color, count, rmin, rmax, scale=2.0):
    shapes = ''.join(
        blob(random.uniform(-20, W + 20), random.uniform(-20, H + 20), random.uniform(rmin, rmax) * scale,
             random.uniform(1.3, 2.3), random.uniform(-.5, .5))
        for _ in range(count))
    return '<path fill="%s" d="%s"/>' % (color, shapes)


def camo(name, ground, big, mid, small):
    """The app's four camouflage colors for a scheme: ground, then the big, mid and small blotches."""
    random.seed(41)
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" preserveAspectRatio="xMidYMid slice">' % (W, H)
           + '<rect width="%d" height="%d" fill="%s"/>' % (W, H, ground)
           # The header's 13, 9 and 8 blotches per 400 x 140, over this tile's area at twice the size.
           + layer(big, 84, 16, 30) + layer(mid, 58, 11, 22) + layer(small, 52, 6, 13) + '</svg>\n')
    (OUT / name).write_text(svg)
    print(name, len(svg), 'bytes')


camo('camo-black.svg', '#23241F', '#161713', '#3A3C33', '#070706')
camo('camo-army.svg', '#3F4722', '#2A3016', '#7F7A48', '#14170B')
