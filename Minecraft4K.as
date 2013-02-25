/**
 * Copyright yonatan ( http://wonderfl.net/user/yonatan )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/sqL5
 */

// ported from notch's javascript version: http://jsdo.it/notch/dB1E
// An unoptimized flash port made in about 10 minutes
// (would have been 5 but I messed up and made 'var closest' an int at first)

// 20121227 ported from http://jsfiddle.net/uzMPU/ to Biliscript - nekofs
// initial version (verbatim port), performance: 0.1 fps with 200x200; 0.3fps with 120x90

/* framebuffer dimension */
var w = 120;
var h = 90;

/* generate texture of 16 blocks, 3 surface each block, 16*16 pixel each surface */
function initTexMap(texmap) {
    for (var i = 1; i < 16; i++) {
        var br = 255 - ((Math.random() * 96) | 0);
        for (var y = 0; y < 16 * 3; y++) {
            for (var x = 0; x < 16; x++) {
                var color = 0x966C4A;
                if (i == 4) color = 0x7F7F7F;
                if (i != 4 || ((Math.random() * 3) | 0) == 0) {
                    br = 255 - ((Math.random() * 96) | 0);
                }
                if ((i == 1 && y < (((x * x * 3 + x * 81) >> 2) & 3) + 18)) {
                    color = 0x6AAA40;
                } else if ((i == 1 && y < (((x * x * 3 + x * 81) >> 2) & 3) + 19)) {
                    br = br * 2 / 3;
                }
                if (i == 7) {
                    color = 0x675231;
                    if (x > 0 && x < 15 && ((y > 0 && y < 15) || (y > 32 && y < 47))) {
                        color = 0xBC9862;
                        var xd = (x - 7);
                        var yd = ((y & 15) - 7);
                        if (xd < 0) xd = 1 - xd;
                        if (yd < 0) yd = 1 - yd;
                        if (yd > xd) xd = yd;

                        br = 196 - ((Math.random() * 32) | 0) + xd % 3 * 32;
                    } else if (((Math.random() * 2) | 0) == 0) {
                        br = br * (150 - (x & 1) * 100) / 100;
                    }
                }
                if (i == 5) {
                    color = 0xB53A15;
                    if ((x + (y >> 2) * 4) % 8 == 0 || y % 4 == 0) color = 0xBCAFA5;
                }
                if (i == 9) color = 0x4040ff;
                var brr = br;
                if (y >= 32) brr /= 2;
                if (i == 8) {
                    color = 0x50D937;
                    if (((Math.random() * 2) | 0) == 0) {
                        color = 0;
                        brr = 255;
                    }
                }

                var col = (((color >> 16) & 0xff) * brr / 255) << 16 | (((color >> 8) & 0xff) * brr / 255) << 8 | (((color) & 0xff) * brr / 255);
                texmap[x + y * 16 + i * 256 * 3] = col;
                //texmap.setPixel(x, i * 16 * 3 + y, col);
            }
        }
    }
}

/* generate scene map */
function initMap(map) {
    for (var x = 0; x < 64; x++) {
        for (var y = 0; y < 64; y++) {
            for (var z = 0; z < 64; z++) {
                var i = (z << 12) | (y << 6) | x;
                var yd = (y - 32.5) * 0.4;
                var zd = (z - 32.5) * 0.4;
                map[i] = (Math.random() * 16) | 0;
                /* the tunnel at the center: */
                if (Math.random() > Math.sqrt(Math.sqrt(yd * yd + zd * zd)) - 0.8) map[i] = 0;
            }
        }
    }
}

/* render each frame */
function renderMinecraft() {
    var data = $G._('data');
    var bmd = data.bmd;
    var texmap = data.texmap;
    var map = data.map;

    var xRot = Math.sin(getTimer() % 10000 / 10000 * Math.PI * 2) * 0.4 + Math.PI / 2;
    var yRot = Math.cos(getTimer() % 10000 / 10000 * Math.PI * 2) * 0.4;
    var yCos = Math.cos(yRot);
    var ySin = Math.sin(yRot);
    var xCos = Math.cos(xRot);
    var xSin = Math.sin(xRot);

    var ox = 32.5 + getTimer() % 10000 / 10000 * 64;
    var oy = 32.5;
    var oz = 32.5;

    var start = getTimer();
    bmd.lock();
    /* render every pixel w*h */
    for (var x = 0; x < w; x++) {
        var ___xd = (x - w / 2) / h;
        for (var y = 0; y < h; y++) {
            var __yd = (y - h / 2) / h;
            var __zd = 1;

            var ___zd = __zd * yCos + __yd * ySin;
            var _yd = __yd * yCos - __zd * ySin;

            var _xd = ___xd * xCos + ___zd * xSin;
            var _zd = ___zd * xCos - ___xd * xSin;

            var col = 0;
            var br = 255;
            var ddist = 0;

            /* manual ray casting. biliscript loop performance sucks */
            var closest = 32;
            for (var d = 0; d < 3; d++) {
                var dimLength = _xd;
                if (d == 1) dimLength = _yd;
                if (d == 2) dimLength = _zd;

                var ll = 1 / (dimLength < 0 ? -dimLength : dimLength);
                var xd = (_xd) * ll;
                var yd = (_yd) * ll;
                var zd = (_zd) * ll;

                var initial = ox - (ox | 0);
                if (d == 1) initial = oy - (oy | 0);
                if (d == 2) initial = oz - (oz | 0);
                if (dimLength > 0) initial = 1 - initial;

                var dist = ll * initial;

                var xp = ox + xd * initial;
                var yp = oy + yd * initial;
                var zp = oz + zd * initial;

                if (dimLength < 0) {
                    if (d == 0) xp--;
                    if (d == 1) yp--;
                    if (d == 2) zp--;
                }

                while (dist < closest) {
                    var tex = map[(zp & 63) << 12 | (yp & 63) << 6 | (xp & 63)];

                    if (tex > 0) {
                        var u = ((xp + zp) * 16) & 15;
                        var v = ((yp * 16) & 15) + 16;
                        if (d == 1) {
                            u = (xp * 16) & 15;
                            v = ((zp * 16) & 15);
                            if (yd < 0) v += 32;
                        }

                        var cc = texmap[u + v * 16 + tex * 256 * 3];
                        //var cc = texmap.getPixel(u, tex * 16 * 3 + v);
                        if (cc > 0) {
                            col = cc;
                            ddist = 255 - ((dist / 32 * 255) | 0);
                            br = 255 * (255 - ((d + 2) % 3) * 50) / 255;
                            closest = dist;
                        }
                    }
                    xp += xd;
                    yp += yd;
                    zp += zd;
                    dist += ll;
                }
            }

            var r = ((col >> 16) & 0xff) * br * ddist / (255 * 255);
            var g = ((col >> 8) & 0xff) * br * ddist / (255 * 255);
            var b = ((col) & 0xff) * br * ddist / (255 * 255);

            bmd.setPixel(x, y, r << 16 | g << 8 | b);
        }
    }
    bmd.unlock();
    trace('rendering: ' + (getTimer() - start) + 'ms/frame');
}

function startApplication() {
    //var map: Vector. < int > = new Vector. < int > (64 * 64 * 64, true);
    var map = Bitmap.createBitmapData(512, 512, false, 0);
    map = map.getVector(map.rect); //512*512=64*64*64
    //var texmap: Vector. < int > = new Vector. < int > (16 * 16 * 3 * 16, true);
    var texmap = Bitmap.createBitmapData(16, 16 * 16 * 3, false, 0);
    texmap = texmap.getVector(texmap.rect);

    initTexMap(texmap);
    initMap(map);
    var bmd = Bitmap.createBitmapData(w, h, false, 0);
    var bmp = Bitmap.createBitmap({bitmapData: bmd, lifeTime: 0});
    bmp.scaleX = bmp.scaleY = 4;
    bmp.x = ((Player.width - bmp.width) / 2) | 0;
    bmp.y = ((Player.height - bmp.height) / 2) | 0;
    $G._set('data', {bmd: bmd, texmap: texmap, map: map});
    bmp.addEventListener("enterFrame", renderMinecraft);
} 

loading = $.createComment('加载libBitmap，稍候…', {lifeTime: 0});
timerLoadTimeout = timer(function() {
    trace('libBitmap load timeout');
}, 3000);
load('libBitmap', function() {
    loading.visible = false;
    clearTimeout(timerLoadTimeout);
    startApplication();
});