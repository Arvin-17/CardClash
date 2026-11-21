E() {
if (this._E) return this._E;
const P = {ink:'#120a16', wall0:'#1a1220', wall1:'#241830', wall2:'#2f2040', glow:'#3d2a4e', paper:'#2c1f3a',
 wood:'#6b3f22', woodHi:'#a8683a', woodDk:'#3f2414', felt0:'#12301f', felt1:'#1a4230', felt2:'#245a40',
 cream:'#f3e6d0', creamSh:'#d6c2a4', red:'#c8283c', redHi:'#ff5a6a', redDk:'#7a1428', black:'#2a2236', blackHi:'#4f4566',
 gold:'#e8b04a', goldDk:'#a8702a', goldHi:'#ffe08a', skin:'#f2c9a8', skinSh:'#cf957c', skinHi:'#ffe2cc', white:'#fbf6ee',
 plum:'#4a2a5c', plumHi:'#7a4a9c', lav:'#b8a3e0', lavDk:'#7e68b0', pink:'#ff7fb0', pinkDk:'#c8507e', teal:'#3fc1c9',
 green:'#2f6b4f', greenDk:'#1d4433', greenHi:'#58a67c', mustard:'#e0a030', hair:'#2a2030', hairHi:'#5a4870',
 grey:'#8d86a8', greyHi:'#c4bddc', greyDk:'#5a5478', steam:'#cfc6dc', blush:'#f08a8a', qskin:'#f6e4dc', qskinSh:'#d9b5aa',
 qhair:'#5a1030', qhairHi:'#8a2448', flush:'#ff9a9a'};
const BAY = [[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]];
let c = null;
const use = (x) => { c = x; };
const R = (x,y,w,h,col) => { x=Math.round(x); y=Math.round(y); w=Math.round(w); h=Math.round(h); if (w<=0||h<=0) return; c.fillStyle=col; c.fillRect(x,y,w,h); };
const px = (x,y,col) => R(x,y,1,1,col);
const ell = (cx,cy,rx,ry,col) => { cx=Math.round(cx); cy=Math.round(cy); rx=Math.round(rx); ry=Math.round(ry); for (let dy=-ry; dy<=ry; dy++) { const f = 1 - (dy*dy)/((ry+0.5)*(ry+0.5)); if (f<0) continue; const hw = Math.round(rx*Math.sqrt(f)); R(cx-hw, cy+dy, hw*2+1, 1, col); } };
const circ = (cx,cy,r,col) => ell(cx,cy,r,r,col);
const dell = (cx,cy,rx,ry,col,lv) => { cx=Math.round(cx); cy=Math.round(cy); rx=Math.round(rx); ry=Math.round(ry); for (let dy=-ry; dy<=ry; dy++) { const f = 1 - (dy*dy)/((ry+0.5)*(ry+0.5)); if (f<0) continue; const hw = Math.round(rx*Math.sqrt(f)); for (let x=cx-hw; x<=cx+hw; x++) { const y=cy+dy; if (BAY[((y%4)+4)%4][((x%4)+4)%4] < lv*16) px(x,y,col); } } };
const drect = (x0,y0,w,h,col,lv) => { x0=Math.round(x0); y0=Math.round(y0); for (let y=y0;y<y0+h;y++) for (let x=x0;x<x0+w;x++) if (BAY[((y%4)+4)%4][((x%4)+4)%4] < lv*16) px(x,y,col); };
const poly = (pts,col) => { let a=1e9,b=-1e9; for (const p of pts) { if (p[1]<a) a=p[1]; if (p[1]>b) b=p[1]; } a=Math.floor(a); b=Math.ceil(b); for (let y=a; y<=b; y++) { const yc=y+0.5, xs=[]; for (let i=0;i<pts.length;i++) { const p=pts[i], q=pts[(i+1)%pts.length]; if ((p[1]<=yc&&q[1]>yc)||(q[1]<=yc&&p[1]>yc)) xs.push(p[0]+(yc-p[1])*(q[0]-p[0])/(q[1]-p[1])); } xs.sort((m,n)=>m-n); for (let i=0;i+1<xs.length;i+=2) { const x0=Math.round(xs[i]), x1=Math.round(xs[i+1]); R(x0,y,x1-x0,1,col); } } };
const line = (x0,y0,x1,y1,col) => { x0=Math.round(x0); y0=Math.round(y0); x1=Math.round(x1); y1=Math.round(y1); const dx=Math.abs(x1-x0), dy=-Math.abs(y1-y0), sx=x0<x1?1:-1, sy=y0<y1?1:-1; let er=dx+dy; for (let i=0;i<600;i++) { px(x0,y0,col); if (x0===x1&&y0===y1) break; const e2=2*er; if (e2>=dy) { er+=dy; x0+=sx; } if (e2<=dx) { er+=dx; y0+=sy; } } };
const bmp = (str,x,y,col,s) => { s=s||1; const rows=str.split('|'); for (let j=0;j<rows.length;j++) for (let i=0;i<rows[j].length;i++) if (rows[j][i]==='#') R(x+i*s,y+j*s,s,s,col); };
const F = {A:'.###.|#...#|#...#|#####|#...#|#...#|#...#',B:'####.|#...#|#...#|####.|#...#|#...#|####.',C:'.###.|#...#|#....|#....|#....|#...#|.###.',D:'####.|#...#|#...#|#...#|#...#|#...#|####.',E:'#####|#....|#....|####.|#....|#....|#####',F:'#####|#....|#....|####.|#....|#....|#....',G:'.###.|#...#|#....|#.###|#...#|#...#|.####',H:'#...#|#...#|#...#|#####|#...#|#...#|#...#',I:'.###.|..#..|..#..|..#..|..#..|..#..|.###.',J:'..###|...#.|...#.|...#.|...#.|#..#.|.##..',K:'#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#',L:'#....|#....|#....|#....|#....|#....|#####',M:'#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#',N:'#...#|#...#|##..#|#.#.#|#..##|#...#|#...#',O:'.###.|#...#|#...#|#...#|#...#|#...#|.###.',P:'####.|#...#|#...#|####.|#....|#....|#....',Q:'.###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#',R:'####.|#...#|#...#|####.|#.#..|#..#.|#...#',S:'.####|#....|#....|.###.|....#|....#|####.',T:'#####|..#..|..#..|..#..|..#..|..#..|..#..',U:'#...#|#...#|#...#|#...#|#...#|#...#|.###.',V:'#...#|#...#|#...#|#...#|#...#|.#.#.|..#..',W:'#...#|#...#|#...#|#.#.#|#.#.#|#.#.#|.#.#.',X:'#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#',Y:'#...#|#...#|.#.#.|..#..|..#..|..#..|..#..',Z:'#####|....#|...#.|..#..|.#...|#....|#####','0':'.###.|#...#|#..##|#.#.#|##..#|#...#|.###.','1':'..#..|.##..|..#..|..#..|..#..|..#..|.###.','2':'.###.|#...#|....#|...#.|..#..|.#...|#####','3':'#####|...#.|..#..|...#.|....#|#...#|.###.','4':'...#.|..##.|.#.#.|#..#.|#####|...#.|...#.','5':'#####|#....|####.|....#|....#|#...#|.###.','6':'..##.|.#...|#....|####.|#...#|#...#|.###.','7':'#####|....#|...#.|..#..|.#...|.#...|.#...','8':'.###.|#...#|#...#|.###.|#...#|#...#|.###.','9':'.###.|#...#|#...#|.####|....#|...#.|.##..','!':'..#..|..#..|..#..|..#..|..#..|.....|..#..','?':'.###.|#...#|....#|...#.|..#..|.....|..#..','.':'.....|.....|.....|.....|.....|.....|..#..','/':'....#|....#|...#.|..#..|.#...|#....|#....','-':'.....|.....|.....|.###.|.....|.....|.....',"'":'..#..|..#..|.#...|.....|.....|.....|.....',':':'.....|..#..|.....|.....|.....|..#..|.....','·':'.....|.....|.....|..#..|.....|.....|.....','+':'.....|..#..|..#..|#####|..#..|..#..|.....','>':'.#...|..#..|...#.|....#|...#.|..#..|.#...','[':'.###.|.#...|.#...|.#...|.#...|.#...|.###.',']':'.###.|...#.|...#.|...#.|...#.|...#.|.###.'};
const text = (s,x,y,col,sc) => { sc=sc||1; s=String(s).toUpperCase(); let cx=x; for (const ch of s) { const g=F[ch]; if (g) { const rows=g.split('|'); for (let j=0;j<7;j++) for (let i=0;i<5;i++) if (rows[j][i]==='#') R(cx+i*sc,y+j*sc,sc,sc, typeof col==='function'?col(j):col); } cx += 6*sc; } };
const tw = (s,sc) => String(s).length*6*(sc||1)-(sc||1);
const stext = (s,x,y,col,sc,ol) => { sc=sc||1; const o=ol||P.ink; for (const d of [[-1,0],[1,0],[0,-1],[0,1],[1,1],[-1,1],[1,-1],[-1,-1]]) text(s,x+d[0]*sc,y+d[1]*sc,o,sc); text(s,x,y,col,sc); };
const M = {'1':'.#.|##.|.#.|.#.|###','0':'###|#.#|#.#|#.#|###','6':'###|#..|###|#.#|###','/':'..#|..#|.#.|#..|#..'};
const mtext = (s,x,y,col) => { let cx=x; for (const ch of s) { if (M[ch]) bmp(M[ch],cx,y,col); cx+=4; } };
const PIP5 = {heart:'.#.#.|#####|#####|.###.|..#..', diamond:'..#..|.###.|#####|.###.|..#..', spade:'..#..|.###.|#####|#####|..#..', club:'.###.|#####|.###.|..#..|.###.'};
const PIP9 = {heart:'.##...##.|####.####|#########|#########|.#######.|..#####..|...###...|....#....|.........',
 diamond:'....#....|...###...|..#####..|.#######.|#########|.#######.|..#####..|...###...|....#....',
 spade:'....#....|...###...|..#####..|.#######.|#########|#########|.##.#.##.|....#....|...###...',
 club:'...###...|..#####..|...###...|.##.#.##.|#########|#########|.##.#.##.|....#....|...###...'};
const heart = (cx,cy,s,col) => { const r=Math.max(1,Math.round(s*0.55)); circ(cx-Math.round(s*0.5),cy,r,col); circ(cx+Math.round(s*0.5),cy,r,col); poly([[cx-s-0.6,cy+0.5],[cx+s+0.6,cy+0.5],[cx,cy+s*1.35]],col); };
const hx = (h) => [parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)];
const INK = hx(P.ink);
const outline = (lc,W,H) => { const img=lc.getImageData(0,0,W,H), d=img.data, out=new Uint8ClampedArray(d); for (let y=0;y<H;y++) for (let x=0;x<W;x++) { const i=(y*W+x)*4; if (d[i+3]>0) continue; if ((x>0&&d[i-1]>0)||(x<W-1&&d[i+7]>0)||(y>0&&d[i-W*4+3]>0)||(y<H-1&&d[i+W*4+3]>0)) { out[i]=INK[0]; out[i+1]=INK[1]; out[i+2]=INK[2]; out[i+3]=255; } } img.data.set(out); lc.putImageData(img,0,0); };
const fadeL = (lc,W,H,lv) => { const img=lc.getImageData(0,0,W,H), d=img.data; for (let y=0;y<H;y++) for (let x=0;x<W;x++) { const i=(y*W+x)*4; if (d[i+3]>0 && BAY[y&3][x&3] >= lv*16) d[i+3]=0; } lc.putImageData(img,0,0); };
const clamp = (v,a,b) => v<a?a:(v>b?b:v);
const seg = (p,a,b) => clamp((p-a)/(b-a),0,1);
const eo = (x) => 1-(1-x)*(1-x);
const bob = (t,sp) => (Math.sin(t*(sp||2.4))>0.3?1:0);
const blink = (t,k) => ((t+(k||0))%3.4)<0.14;
const cyc = (t,per) => (t%per)/per;
const room = (W,H,o) => { const r=o&&o.rage, fl=r&&(Math.floor(o._t*8)%3===0);
 R(0,0,W,H, r?'#1e0810':P.wall0);
 const g1=r?'#3a0e1c':P.wall1, g2=r?'#561428':P.wall2, g3=r?(fl?'#8a2238':'#701c30'):P.glow;
 dell(W/2,-4,W*0.62,H*0.62,g1,0.5); ell(W/2,-4,W*0.55,H*0.55,g1);
 dell(W/2,-4,W*0.42,H*0.42,g2,0.5); ell(W/2,-4,W*0.36,H*0.36,g2);
 dell(W/2,-4,W*0.22,H*0.24,g3,0.5); ell(W/2,-4,W*0.17,H*0.19,g3);
 const wp=r?'#4a1020':P.paper; for (let y=6;y<H;y+=12) for (let x=((y/12)%2<1?4:10); x<W; x+=12) { px(x,y,wp); px(x-1,y+1,wp); px(x+1,y+1,wp); px(x,y+2,wp); }
 drect(0,0,6,H,P.ink,0.5); drect(W-6,0,6,H,P.ink,0.5);
 R(W/2,0,1,3,P.goldDk); };
const table = (W,H,TY) => { R(0,TY,W,1,P.woodHi); R(0,TY+1,W,2,P.wood); R(0,TY+3,W,1,P.woodDk); R(0,TY+4,W,H-TY-4,P.felt1); dell(W/2,TY+16,W*0.4,9,P.felt2,0.5); ell(W/2,TY+16,W*0.3,6,P.felt2); for (let x=3;x<W;x+=7) px(x,TY+8+((x*7)%9),P.felt0); };
const cardB = (x,y) => { R(x,y,7,10,P.cream); R(x+1,y+1,5,8,P.redDk); px(x+3,y+3,P.red); px(x+2,y+4,P.red); px(x+4,y+4,P.red); px(x+3,y+5,P.red); px(x+3,y+7,P.gold); };
const cardF = (x,y,n,suit,col) => { R(x,y,12,17,P.cream); R(x+10,y+1,1,16,P.creamSh); text(n,x+1,y+1,col,1); bmp(PIP5[suit],x+4,y+10,col); };
const mk = (W,H) => { if (typeof OffscreenCanvas!=='undefined') return new OffscreenCanvas(W,H); const e=document.createElement('canvas'); e.width=W; e.height=H; return e; };
const render = (el, sc, t, o) => { const W=el.width, H=el.height, ctx=el.getContext('2d'); ctx.imageSmoothingEnabled=false; o._t=t;
 if (sc.raw) { use(ctx); sc.raw(t,W,H); return; }
 if (!el._L || el._L.width!==W) el._L=mk(W,H);
 const L=el._L, lc=L.getContext('2d',{willReadFrequently:true});
 const sh=sc.shake?sc.shake(t):0, ox=sh?Math.round((Math.random()*2-1)*sh):0, oy=sh?Math.round((Math.random()*2-1)*sh):0;
 use(ctx); ctx.clearRect(0,0,W,H); sc.bg(t,W,H);
 const lv=sc.fade?sc.fade(t):1;
 const layer=(fn,f)=>{ if(!fn) return; lc.clearRect(0,0,W,H); use(lc); fn(t,W,H); outline(lc,W,H); if (f<1) fadeL(lc,W,H,f); ctx.drawImage(L,ox,oy); use(ctx); };
 layer(sc.back,lv); use(ctx); if (sc.table) sc.table(t,W,H); layer(sc.front,lv); layer(sc.top,1); use(ctx); if (sc.fx) sc.fx(t,W,H); };
const S = {};

S.soldier = (o) => { const suit=o.suit||'heart'; const SU={spade:{c:P.black,hi:P.blackHi,n:'9',tip:P.greyHi},club:{c:P.black,hi:P.blackHi,n:'7',tip:P.greyHi},diamond:{c:P.red,hi:P.redHi,n:'5',tip:P.redHi},heart:{c:P.red,hi:P.redHi,n:'10',tip:P.redHi}}[suit]; const act=o.mode==='action';
 const st=(t)=>{ const p=cyc(t,2.4), wind=seg(p,.05,.35), strike=seg(p,.35,.45), rec=seg(p,.6,.95); let wy=0,lean=0,reach=0,grab=false,ex=0;
  if (act) { if (suit==='spade') wy=(-10*eo(wind)+14*strike)*(1-rec); else if (suit==='club') wy=(-10*eo(wind)+6*strike)*(1-rec); else if (suit==='heart') wy=(-8*eo(wind)+8*strike)*(1-rec); else { reach=eo(seg(p,.2,.4))*(1-seg(p,.55,.8)); grab=p>.42&&p<.92; ex=p<.2?(Math.floor(t*6)%2?1:-1):0; }
   if (wind>0&&strike<1&&suit!=='diamond') lean=-1; }
  return {p,wind,strike,rec,wy,lean,reach,grab,ex}; };
 return { bg:(t,W,H)=>room(W,H,o), table:(t,W,H)=>table(W,H,84),
  back:(t)=>{ const s=st(t), b=bob(t), y0=26+b+s.lean, top=10+s.wy;
   R(97,top+9,2,84-top-9,P.wood); R(98,top+9,1,84-top-9,P.woodHi); bmp(PIP9[suit],94,top,SU.tip);
   bmp(PIP9[suit],55,y0-12,SU.c,2); R(58,y0-9,2,4,SU.hi);
   ell(64,y0+8,6,6,P.skinSh); ell(64,y0+9,6,5,P.skin);
   if (blink(t,0.3)) { R(61,y0+8,2,1,P.ink); R(66,y0+8,2,1,P.ink); } else { R(61+s.ex,y0+7,1,2,P.ink); R(67+s.ex,y0+7,1,2,P.ink); }
   R(61,y0+11,6,1,P.hair); px(60,y0+12,P.hair); px(67,y0+12,P.hair); px(59,y0+10,P.blush); px(69,y0+10,P.blush);
   const y=y0+14, h=92-y; R(44,y,40,h,P.cream); R(80,y+1,3,h,P.creamSh); R(44,y,40,1,SU.c); R(44,y,1,h,SU.c); R(83,y,1,h,SU.c);
   text(SU.n,47,y+3,SU.c,1); bmp(PIP5[suit],47,y+11,SU.c); bmp(PIP9[suit],55,y+15,SU.c,2);
   poly([[44,y+2],[37,y+4],[33,y+20],[41,y+22],[44,y+12]],SU.c); poly([[84,y+2],[91,y+4],[95,y+20],[87,y+22],[84,y+12]],SU.c); },
  front:(t)=>{ const s=st(t), b=bob(t), y=26+b+s.lean+14, hy=72+s.wy*0.6;
   poly([[87,y+18],[95,y+20],[100,hy+1],[95,hy+3]],SU.c); ell(98,hy,3,3,P.white);
   if (s.reach<0.05) { poly([[33,y+18],[41,y+21],[47,83],[39,86]],SU.c); cardB(38,75); cardB(43,74); cardB(48,75); ell(46,85,4,3,P.white); }
   else { const hx=46+(64-46)*s.reach, hy2=85+(100-85)*s.reach, sz=3+6*s.reach; poly([[33,y+18],[41,y+21],[hx+sz,hy2],[hx-sz,hy2+3]],SU.c); if (s.grab) cardF(hx-6,hy2-sz-14,'4','heart',P.red); ell(hx,hy2,Math.round(sz+1),Math.round(sz),P.white); R(hx-sz+1,hy2-1,Math.round(sz*2-1),1,P.creamSh); } },
  shake:(t)=>{ if(!act) return 0; const p=cyc(t,2.4); return (p>.44&&p<.56&&suit!=='diamond')?2:0; },
  fx:(t)=>{ if(!act) return; const s=st(t), p=s.p;
   if (suit==='spade' && p>.42 && p<.8) { const e=seg(p,.42,.8); for (let i=0;i<8;i++) { const dx=(i-3.5)*(2+e*7), yy=84-e*16*(1-(i%3)*.25)+e*e*20; R(98+dx,yy,2,2,i%2?P.wood:P.woodHi); } stext('DIG!',72,24,P.goldHi,1); }
   if (suit==='club' && p>.3 && p<.8) { const e=seg(p,.3,.46); if (p<.47) { const sc=1+Math.round(e*4), cx=96+(64-96)*e, cy=14+(70-14)*e; bmp(PIP9.club,cx-4.5*sc,cy-4.5*sc,P.greyHi,sc); } else { const r=4+seg(p,.47,.7)*22; for (let k=0;k<12;k++) { const a=k*Math.PI/6; line(64+Math.cos(a)*r*0.5,96+Math.sin(a)*r*0.4,64+Math.cos(a)*r,96+Math.sin(a)*r*0.8,P.goldHi); } stext('+2',53,86,P.goldHi,2); } }
   if (suit==='heart' && p>.36 && p<.8) { const e=seg(p,.36,.52); for (let k=0;k<=e;k+=0.01) { const x=10+108*k, y=70-Math.sin(k*Math.PI)*18; R(x,y,2,2,(e-k)<0.12?P.white:P.redHi); } if (p>.45) stext('OFF WITH IT!',28,6,P.redHi,1); }
   if (suit==='diamond' && s.grab) { const hx=46+(64-46)*s.reach, hy2=85+(100-85)*s.reach; if (Math.floor(t*8)%2) px(hx+3,hy2-22,P.goldHi); if (p>.6) stext('MINE!',74,22,P.goldHi,1); } } }; };

S.cheshire = (o) => { const act=o.mode==='action';
 const st=(t)=>{ const p=cyc(t,3.2); let f=(Math.sin(t*0.9)>0.9)?0.7:1, gy=0, gw=0, gone=0; if (act) { const out=seg(p,.05,.3), inn=seg(p,.62,.88); f=Math.min(1,1-out+inn); const mid=seg(p,.3,.5)*(1-inn); gy=Math.round(10*mid); gw=Math.round(7*mid); gone=out*(1-inn); } return {p,f,gy,gw,gone}; };
 const grin=(cx,cy,rx,ry)=>{ const inC=(x,y)=>{ const a=((x-cx)/(rx+0.5))**2+((y-cy)/(ry+0.5))**2<=1, b=((x-cx)/(rx+0.5))**2+((y-(cy-4))/(ry+0.5))**2<=1; return a&&!b; }; for (let y=cy-ry;y<=cy+ry;y++) for (let x=cx-rx;x<=cx+rx;x++) { if (!inC(x,y)) continue; const edge=!inC(x,y-1); const tooth=((x-cx)%4===0)&&inC(x,y+1); px(x,y,(edge||tooth)?P.ink:P.white); } };
 return { bg:(t,W,H)=>room(W,H,o), table:(t,W,H)=>table(W,H,84), fade:(t)=>st(t).f,
  back:(t)=>{ const b=bob(t,1.6), cy=48+b;
   for (let i=0;i<=16;i++) { const tt=i/16, x=94+tt*22+Math.sin(t*2+tt*5)*5*tt, y=88-tt*52, r=Math.max(2,Math.round(6-tt*3)); circ(x,y,r,i===16?P.greyHi:((i%4<2)?P.grey:P.plum)); }
   ell(64,88,34,14,P.grey); R(44,80,4,8,P.plum); R(58,78,4,10,P.plum); R(72,78,4,10,P.plum); R(86,80,4,8,P.plum);
   poly([[40,cy-10],[44,cy-32],[58,cy-18]],P.grey); poly([[44,cy-14],[46,cy-26],[54,cy-17]],P.pinkDk);
   poly([[88,cy-10],[84,cy-32],[70,cy-18]],P.grey); poly([[84,cy-14],[82,cy-26],[74,cy-17]],P.pinkDk);
   poly([[38,cy+2],[28,cy+12],[42,cy+12]],P.grey); poly([[90,cy+2],[100,cy+12],[86,cy+12]],P.grey);
   ell(64,cy,28,20,P.greyDk); ell(64,cy+1,27,19,P.grey); ell(64,cy+9,20,9,P.greyHi);
   R(62,cy-20,4,8,P.plum); R(52,cy-18,3,6,P.plum); R(73,cy-18,3,6,P.plum); R(37,cy-4,7,2,P.plum); R(38,cy+2,6,2,P.plum); R(84,cy-4,7,2,P.plum); R(84,cy+2,6,2,P.plum); },
  front:(t)=>{ ell(50,87,7,3,P.grey); ell(78,87,7,3,P.grey); for (const x of [46,50,54,74,78,82]) px(x,89,P.greyDk); },
  top:(t)=>{ const s=st(t), b=bob(t,1.6), cy=48+b+s.gy;
   if (blink(t,1.1)&&!s.gone) { R(47,cy-4,13,1,P.ink); R(69,cy-4,13,1,P.ink); }
   else { ell(53,cy-4,6,5,P.gold); ell(75,cy-4,6,5,P.gold); R(49,cy-7,3,1,P.goldHi); R(71,cy-7,3,1,P.goldHi); const pw=s.gone>0.5?3:1; R(53-(pw>>1),cy-8,pw,9,P.ink); R(75-(pw>>1),cy-8,pw,9,P.ink); }
   poly([[61,cy+3],[67,cy+3],[64,cy+6]],P.pink);
   grin(64,cy+11,19+s.gw,7+(s.gw>>1)); },
  fx:(t)=>{ if (!act) return; const s=st(t); if (s.gone>0.6) { const k=Math.floor(t*6)%3; stext('?',16,34+k,P.lav,2); stext('?',104,30+((k+1)%3),P.lav,2); stext('??',52,96,P.lav,2); } } }; };

S.knave = (o) => { const act=o.mode==='action';
 const st=(t)=>{ const p=cyc(t,3); let reach=0, card=false, wink=false, look=false, tuck=0; if (act) { reach=eo(seg(p,.15,.35))*(1-seg(p,.55,.78)); card=p>.36&&p<.86; tuck=seg(p,.78,.86); wink=p>.84&&p<.98; look=p>.03&&p<.16; } return {p,reach,card,wink,look,tuck}; };
 return { bg:(t,W,H)=>room(W,H,o), table:(t,W,H)=>table(W,H,84),
  back:(t)=>{ const s=st(t), b=bob(t), hy=42+b, dx=s.look?0:(Math.sin(t*1.7)>0.4?1:(Math.sin(t*1.7)<-0.4?-1:0));
   poly([[38,62+b],[90,62+b],[100,92],[28,92]],P.red); poly([[64,62+b],[90,62+b],[100,92],[64,92]],P.black); R(63,62+b,2,30,P.gold);
   for (let y=66+b;y<92;y+=6) { R(40+((y/6)%2?0:3),y,2,2,P.redDk); R(86-((y/6)%2?0:3),y,2,2,P.blackHi); }
   heart(78,76+b,3,P.red); bmp(PIP5.spade,47,73+b,P.black);
   R(54,55+b,20,8,P.black); R(54,62+b,20,1,P.gold); R(60,51+b,8,5,P.skinSh);
   ell(64,hy-4,15,12,P.hair); R(50,hy-4,4,14,P.hair); R(74,hy-4,4,12,P.hair);
   ell(64,hy,11,12,P.skinSh); ell(64,hy+1,10,11,P.skin);
   R(48,hy-8,5,7,P.cream); px(50,hy-6,P.red); px(49,hy-5,P.red); px(51,hy-5,P.red); px(50,hy-4,P.red);
   if (s.wink) R(67,hy,4,1,P.ink); else { R(67,hy-1,4,2,P.white); R(68+dx+(s.look?1:0),hy-1,2,2,P.ink); }
   line(66,hy-5,72,hy-7,P.hair); if (s.wink) R(57,hy,4,1,P.ink); else { R(57,hy-1,4,2,P.white); R(58+dx+(s.look?1:0),hy-1,2,2,P.ink); } line(56,hy-4,61,hy-3,P.hair);
   poly([[51,hy-10],[71,hy-15],[77,hy-8],[69,hy-10],[63,hy-7],[58,hy-5],[55,hy-7],[52,hy-5]],P.hair); line(56,hy-11,70,hy-14,P.hairHi);
   ell(70,hy-14,14,4,P.red); R(57,hy-12,26,2,P.redDk); bmp(PIP5.heart,78,hy-18,P.gold);
   line(60,hy+6,66,hy+6,P.redDk); px(67,hy+5,P.redDk); if (s.wink) { px(68,hy+4,P.redDk); } px(58,hy+3,P.blush); },
  front:(t)=>{ const s=st(t), b=bob(t);
   R(36,80,12,6,P.red); R(36,80,12,1,P.gold); ell(50,87,4,3,P.skin); cardB(46,77); cardB(50,76);
   if (!act) { const k=cyc(t,1.4); if (k<0.5) { const e=k/0.5, x=52+24*e, y=74-Math.sin(e*Math.PI)*12; cardB(x,y); } }
   const hx=78+(64-78)*s.reach, hy=87+(102-87)*s.reach, sz=3+7*s.reach;
   poly([[84,64+b],[94,66+b],[hx+sz+1,hy-1],[hx-sz,hy+2]],P.black); R(Math.round(hx-sz-1),Math.round(hy-sz-2),Math.round(sz*2+2),2,P.gold);
   if (s.card && s.tuck<1) { const cx=hx-6+(s.tuck*14), cy=hy-sz-16-(s.tuck*20); cardF(cx,cy,'A','heart',P.red); }
   ell(hx,hy,Math.round(sz+1),Math.round(sz),P.skin); R(hx-sz+1,hy+1,Math.round(sz*2-1),1,P.skinSh); },
  fx:(t)=>{ if (!act) return; const s=st(t); if (s.card&&s.tuck<1&&Math.floor(t*8)%2) { px(70,60,P.goldHi); px(58,66,P.goldHi); } if (s.p>.6&&s.p<.98) stext('YOINK!',90,16,P.goldHi,1); } }; };

S.hatter = (o) => { const act=o.mode==='action';
 const st=(t)=>{ const p=cyc(t,3.2); let lift=0, swap=0, hat=0, raise=0; if (act) { swap=seg(p,.15,.5); hat=Math.sin(seg(p,.3,.55)*Math.PI)*5; raise=Math.sin(seg(p,.5,.85)*Math.PI); } else { lift=Math.sin(seg(cyc(t,3.6),.55,.95)*Math.PI); } return {p,lift,swap,hat,raise}; };
 return { bg:(t,W,H)=>room(W,H,o), table:(t,W,H)=>table(W,H,84),
  back:(t)=>{ const s=st(t), b=bob(t), hy=50+b, tl=(!act&&Math.sin(t*0.9)>0.6)?1:0, h0=hy-8-Math.round(s.hat);
   poly([[36,66+b],[92,66+b],[102,92],[26,92]],P.plum); poly([[56,66+b],[64,84],[52,92],[44,70+b]],P.plumHi); poly([[72,66+b],[64,84],[76,92],[84,70+b]],P.plumHi); R(58,63+b,12,9,P.cream);
   poly([[64,67+b],[53,61+b],[53,73+b]],P.mustard); poly([[64,67+b],[75,61+b],[75,73+b]],P.mustard); R(62,65+b,4,4,P.goldDk); px(56,64+b,P.redDk); px(56,69+b,P.redDk); px(72,64+b,P.redDk); px(72,69+b,P.redDk);
   R(60,58+b,8,6,P.skinSh);
   circ(46,hy+2,7,P.white); circ(82,hy+2,7,P.white); circ(49,hy+9,5,P.white); circ(79,hy+9,5,P.white); px(44,hy,P.greyHi); px(84,hy+1,P.greyHi);
   ell(64,hy,12,13,P.skinSh); ell(64,hy+1,11,12,P.skin);
   if (blink(t,2)||o.sleep) { R(55,hy-1,6,1,P.ink); R(68,hy-1,4,1,P.ink); } else { circ(58,hy-1,3,P.white); R(58,hy-1,2,2,P.ink); circ(70,hy-1,2,P.white); px(70,hy-1,P.ink); }
   line(53,hy-6,61,hy-5,P.white); line(67,hy-5,74,hy-7,P.white); R(64,hy+1,1,4,P.skinSh);
   if (o.sleep) { ell(64,hy+7,2,2,P.ink); } else { R(57,hy+6,14,3,P.ink); R(58,hy+6,12,1,P.white); } px(55,hy+4,P.blush); px(73,hy+4,P.blush);
   if (s.hat<1) { R(54,h0+1,20,1,P.skinSh); circ(50,h0+2,3,P.white); circ(78,h0+2,3,P.white); } R(41+tl,h0-2,46,3,P.greenDk); px(41+tl,h0-3,P.greenDk); px(86+tl,h0-3,P.greenDk); R(44+tl,h0-2,40,1,P.green); poly([[50+tl,h0-2],[78+tl,h0-2],[82+tl,h0-32],[46+tl,h0-32]],P.green); R(50+tl,h0-30,3,26,P.greenHi); R(48+tl,h0-10,33,4,P.plumHi);
   R(66+tl,h0-21,17,8,P.cream); mtext('10/6',67+tl,h0-20,P.ink); },
  front:(t)=>{ const s=st(t), b=bob(t);
   const dy=s.swap*26; for (let i=0;i<3;i++) cardB(54+i*5,90+dy-i); if (act&&s.swap>0) { cardF(52,116-dy,'9','spade',P.black); cardF(64,117-dy,'J','heart',P.red); }
   R(34,82,12,5,P.plum); ell(46,87,4,3,P.skin);
   const lift=Math.max(s.lift,s.raise), cx=86-14*s.lift, cy=82-22*lift; R(80,89,16,2,P.white);
   poly([[90,70+b],[98,72+b],[cx+5,cy+3],[cx-2,cy+5]],P.plum); R(cx-5,cy-5,10,7,P.white); R(cx-5,cy-3,10,1,P.pink); R(cx+5,cy-4,2,1,P.white); R(cx+6,cy-4,1,3,P.white); R(cx+5,cy-2,2,1,P.white); ell(cx+2,cy+2,3,2,P.skin);
   if (lift<0.2) for (let i=0;i<3;i++) { const sy=(t*10+i*5)%14; px(cx-2+i*2+Math.round(Math.sin(t*3+i)),cy-7-sy,P.steam); } },
  fx:(t)=>{ if (!act) return; const s=st(t); if (s.p>.12&&s.p<.55) { for (let i=0;i<4;i++) line(36+i*4,96,36+i*4,104,P.goldHi); for (let i=0;i<4;i++) line(80+i*4,96,80+i*4,104,P.goldHi); } if (s.p>.25&&s.p<.9) { stext('MOVE',6,40,P.mustard,1); stext('DOWN!',6,50,P.mustard,1); } } }; };

S.queen = (o) => { const md=o.mode, act=md==='action', rage=md==='rage'||!!o.rage, sold=(md==='bonk'||md==='pilfer'||md==='dig'), laugh=md==='laugh', hl=!!o.headless;
 const st=(t)=>{ const p=cyc(t,sold?2.6:3.4); let fl=0, rise=0, open=0, pt=0, sy=0, grab=false;
  if (act) { fl=seg(p,.0,.2)*(1-seg(p,.85,1)); rise=Math.round(3*seg(p,.18,.3)*(1-seg(p,.75,.9))); open=Math.round(4*seg(p,.2,.3)*(1-seg(p,.7,.8))); pt=eo(seg(p,.22,.36))*(1-seg(p,.72,.9)); }
  if (sold) { const wind=seg(p,.05,.35), strike=seg(p,.35,.45), rec=seg(p,.6,.95); if (md==='dig') sy=(-12*eo(wind)+16*strike)*(1-rec); if (md==='bonk') sy=(-12*eo(wind)+6*strike)*(1-rec); if (md==='pilfer') { pt=eo(seg(p,.2,.4))*(1-seg(p,.55,.8)); grab=p>.42&&p<.92; } fl=0.2; }
  if (rage) { fl=1; open=Math.floor(t*4)%2?1:0; }
  if (laugh) { open=Math.floor(t*8)%2?3:1; rise=Math.floor(t*8)%2; }
  return {p,fl,rise,open,pt,sy,grab}; };
 return { bg:(t,W,H)=>room(W,H,{rage:rage||(act&&st(t).p>.25&&st(t).p<.75),_t:t}), table:(t,W,H)=>table(W,H,84),
  shake:(t)=>{ const s=st(t); if (sold) return (s.p>.44&&s.p<.56&&md!=='pilfer')?2:0; return (act&&s.p>.3&&s.p<.6)?2:(rage&&Math.floor(t*12)%7===0?1:0); },
  back:(t)=>{ const s=st(t), b=bob(t,1.8)-s.rise, hy=44+b, hc=rage?(Math.floor(t*6)%2?P.redDk:P.qhair):P.qhair, hh=rage?P.redHi:P.qhairHi, sk=s.fl>0.5?P.flush:P.qskin;
   if (!hl) { circ(45,22+b,19,hc); circ(83,22+b,19,hc); poly([[26,26+b],[102,26+b],[64,74+b]],hc); circ(40,14+b,4,hh); R(36,20+b,2,6,hh); circ(78,12+b,3,hh); }
   poly([[28,64+b],[100,64+b],[110,92],[18,92]],P.red); for (const q of [[30,74],[44,84],[80,84],[94,74],[38,88],[88,88]]) bmp(PIP5.heart,q[0],q[1]+b,P.redDk); R(62,64+b,4,28,P.gold); R(63,64+b,2,28,P.goldHi);
   poly([[38,62+b],[90,62+b],[96,50+b],[32,50+b]],P.white); for (let i=0;i<8;i++) R(35+i*8,51+b,3,10,'#f0c8cc'); R(38,61+b,52,1,P.redDk);
   if (hl) { ell(64,52+b,7,2,P.redDk); return; }
   R(60,54+b,8,6,P.qskinSh);
   ell(64,hy,11,13,P.qskinSh); ell(64,hy+1,10,12,sk);
   poly([[52,hy-12],[76,hy-12],[76,hy-5],[64,hy-9],[52,hy-5]],hc);
   R(54,hy-15,20,4,P.gold); R(55,hy-14,18,1,P.goldHi); poly([[54,hy-15],[57,hy-22],[60,hy-15]],P.gold); poly([[61,hy-15],[64,hy-25],[67,hy-15]],P.gold); poly([[68,hy-15],[71,hy-22],[74,hy-15]],P.gold); px(57,hy-21,P.redHi); px(64,hy-24,P.redHi); px(71,hy-21,P.redHi); bmp(PIP5.heart,62,hy-15,P.red);
   const pc=rage?P.redHi:P.ink;
   if (laugh) { for (const ex of [59,69]) { px(ex-2,hy,P.ink); px(ex-1,hy-1,P.ink); px(ex,hy-1,P.ink); px(ex+1,hy,P.ink); } }
   else if (blink(t,0.7)&&!act&&!rage&&!sold) { R(56,hy,7,1,P.ink); R(66,hy,7,1,P.ink); }
   else { R(57,hy-1,5,2,P.white); R(67,hy-1,5,2,P.white); R(59,hy-1,2,2,pc); R(69,hy-1,2,2,pc); if (!(act||rage)) { R(56,hy-2,7,1,P.ink); R(66,hy-2,7,1,P.ink); } px(55,hy-2,P.ink); px(73,hy-2,P.ink); }
   const bd=(act&&s.fl>0.5)||rage||sold?2:0; line(55,hy-5-bd,62,hy-3,P.qhair); line(73,hy-5-bd,66,hy-3,P.qhair);
   R(56,hy+4,2,2,P.blush); R(71,hy+4,2,2,P.blush);
   if (s.open>0) { ell(64,hy+8,3,1+s.open,P.ink); R(62,hy+7,5,1,P.red); } else bmp(PIP5.heart,62,hy+5,P.red); },
  front:(t)=>{ const s=st(t), b=bob(t,1.8)-s.rise, sy=Math.round(s.sy);
   R(32,80,14,6,P.red); R(32,80,14,1,P.gold); ell(46,87,4,3,P.qskin);
   R(97,40+b+sy,2,48,P.gold); R(98,40+b+sy,1,48,P.goldHi); circ(98,34+b+sy,6,P.gold); heart(98,34+b+sy,4,P.red); px(97,33+b+sy,P.redHi);
   const hx=98+(76-98)*s.pt, hy=80+sy+(100-80-sy)*s.pt, sz=3+8*s.pt;
   poly([[90,66+b],[100,68+b],[hx+sz+1,hy],[hx-sz,hy+3]],P.red); R(Math.round(hx-sz-1),Math.round(hy-sz-2),Math.round(sz*2+2),2,P.gold);
   if (s.grab) cardF(hx-6,hy-sz-15,'7','club',P.black);
   ell(hx,hy,Math.round(sz+1),Math.round(sz),P.qskin); if (s.pt>0.5&&!sold) { circ(hx,hy-1,Math.round(sz*0.45),P.qskinSh); circ(hx,hy-2,Math.round(sz*0.3),P.qskin); px(hx,hy-3,P.white); } },
  fx:(t)=>{ const s=st(t), p=s.p;
   if ((act&&p>.2&&p<.85)||rage) { for (let i=0;i<3;i++) { const k=(t*1.5+i/3)%1; circ(46-k*8+i*2,26-k*20,2+Math.round(k*2),P.steam); circ(82+k*8-i*2,26-k*20,2+Math.round(k*2),P.steam); } }
   if (act&&p>.26&&p<.82) { const L=o.bubble||['OFF WITH','ITS HEAD!']; R(3,3,62,24,P.white); R(3,3,62,1,P.ink); R(3,26,62,1,P.ink); R(3,3,1,24,P.ink); R(64,3,1,24,P.ink); poly([[40,27],[50,27],[52,34]],P.white); text(L[0],6+(Math.floor(t*12)%2),6,P.red,1); text(L[1],6,16,P.red,1); }
   if (laugh) stext('HA HA HA!',10+(Math.floor(t*8)%2),6,P.redHi,1);
   if (md==='bonk'&&p>.3&&p<.8) { const e=seg(p,.3,.46); if (p<.47) { const cx=98+(64-98)*e, cy=34+(80-34)*e; heart(cx,cy,3+Math.round(e*9),P.redHi); } else { const r=4+seg(p,.47,.7)*22; for (let k=0;k<12;k++) { const a=k*Math.PI/6; line(64+Math.cos(a)*r*0.5,96+Math.sin(a)*r*0.4,64+Math.cos(a)*r,96+Math.sin(a)*r*0.8,P.goldHi); } stext('+2',53,86,P.goldHi,2); } }
   if (md==='dig'&&p>.42&&p<.8) { const e=seg(p,.42,.8); for (let i=0;i<8;i++) { const dx=(i-3.5)*(2+e*7), yy=84-e*16*(1-(i%3)*.25)+e*e*20; R(98+dx,yy,2,2,i%2?P.wood:P.woodHi); } stext('BURIED!',4,8,P.goldHi,1); }
   if (md==='pilfer'&&s.grab&&p>.55) stext('MINE.',8,8,P.goldHi,1);
   if (hl) { const hp=o.hp===undefined?1:o.hp; if (hp>0) { const fall=seg(hp,0,.65), y=Math.round(hp<.65?36+52*fall*fall:88-Math.sin(seg(hp,.65,.82)*Math.PI)*7), spin=hp<.82?Math.cos(hp*22):1, w=Math.max(1,Math.round(Math.abs(spin)*16)), x=64+(hp<.82?Math.round(Math.sin(hp*9)*6):0); R(x-w/2-1,y-12,w+2,24,P.ink); R(x-w/2,y-11,w,22,P.cream); if (spin>0&&w>10) { heart(x,y-4,5,P.qhair); circ(x,y-1,3,P.qskin); R(x-3,y-8,7,2,P.gold); px(x-1,y-1,P.ink); px(x+1,y-1,P.ink); px(x,y+2,P.red); text('Q',x-7,y-10,P.red,1); } else if (w>4) { R(x-w/2+1,y-10,w-2,20,P.redDk); } } } } }; };

S.alice = (o) => { const act=o.mode==='action', TY=34;
 const st=(t)=>{ if (!act) return {ph:'idle',e:0,tt:t}; const p=t%6; if (p<2) return {ph:'hit',e:p/2,tt:t}; if (p<4) return {ph:'pump',e:(p-2)/2,tt:t}; return {ph:'stay',e:(p-4)/2,tt:t}; };
 const hand=(x,y,dir,kind,t,drum)=>{ if (kind==='fist') { ell(x,y,8,7,P.skin); for (let i=0;i<4;i++) R(x-6+i*4,y-7,3,3,P.skinSh); R(x-7,y-1,14,1,P.skinSh); R(dir>0?x+6:x-9,y-3,3,5,P.skin); return; }
   R(dir>0?x+7:x-11,y-2,4,3,P.skin);
   if (kind==='flat') { R(x-8,y-13,16,10,P.skin); for (let i=1;i<4;i++) R(x-8+i*4,y-12,1,8,P.skinSh); R(x-8,y-13,16,1,P.skinHi); ell(x,y,9,6,P.skin); R(x-6,y+3,12,2,P.skinSh); return; }
   const idx=dir>0?3:0;
   for (let i=0;i<4;i++) { const fx=x-7+i*4; if (kind==='point'&&i!==idx) { R(fx,y-8,3,3,P.skinSh); continue; } const up=(drum===i)?2:0, h=(kind==='point')?13:6, top=y-4-h-up; R(fx,top,3,h+2,P.skin); px(fx+1,top,P.skinHi); }
   ell(x,y,9,6,P.skin); R(x-6,y+3,12,2,P.skinSh); };
 return { bg:(t,W,H)=>{ R(0,0,W,TY,P.wall0); dell(W/2,-4,W*0.4,TY,P.wall1,0.5); ell(W/2,-4,W*0.32,TY-6,P.wall1); for (let x=6;x<W;x+=12) { px(x,10,P.paper); px(x-1,11,P.paper); px(x+1,11,P.paper); px(x,12,P.paper); } R(0,TY,W,2,P.woodHi); R(0,TY+2,W,3,P.wood); R(0,TY+5,W,1,P.woodDk); R(0,TY+6,W,H-TY-6,P.felt1); dell(W/2,70,52,26,P.felt2,0.5); ell(W/2,70,40,20,P.felt2); for (let x=4;x<W;x+=9) px(x,TY+12+((x*5)%40),P.felt0);
   cardB(100,46); cardB(101,45); cardB(102,44);
   const s=st(t); cardF(44,58,'10','heart',P.red); cardF(58,58,'7','club',P.black);
   if (s.ph==='hit') { const e=seg(s.e,.45,.75); if (e>0) cardF(102+(72-102)*e,44+(58-44)*e,'4','diamond',P.red); }
   if (s.ph==='pump'||s.ph==='stay') cardF(72,58,'4','diamond',P.red);
   if (s.ph==='pump') { if (Math.floor(t*8)%2) { px(42,56,P.goldHi); px(86,60,P.goldHi); px(64,54,P.goldHi); } }
  },
  front:(t)=>{ const s=st(t), drumL=Math.floor(t*7)%6, drumR=Math.floor(t*7+3)%6;
   ell(10,106,20,13,P.lavDk); ell(12,104,18,11,P.lav); ell(26,98,7,5,P.white);
   hand(36,90,1,'rest',t,act?-1:drumL);
   ell(118,106,20,13,P.lavDk); ell(116,104,18,11,P.lav); ell(102,98,7,5,P.white);
   if (s.ph==='idle') hand(92,90,-1,'rest',t,drumR);
   else if (s.ph==='hit') { const tap=(s.e<.5)?((Math.floor(s.e*8)%2)?2:0):0, y=80+tap; poly([[104,98],[110,92],[96,y+2],[90,y+6]],P.lav); hand(92,y,-1,'point',t,-1); }
   else if (s.ph==='pump') { const e=Math.sin(Math.min(1,s.e*2)*Math.PI*2)*0.5+0.5, y=86-18*e; poly([[104,100],[112,94],[96,y+4],[88,y+8]],P.lav); hand(92,y,-1,'fist',t,-1); }
   else { const x=92+Math.round(Math.sin(s.tt*12)*6); poly([[104,98],[112,92],[x+4,86],[x-4,90]],P.lav); hand(x,84,-1,'flat',t,-1); } },
  fx:(t)=>{ const s=st(t); if (s.ph==='pump') stext('21!',50+(Math.floor(t*10)%2),40,P.goldHi,2); if (s.ph==='stay') stext('STAY',94,40,P.cream,1); if (s.ph==='hit'&&s.e<.5) stext('HIT',96,40,P.cream,1); } }; };

S.title = (o) => ({ raw:(t,W,H)=>{
 const sky=['#0d0714','#140b1f','#1c102b','#261438','#321848'];
 for (let i=0;i<5;i++) { R(0,i*26,W,26,sky[i]); if (i<4) drect(0,i*26+22,W,4,sky[i+1],0.5); }
 let sd=7; const rnd=()=>{ sd=(sd*16807)%2147483647; return sd/2147483647; };
 for (let i=0;i<46;i++) { const x=Math.floor(rnd()*W), y=Math.floor(rnd()*110), k=rnd()*6; if (Math.sin(t*2.5+k*3)>-0.2) { px(x,y,i%5?P.lav:P.white); if (i%7===0) { px(x-1,y,P.lavDk); px(x+1,y,P.lavDk); px(x,y-1,P.lavDk); px(x,y+1,P.lavDk); } } }
 dell(432,32,26,26,P.glow,0.5); circ(432,32,19,P.goldDk); circ(432,32,17,P.cream); for (let k=0;k<12;k++) { const a=k*Math.PI/6; px(432+Math.cos(a)*15,32+Math.sin(a)*15,P.ink); } const am=t*0.6, ah=t*0.05; line(432,32,432+Math.cos(am-Math.PI/2)*13,32+Math.sin(am-Math.PI/2)*13,P.ink); line(432,32,432+Math.cos(ah-Math.PI/2)*8,32+Math.sin(ah-Math.PI/2)*8,P.redDk); R(430,10,5,4,P.goldDk); circ(432,7,3,P.goldDk); circ(432,7,1,sky[0]);
 circ(214,96,30,'#34102a'); circ(266,96,30,'#34102a'); poly([[182,100],[298,100],[240,150]],'#34102a');
 
 R(0,122,W,14,'#0f2618'); for (let x=-6;x<W;x+=14) { circ(x+7,121+((x/14)%2?1:-1),9,'#163a26'); if ((x/14)%3===0) { px(x+5,117,P.red); px(x+6,118,P.redHi); } if ((x/14)%4===1) { px(x+10,120,P.red); } }
 const HZ=134, img=c.getImageData(0,HZ,W,H-HZ), d=img.data; const A=hx('#5a1e3a'), Bc=hx('#140a1a'), FG=hx('#261438');
 for (let y=0;y<H-HZ;y++) { const z=300/(y+6), wy=z*0.5+t*1.2, fog=clamp(1-y/70,0,1); for (let x=0;x<W;x++) { const wx=(x-W/2)*z/110; const tile=(Math.floor(wx)+Math.floor(wy))&1; let col=tile?A:Bc; if (BAY[y&3][x&3]<fog*16) col=FG; const i=(y*W+x)*4; d[i]=col[0]; d[i+1]=col[1]; d[i+2]=col[2]; d[i+3]=255; } }
 c.putImageData(img,0,HZ);
 for (let i=0;i<8;i++) { const ph=i*0.77, x0=30+i*58, y=((t*(8+i%3*4)+ph*140)%320)-40, x=x0+Math.sin(t*0.8+ph)*12, cw=Math.cos(t*1.6+ph*2), w=Math.max(1,Math.round(Math.abs(cw)*14)), h=20, xx=Math.round(x-w/2); R(xx-1,y-1,w+2,h+2,P.ink); R(xx,y,w,h,P.cream); if (cw<0) { R(xx+1,y+1,w-2,h-2,P.redDk); if (w>6) R(xx+w/2-1,y+8,2,4,P.gold); } else if (w>8) { bmp(PIP5[['heart','spade','diamond','club'][i%4]],xx+w/2-2,y+7,i%2?P.black:P.red); } }
 const T=o.name||'WONDERJACK', sc=6, tx=Math.round((W-tw(T,sc))/2), ty=54+(Math.floor(t*1.5)%2);
 text(T,tx+3,ty+5,'#2a0c20',sc); for (const dd of [[-2,0],[2,0],[0,-2],[0,2],[-2,-2],[2,2],[-2,2],[2,-2]]) text(T,tx+dd[0],ty+dd[1],P.ink,sc);
 text(T,tx,ty,(j)=>['#ffe0ea','#ffb0cc','#ff7fb0','#f0558e','#e0407a','#c02a62','#8a1846'][j],sc);
 const gx=(t*90)%(W+200)-100; for (let k=0;k<3;k++) { const x=Math.round(gx)+k*6; if (x>tx&&x<tx+tw(T,sc)) { R(x,ty+2,2,8,P.white); } }
 const cx=240, cy=38+(Math.floor(t*1.5)%2); R(cx-12,cy,24,5,P.gold); R(cx-11,cy+1,22,1,P.goldHi); poly([[cx-12,cy],[cx-9,cy-9],[cx-6,cy]],P.gold); poly([[cx-3,cy],[cx,cy-12],[cx+3,cy]],P.gold); poly([[cx+6,cy],[cx+9,cy-9],[cx+12,cy]],P.gold); px(cx-9,cy-8,P.redHi); px(cx,cy-11,P.redHi); px(cx+9,cy-8,P.redHi); bmp(PIP5.heart,cx-2,cy,P.red);
 const tg='HIT · STAY · LOSE YOUR HEAD'; stext(tg,Math.round((W-tw(tg,2))/2),108,P.goldHi,2);
 if (!o.noPress&&(t%1.2)<0.8) { const ps='- PRESS START -'; stext(ps,Math.round((W-tw(ps,2))/2),228,P.cream,2); }
 const cw2=Math.cos(t*1.2), w2=Math.max(2,Math.round(Math.abs(cw2)*30)), x2=46-Math.round(w2/2); R(x2-1,177,w2+2,46,P.ink); R(x2,178,w2,44,P.cream); if (cw2<0) { R(x2+2,180,w2-4,40,P.redDk); for (let yy=184;yy<218;yy+=6) if (w2>10) bmp(PIP5.diamond,x2+w2/2-2,yy,P.gold); } else if (w2>14) { text('A',x2+3,181,P.red,1); heart(x2+w2/2,198,6,P.red); }
 const hb=Math.floor(t*2)%2; R(410,232+hb,44,4,P.greenDk); R(410,232+hb,44,1,P.greenHi); poly([[418,232+hb],[446,232+hb],[450,196+hb],[414,196+hb]],P.green); R(418,198+hb,3,32,P.greenHi); R(416,222+hb,33,5,P.plumHi); R(432,206+hb,17,8,P.cream); mtext('10/6',433,207+hb,P.ink);
 for (let i=0;i<3;i++) { const sy=(t*8+i*6)%18; px(440+Math.round(Math.sin(t*2+i)*2),194+hb-sy,P.steam); }
} });

const over = (W,H,col,fn,sh) => { const img=c.getImageData(0,0,W,H), d=img.data, k=hx(col), s=sh||0; for (let y=0;y<H;y++) for (let x=0;x<W;x++) { const lv=fn(x,y); if (lv<=0) continue; if (BAY[y&3][(x+s)&3] < lv*16) { const i=(y*W+x)*4; d[i]=k[0]; d[i+1]=k[1]; d[i+2]=k[2]; } } c.putImageData(img,0,0); };
const bigTable = (W,H) => { const TY=168; R(0,TY,W,2,P.woodHi); R(0,TY+2,W,4,P.wood); R(0,TY+6,W,2,P.woodDk); R(0,TY+8,W,H-TY-8,P.felt1); dell(W/2,TY+44,W*0.42,32,P.felt2,0.5); ell(W/2,TY+44,W*0.34,26,P.felt2); for (let x=5;x<W;x+=11) px(x,TY+14+((x*7)%80),P.felt0); };
let CC = null;
const boss = (t,o,m) => { if (!o.boss || o.boss==='none') return; if (!CC) CC=mk(128,112); const md=(o.mood==='rage'&&o.boss==='queen')?'rage':'idle'; const oo={mode:md,suit:o.suit||'heart'}; const sc=S[o.boss](oo); render(CC,Object.assign({},sc,{bg:()=>{},table:(tt,W2,H2)=>{ c.clearRect(0,84,W2,H2-84); }}),t,oo); use(m); m.imageSmoothingEnabled=false; m.drawImage(CC,112,0,256,224); };
const tint = (t,W,H,md) => { if (md==='rage') over(W,H,'#6a0a1e',(x,y)=>{ const dd=Math.min(x,y,W-1-x,H-1-y); return 0.12+(dd<60?(1-dd/60)*0.45:0); }); };
const mood = (t,W,H,md) => {
 if (md==='tension') { const beat=((t%1.1)<0.12)?0.35:0, lv=0.55+beat; over(W,H,P.ink,(x,y)=>{ const dd=Math.min(x,y,W-1-x,H-1-y); return dd<56?(1-dd/56)*lv:0; }); if (Math.floor(t*12)%19===0) over(W,H,P.ink,()=>0.3); }
 if (md==='rage') { for (let i=0;i<28;i++) { const x=(i*53+Math.sin(t*1.5+i)*12+W)%W, y=H-((t*(18+i%4*6)+i*37)%H); R(x,y,i%3?1:2,1,i%2?P.redHi:P.goldHi); } } };
const cres = (cx,cy,r,dx,dy,col) => { for (let y=cy-r;y<=cy+r;y++) for (let x=cx-r;x<=cx+r;x++) { const a=(x-cx)**2+(y-cy)**2<=r*r, b=(x-cx-dx)**2+(y-cy-dy)**2<=r*r; if (a&&!b) px(x,y,col); } };

S.roomTea = (o) => ({ raw:(t,W,H)=>{ const m=c;
 const sky=['#2a1438','#4a1e48','#7a2e50','#b04a5a','#e0805a']; for (let i=0;i<5;i++) { R(0,i*22,W,22,sky[i]); if (i<4) drect(0,i*22+19,W,3,sky[i+1],0.5); } R(0,110,W,60,sky[4]);
 circ(120,118,28,'#f0a860'); circ(120,118,22,'#ffd08a'); for (let k=0;k<3;k++) R(94,100+k*7,52,2,'#f0a860');
 R(0,114,W,56,'#16351f'); for (let x=-8;x<W;x+=16) { const yy=113+(((x+8)/16)%2?2:-1); circ(x+8,yy,11,'#16351f'); circ(x+6,yy-3,5,'#1f4a2c'); }
 for (let k=0;k<5;k++) ell(40,64+k*10,5+k*3,5,k%2?'#1f4a2c':'#16351f'); R(39,112,3,4,P.woodDk);
 ell(432,98,24,18,'#1f4a2c'); poly([[452,94],[470,74],[475,78],[458,102]],'#1f4a2c'); ell(406,96,6,10,'#16351f'); ell(432,79,11,4,'#245a35'); circ(432,72,3,'#245a35');
 circ(196,126,13,P.goldDk); circ(196,126,11,P.cream); for (let k=0;k<12;k++) { const a=k*Math.PI/6; px(196+Math.cos(a)*9,126+Math.sin(a)*9,P.ink); } line(196,126,196+Math.cos(t*3)*8,126+Math.sin(t*3)*8,P.ink); line(196,126,196+Math.cos(-t*1.3)*5,126+Math.sin(-t*1.3)*5,P.redDk);
 R(140,118,4,50,'#2b1838'); R(170,118,4,50,'#2b1838'); R(140,116,34,6,'#2b1838'); circ(157,112,7,'#2b1838'); R(144,132,26,3,'#2b1838'); circ(157,112,3,'#4a2a5c');
 circ(330,138,16,'#2b1838'); circ(330,138,10,'#16351f'); R(314,140,4,28,'#2b1838'); R(342,140,4,28,'#2b1838');
 for (let s=0;s<2;s++) { const y0=8+s*24, sag=20-s*6; let prev=null; for (let x=0;x<W;x+=2) { const y=Math.round(y0+sag*(1-((x-240)/240)**2)+Math.sin(t*1.1+s+x*0.01)); R(x,y,2,1,'#1a0e20'); } for (let i=0;i<10;i++) { const x=24+i*48+s*24; if (x>=W) continue; const y=Math.round(y0+sag*(1-((x-240)/240)**2)+Math.sin(t*1.1+s+x*0.01)), sx=Math.round(Math.sin(t*2+i+s)*1.5), col=[P.pink,P.goldHi,P.teal][(i+s)%3]; dell(x+sx,y+8,9,9,col,0.15+0.1*Math.sin(t*3+i)); R(x,y,1,3,'#1a0e20'); ell(x+sx,y+8,4,5,col); R(x+sx-4,y+8,9,1,'#ffffff'); R(x+sx-2,y+3,5,1,'#1a0e20'); R(x+sx-2,y+13,5,1,'#1a0e20'); } }
 for (let i=0;i<28;i++) { const x=8+i*17, y=Math.round(52+9*(1-((x-240)/240)**2)), fl=Math.floor(t*4+i)%2, col=[P.red,P.cream,P.black][i%3]; poly([[x-5,y],[x+5,y],[x+fl,y+10]],col); if (i%3===1) px(x,y+3,P.red); } line(0,52,W,52,'#1a0e20');
 for (let i=0;i<3;i++) { const a=t*0.7+i*2.09, x=Math.round(400+Math.cos(a)*38), y=Math.round(130+Math.sin(a)*6-Math.sin(t*2+i)*2); R(x-7,y+5,14,2,P.white); R(x-5,y-1,10,6,P.white); R(x-5,y+1,10,1,P.pink); R(x+5,y,2,1,P.white); R(x+6,y,1,3,P.white); R(x-5,y-1,10,1,'#d8c8e8'); }
 const tx=62, ty=138, cy6=cyc(t,6), rise=Math.sin(seg(cy6,.1,.4)*Math.PI);
 R(36,160,52,8,P.woodDk); R(36,160,52,1,P.woodHi);
 if (rise>0.05) { circ(tx,ty-24-Math.round(rise*8),6,'#9a8a7a'); circ(tx-5,ty-30-Math.round(rise*8),2,P.pinkDk); circ(tx+5,ty-30-Math.round(rise*8),2,P.pinkDk); R(tx-3,ty-24-Math.round(rise*8),2,1,P.ink); R(tx+2,ty-24-Math.round(rise*8),2,1,P.ink); px(tx,ty-21-Math.round(rise*8),P.pink); if (rise>0.6) stext('ZZ',tx+10,ty-46,P.cream,1); }
 ell(tx-32,ty,8,12,'#e8d8f0'); ell(tx-32,ty,4,8,'#16351f');
 poly([[tx+24,ty-4],[tx+44,ty-24],[tx+49,ty-21],[tx+30,ty+6]],'#e8d8f0');
 ell(tx,ty,30,22,'#e8d8f0'); ell(tx+4,ty+12,24,7,'#cfc0dc'); R(tx-29,ty-3,59,4,P.pink); for (let k=-24;k<=24;k+=8) bmp(PIP5.heart,tx+k-2,ty+5,P.pinkDk); circ(tx-12,ty-10,3,P.white);
 ell(tx,ty-22-Math.round(rise*8),14,4,'#e8d8f0'); circ(tx,ty-28-Math.round(rise*8),3,P.pink);
 for (let i=0;i<5;i++) { const k=(t*0.6+i/5)%1, x=tx+48+Math.sin(k*6+i)*3+k*10, y=ty-26-k*40; circ(x,y,1+Math.round(k*3),k>0.7?'#b8a8c8':P.steam); }
 bigTable(W,H); tint(t,W,H,o.mood); boss(t,o,m); use(m); mood(t,W,H,o.mood); } });

S.roomWood = (o) => ({ raw:(t,W,H)=>{ const m=c;
 R(0,0,W,H,'#0a0612'); dell(240,-10,220,130,'#140c24',0.5); ell(240,-10,190,110,'#140c24'); ell(240,-10,120,70,'#1a1030');
 cres(430,30,13,5,-4,'#d8d0f0');
 for (let k=0;k<8;k++) { const bx=20+k*64; for (let y=0;y<168;y++) { const x=Math.round(bx+Math.sin(y*0.04+k)*5); R(x-5,y,10,1,'#150d24'); } line(bx,40+k*7,bx+(k%2?34:-34),18+k*3,'#150d24'); line(bx,41+k*7,bx+(k%2?34:-34),19+k*3,'#150d24'); }
 const fs=Math.floor(t*6); over(W,H,'#2a1a40',(x,y)=>{ if (y<84||y>150) return 0; const top=96+5*Math.sin((x+t*14)*0.04); if (y<top) return 0; return 0.45*(1-Math.abs(y-120)/30); },fs);
 for (const q of [[56,28],[150,20],[330,22],[424,30]]) { const bx=q[0], w=q[1]; for (let y=10;y<168;y++) { const x=Math.round(bx+Math.sin(y*0.06+bx)*8); R(x-w/2,y,w,1,'#22143a'); px(x-w/2+((y*3)%w),y,'#2e1c4a'); px(x-w/2,y,'#2e1c4a'); } poly([[bx-w,168],[bx-w/2,150],[bx,168]],'#22143a'); poly([[bx,168],[bx+w/2,150],[bx+w,168]],'#22143a'); }
 const eyes=[[100,60],[200,40],[280,90],[370,52],[470,100],[20,110],[250,130]]; eyes.forEach((e,i)=>{ if (Math.sin(t*0.9+i*2.3)>0.35 && !(((t+i)%2.7)<0.12)) { const col=i%2?P.goldHi:P.teal; R(e[0],e[1],2,1,col); R(e[0]+5,e[1],2,1,col); } });
 if (o.boss!=='cheshire') { const p=cyc(t,8); if (p>.2&&p<.55) { const lv=Math.sin(seg(p,.2,.55)*Math.PI); for (let x=-12;x<=12;x++) { const y=Math.round(Math.abs(x)<12?4-Math.sqrt(144-x*x)/3:0); if (BAY[(y+70)&3][(x+390)&3]<lv*16) { px(390+x,74-y,P.white); if (x%3===0) px(390+x,73-y,P.ink); } } } }
 const post=86; R(post-2,96,4,72,P.wood); R(post-1,96,1,72,P.woodHi);
 ['THIS WAY','THAT WAY','UP?'].forEach((lb,i)=>{ const dir=(Math.floor(t/4+i*1.3)%2)?1:-1, w=tw(lb)+10, y=100+i*14, x=dir>0?post+2:post-2-w; R(x,y,w,10,'#a8683a'); R(x,y+9,w,1,P.woodDk); if (dir>0) poly([[x+w,y],[x+w+6,y+5],[x+w,y+10]],'#a8683a'); else poly([[x,y],[x-6,y+5],[x,y+10]],'#a8683a'); text(lb,x+5,y+2,P.ink,1); });
 [[40,160,P.teal],[136,164,P.pink],[350,162,P.teal],[452,158,P.pink]].forEach((q,i)=>{ const g=0.25+0.15*Math.sin(t*2+i); dell(q[0],q[1]-6,14,10,q[2],g); R(q[0]-1,q[1]-6,3,8,P.cream); ell(q[0],q[1]-8,7,4,q[2]); px(q[0]-3,q[1]-9,P.white); px(q[0]+2,q[1]-10,P.white); });
 for (let i=0;i<16;i++) { const x=(i*61+t*6*(i%3+1))%W, y=36+((i*37)%110)+Math.sin(t*2+i)*8; if (Math.sin(t*3+i*1.7)>-0.3) { px(x,y,P.goldHi); px(x-1,y,'#7a6a20'); px(x+1,y,'#7a6a20'); px(x,y-1,'#7a6a20'); px(x,y+1,'#7a6a20'); } }
 over(W,H,'#3a2a58',(x,y)=>{ if (y<146||y>167) return 0; const top=150+3*Math.sin((x-t*20)*0.05); return y<top?0:0.35; },fs+2);
 bigTable(W,H); tint(t,W,H,o.mood); boss(t,o,m); use(m); mood(t,W,H,o.mood); } });

S.roomCourt = (o) => ({ raw:(t,W,H)=>{ const m=c;
 R(0,0,W,H,'#240a16'); for (let y=4;y<168;y+=10) { R(0,y,W,1,'#30101e'); for (let x=((y/10)%2<1?0:12);x<W;x+=24) R(x,y,1,10,'#30101e'); }
 dell(240,60,170,110,'#34101e',0.5); ell(240,60,140,90,'#34101e');
 const hc=240, hcy=34, hs=14, inH=(x,y)=>{ const r=hs*0.6; return ((x-(hc-hs/2))**2+(y-hcy)**2<=r*r)||((x-(hc+hs/2))**2+(y-hcy)**2<=r*r)||(y>=hcy&&Math.abs(x-hc)<=hs*1.05*(1-(y-hcy)/(hs*1.35))); };
 heart(hc,hcy,hs+3,P.ink); const sh=Math.floor(t*2), pc=['#c8283c','#ff5a6a','#e8b04a','#8a1838'];
 for (let y=hcy-hs;y<=hcy+hs*1.4;y++) for (let x=hc-hs*1.6;x<=hc+hs*1.6;x++) if (inH(x,y)) { { const d=Math.sqrt((x-hc)**2+(y-hcy-4)**2), ring=(d/4)|0, lead=(d%4)<0.9||x===hc; px(x,y,lead?P.ink:pc[(ring+sh)%4]); } }
 over(W,H,'#ff8a9a',(x,y)=>{ if (y<40||y>168) return 0; const half=12+(y-40)*0.8; if (Math.abs(x-240)>half) return 0; return 0.16*(0.55+0.45*Math.sin(x*0.15-t*2)); });
 R(196,70,88,98,P.goldDk); R(198,72,84,96,P.gold); R(202,76,76,92,'#7a1428'); for (let y=80;y<168;y+=8) for (let x=206+((y/8)%2?4:0);x<276;x+=8) px(x,y,'#5a1020');
 circ(196,68,5,P.gold); circ(284,68,5,P.gold); heart(240,64,10,P.gold); heart(240,65,7,P.red);
 for (const g of [[150,0],[330,1]]) { const x=g[0], tilt=(Math.floor(t/5+g[1])%2)?1:0; R(x+16,70,2,98,'#3a2018'); line(x+16,70,x+16+tilt*2,62,'#3a2018'); bmp(PIP9.heart,x+12+tilt*2,54,'#8a1838'); circ(x,96,6,'#5a3040'); bmp(PIP9.heart,x-4,84,'#7a1428'); R(x-14,104,28,40,'#5a3040'); R(x-14,104,28,1,'#7a1428'); bmp(PIP9.heart,x-4,116,'#7a1428'); R(x-14,144,28,24,'#4a2434'); if (!(((t+g[1]*1.7)%3.1)<0.15)) { px(x-2,96,P.white); px(x+2,96,P.white); } }
 for (const cx of [120,360]) { R(cx-1,96,3,40,P.gold); R(cx-13,96,27,2,P.gold); R(cx-6,136,13,2,P.gold); dell(cx,82,18,14,'#5a1a28',0.35+0.1*Math.sin(t*5+cx)); [[cx-12,88],[cx,86],[cx+12,88]].forEach((cd,i)=>{ R(cd[0]-1,cd[1],3,8,P.cream); const f=Math.floor(t*10+i+cx)%3; ell(cd[0],cd[1]-3,1+(f===1?1:0),3,P.gold); px(cd[0]+(f===2?1:0),cd[1]-6,P.goldHi); px(cd[0],cd[1]-2,P.white); }); }
 for (const b of [[96,0],[384,1]]) { const bx=b[0]; ell(bx,156,26,14,'#16351f'); ell(bx-6,152,12,7,'#1f4a2c'); const p=cyc(t+b[1]*2,5); [[bx-14,150],[bx-2,146],[bx+12,152],[bx+4,158],[bx-10,160]].forEach((r,i)=>{ circ(r[0],r[1],3,P.white); px(r[0],r[1],P.creamSh); if (i<2||(i===2&&p>.5)) { circ(r[0],r[1],3,P.red); px(r[0],r[1],P.redDk); } else if (i===2) { dell(r[0],r[1],3,3,P.red,seg(p,0,.5)); R(r[0]+3,r[1]-5,1,4,P.woodHi); px(r[0]+2,r[1]-1,P.red); } }); }
 for (const side of [0,1]) { for (let y=0;y<H;y++) for (let f=0;f<5;f++) { const base=side?W-70+f*14:f*14, x=Math.round(base+Math.sin(t*1.2+y*0.035+f)*2*(y/H)); R(x,y,14,1,['#7a1428','#a81e34','#5a1020','#a81e34','#7a1428'][f]); } R(side?W-70:0,118,70,4,P.gold); R(side?W-70:0,119,70,1,P.goldHi); }
 R(0,0,W,12,'#7a1428'); for (let x=0;x<W;x+=24) circ(x+12,12,9,'#7a1428'); for (let x=2;x<W;x+=4) px(x,21+((x/4)%2),P.gold); R(0,0,W,2,P.gold);
 bigTable(W,H); tint(t,W,H,o.mood); boss(t,o,m); use(m); mood(t,W,H,o.mood); } });

const CCS = {};
const charImg = (key,t,name,oo) => { let cv=CCS[key]; if (!cv) { cv=mk(128,112); CCS[key]=cv; } const sc=S[name](oo); render(cv,Object.assign({},sc,{bg:()=>{},table:(tt,W2,H2)=>{ c.clearRect(0,84,W2,H2-84); }}),t,oo); return cv; };
const tintImg = (cv,col,amt) => { const x=cv.getContext('2d'), img=x.getImageData(0,0,cv.width,cv.height), d=img.data, k=hx(col); for (let i=0;i<d.length;i+=4) { if (d[i+3]===0) continue; d[i]+=(k[0]-d[i])*amt; d[i+1]+=(k[1]-d[i+1])*amt; d[i+2]+=(k[2]-d[i+2])*amt; } x.putImageData(img,0,0); };
const gray = (W,H,lv) => { const img=c.getImageData(0,0,W,H), d=img.data, pal=[hx('#120a16'),hx('#3a3048'),hx('#7a7090'),hx('#d8d0e0')]; for (let y=0;y<H;y++) for (let x=0;x<W;x++) { if (BAY[y&3][x&3]>=lv*16) continue; const i=(y*W+x)*4, l=(d[i]*0.3+d[i+1]*0.59+d[i+2]*0.11)/255*3.2; const k=clamp(Math.floor(l+BAY[(y+1)&3][(x+2)&3]/16-0.5),0,3), q=pal[k]; d[i]=q[0]; d[i+1]=q[1]; d[i+2]=q[2]; } c.putImageData(img,0,0); };
const PER = {soldier:2.4,cheshire:3.2,knave:3,hatter:3.2,queen:3.4};

S.react = (o) => ({ raw:(t,W,H)=>{ const m=c, who=o.who, kind=o.kind, per=kind==='defeat'?3.6:2.4, p=cyc(t,per); room(W,H,{_t:t}); table(W,H,84);
 let oo={mode:'idle',suit:'heart'}, tt=t, dx=0, dy=0, flash=false, alpha=1, sq=1, hide=false;
 if (kind==='tell') { if (p>.3) { oo.mode='action'; tt=PER[who]*0.22*seg(p,.3,.75); if (who==='cheshire') tt=PER[who]*0.03; } }
 if (kind==='hurt') { if (p>.2&&p<.3) flash=true; if (p>.2&&p<.5) dx=Math.round(4*(1-seg(p,.2,.5))*(Math.floor(t*24)%2?1:-1)); }
 if (kind==='defeat') { if (p<.12&&p>.04) flash=true;
  if (who==='soldier') { sq=1-eo(seg(p,.15,.4)); if (p>.4) hide=true; }
  if (who==='cheshire') { oo.mode='action'; tt=PER.cheshire*(0.05+0.4*seg(p,.1,.5)); if (p>.6) hide=true; }
  if (who==='knave') { dx=-Math.round(150*seg(p,.2,.6)**2); dy=Math.round(Math.sin(t*30)*(p>.2&&p<.6?1:0)); if (p>.6) hide=true; }
  if (who==='hatter') { dy=Math.round(16*eo(seg(p,.15,.35))); tt=0.2; oo.sleep=p>.2; }
  if (who==='queen') { oo.headless=p>.3; oo.hp=seg(p,.3,.8); if (p>.95) oo.hp=1; }
  if (p>.92&&who!=='hatter'&&who!=='queen') { hide=false; alpha=seg(p,.92,1); sq=1; dx=0; oo={mode:'idle',suit:'heart'}; tt=t; }
 }
 if (!hide) { const cv=charImg('r_'+who+kind,tt,who,oo); if (flash) tintImg(cv,'#ffffff',1); else if (kind==='hurt'&&p>.3&&p<.45) tintImg(cv,P.red,0.35); use(m);
  if (sq<1) { const h=Math.max(1,Math.round(84*sq)); m.drawImage(cv,0,0,128,84,dx,84-h,128,h); m.drawImage(cv,0,84,128,28,dx,84,128,28); } else if (alpha<1) { m.globalAlpha=alpha; m.drawImage(cv,dx,dy); m.globalAlpha=1; } else m.drawImage(cv,dx,dy); }
 use(m);
 if (kind==='tell'&&p>.3) { const on=Math.floor(t*8)%2; R(54,4,20,4,P.ink); R(55,5,Math.round(18*seg(p,.3,.6)),2,seg(p,.3,.6)>=1?(on?P.redHi:P.goldHi):P.goldHi); if (p>.55) stext('!',on?96:97,18,P.redHi,2); }
 if (kind==='hurt'&&p>.2&&p<.85) { const e=seg(p,.2,.85); stext('-7',58,Math.round(40-e*20),P.redHi,2); }
 if (kind==='defeat') {
  if (who==='soldier'&&p>.2&&p<.9) { const e=seg(p,.2,.9); for (let i=0;i<9;i++) { const a=-Math.PI*(0.1+0.8*i/8), r=e*60; const x=64+Math.cos(a)*r, y=70+Math.sin(a)*r*0.8+e*e*50; cardB(x,y); } if (p>.4) stext('FOLDED!',43,10,P.goldHi,1); }
  if (who==='cheshire'&&p>.5&&p<.75) { const e=seg(p,.5,.75); for (let k=0;k<10;k++) { const a=k*Math.PI/5, r=4+e*24; px(64+Math.cos(a)*r,60+Math.sin(a)*r*0.6,k%2?P.pink:P.white); } if (p>.6) stext('POOF',52,30,P.lav,1); }
  if (who==='knave'&&p>.2&&p<.7) { for (let k=0;k<5;k++) { const e=(t*3+k/5)%1; circ(70+k*8-e*10,82-e*6,1+Math.round(e*2),P.steam); } stext('DRAGGED OFF!',28,10,P.goldHi,1); }
  if (who==='hatter'&&p>.3) { for (let k=0;k<3;k++) { const e=(t*0.8+k/3)%1; stext('Z',72+k*6+Math.round(e*6),Math.round(30-e*20-k*4),P.cream,1); } R(84,86,10,5,P.white); R(80,90,6,2,'#c8a070'); px(78,91,'#c8a070'); stext('ASLEEP',46,8,P.goldHi,1); }
  if (who==='queen'&&p>.82) stext('OFF WITH HERS!',22,6,P.goldHi,1);
 } } });

const topTable = (W,H) => { const TY=34; R(0,0,W,TY,P.wall0); dell(W/2,-4,W*0.4,TY,P.wall1,0.5); ell(W/2,-4,W*0.32,TY-6,P.wall1); for (let x=6;x<W;x+=12) { px(x,10,P.paper); px(x-1,11,P.paper); px(x+1,11,P.paper); px(x,12,P.paper); } R(0,TY,W,2,P.woodHi); R(0,TY+2,W,3,P.wood); R(0,TY+5,W,1,P.woodDk); R(0,TY+6,W,H-TY-6,P.felt1); dell(W/2,70,52,26,P.felt2,0.5); ell(W/2,70,40,20,P.felt2); for (let x=4;x<W;x+=9) px(x,TY+12+((x*5)%40),P.felt0); };
const CARDS = { drink:{n:'DRINK ME',r:P.greyHi}, eat:{n:'EAT ME',r:P.greyHi}, tea:{n:'TEACUP',r:P.greyHi}, watch:{n:'WATCH',r:P.teal}, glass:{n:'MIRROR',r:P.teal}, vorpal:{n:'VORPAL',r:P.gold} };
const art = (k,cx,cy,t) => {
 if (k==='drink') { R(cx-3,cy-14,6,4,P.woodHi); R(cx-2,cy-10,4,5,'#9ad8e0'); ell(cx,cy+3,10,12,'#9ad8e0'); ell(cx,cy+7,9,7,P.pink); R(cx-7,cy-1,14,6,P.cream); text('ME',cx-5,cy-1,P.ink,1); px(cx-6,cy-6,P.white); px(cx-6,cy-5,P.white); }
 if (k==='eat') { R(cx-13,cy+9,26,2,P.white); R(cx-10,cy-2,20,11,P.cream); R(cx-10,cy-6,20,5,P.pink); for (let x=-9;x<10;x+=4) R(cx+x,cy-1,2,2+((x+9)%3),P.pink); circ(cx,cy-9,2,P.red); px(cx-6,cy+4,P.redDk); px(cx+5,cy+6,P.redDk); px(cx,cy+3,P.redDk); }
 if (k==='tea') { R(cx-12,cy+8,24,2,P.white); R(cx-8,cy-2,16,10,P.white); R(cx-8,cy+1,16,2,P.pink); R(cx+8,cy,3,1,P.white); R(cx+10,cy,1,5,P.white); R(cx+8,cy+4,3,1,P.white); for (let i=0;i<3;i++) { for (let k2=0;k2<4;k2++) px(cx-4+i*4+Math.round(Math.sin(t*4+k2+i)),cy-5-k2*3,P.steam); } }
 if (k==='watch') { R(cx-2,cy-16,4,3,P.goldDk); circ(cx,cy,12,P.goldDk); circ(cx,cy,10,P.cream); for (let i=0;i<12;i++) { const a=i*Math.PI/6; px(cx+Math.cos(a)*8,cy+Math.sin(a)*8,P.ink); } line(cx,cy,cx,cy-7,P.ink); line(cx,cy,cx+5,cy+2,P.redDk); }
 if (k==='glass') { ell(cx,cy-2,10,14,P.gold); ell(cx,cy-2,8,12,'#9ad8e0'); line(cx-4,cy-8,cx+1,cy-12,P.white); line(cx-5,cy-4,cx,cy-9,P.white); R(cx-1,cy+12,3,4,P.gold); R(cx-6,cy+16,13,2,P.gold); }
 if (k==='rabbit') { ell(cx,cy+4,9,8,P.white); R(cx-6,cy-16,4,14,P.white); R(cx+2,cy-16,4,14,P.white); R(cx-5,cy-14,2,10,P.pink); R(cx+3,cy-14,2,10,P.pink); px(cx-3,cy+2,P.ink); px(cx+3,cy+2,P.ink); px(cx,cy+5,P.pink); R(cx-10,cy+11,20,3,P.red); }
 if (k==='rose') { R(cx,cy+2,2,14,P.green); ell(cx-4,cy+9,3,2,P.greenHi); circ(cx,cy-4,8,P.red); circ(cx,cy-4,5,P.redDk); circ(cx,cy-4,2,P.red); R(cx+3,cy-12,6,16,P.white); line(cx+2,cy-11,cx+2,cy+3,P.redHi); R(cx+9,cy-14,2,6,P.woodHi); }
 if (k==='mushroom') { R(cx-3,cy,6,12,P.cream); ell(cx,cy-2,13,8,P.red); R(cx-13,cy-2,27,3,P.red); circ(cx-6,cy-5,2,P.white); circ(cx+4,cy-7,2,P.white); circ(cx+8,cy-2,1,P.white); px(cx,cy-3,P.white); }
 if (k==='croquet') { line(cx-8,cy-14,cx+2,cy+6,P.pink); line(cx-7,cy-14,cx+3,cy+6,P.pink); circ(cx-9,cy-15,3,P.pink); px(cx-10,cy-16,P.ink); R(cx-12,cy-15,2,1,P.goldDk); R(cx+1,cy+5,6,3,P.pinkDk); circ(cx+8,cy+10,5,P.greyDk); for (let i=0;i<5;i++) px(cx+5+i*2,cy+5+(i%2),P.grey); }
 if (k==='hedgehog') { ell(cx,cy+2,12,9,P.greyDk); for (let i=-10;i<=10;i+=3) line(cx+i,cy-4,cx+i*1.3,cy-11,P.grey); ell(cx+8,cy+5,5,4,P.cream); px(cx+9,cy+4,P.ink); px(cx+13,cy+5,P.ink); R(cx-14,cy+11,28,2,P.goldDk); }
 if (k==='smoke') { R(cx-3,cy+6,6,8,P.plumHi); R(cx-6,cy+13,12,2,P.goldDk); line(cx,cy+6,cx-8,cy-2,P.goldDk); for (const q of [[cx-8,cy-6,5],[cx+2,cy-11,6],[cx+8,cy-3,4]]) { circ(q[0],q[1],q[2],P.lav); circ(q[0],q[1],q[2]-2,P.cream); } }
 if (k==='twins') { for (const ox of [-7,7]) { ell(cx+ox,cy+5,6,8,ox<0?P.mustard:P.red); circ(cx+ox,cy-6,5,P.skin); px(cx+ox-2,cy-7,P.ink); px(cx+ox+2,cy-7,P.ink); R(cx+ox-5,cy-12,10,3,ox<0?P.red:P.mustard); px(cx+ox,cy-14,P.goldHi); } }
 if (k==='gift') { R(cx-11,cy-4,22,16,P.teal); R(cx-12,cy-8,24,5,'#2a9aa2'); R(cx-1,cy-8,3,20,P.goldHi); poly([[cx,cy-8],[cx-8,cy-15],[cx-6,cy-8]],P.goldHi); poly([[cx+1,cy-8],[cx+9,cy-15],[cx+7,cy-8]],P.goldHi); }
 if (k==='vorpal') { for (let d=-1;d<=1;d++) line(cx-9+d,cy+9,cx+10+d,cy-14,P.greyHi); line(cx-9,cy+9,cx+10,cy-14,P.white); R(cx-14,cy+7,10,3,P.gold); line(cx-13,cy+4,cx-6,cy+12,P.gold); line(cx-12,cy+11,cx-15,cy+14,P.woodHi); line(cx-11,cy+12,cx-14,cy+15,P.woodHi); } };
const bigCard = (cx,cy,w,h,face,k,t) => { w=Math.max(1,Math.round(w)); h=Math.round(h); const x=Math.round(cx-w/2), y=Math.round(cy-h/2); R(x-1,y-1,w+2,h+2,P.ink); if (!face) { R(x,y,w,h,P.cream); if (w>4) { R(x+2,y+2,w-4,h-4,P.redDk); for (let yy=y+5;yy<y+h-5;yy+=8) for (let xx=x+5;xx<x+w-5;xx+=8) px(xx,yy,P.gold); } return; } const C=CARDS[k]; R(x,y,w,h,C.r); if (w>6) R(x+2,y+2,w-4,h-4,P.cream); if (w>=44) { art(k,cx,cy-6,t); R(x+2,y+h-13,w-4,11,C.r); text(C.n,Math.round(cx-tw(C.n)/2),y+h-11,P.ink,1); } };
S.cardplay = (o) => ({ raw:(t,W,H)=>{ const k=o.card, p=cyc(t,3.6); topTable(W,H); cardB(100,46); cardB(101,45); cardB(102,44);
 const e=seg(p,.62,.9); let n2='7', w2=12, h2=17, tot=17, x3=null;
 if (k==='drink'&&p>.62) { w2=Math.round(12-4*e); h2=Math.round(17-6*e); if (e>.5) { n2='4'; tot=14; } }
 if (k==='eat'&&p>.62) { w2=Math.round(12+4*e); h2=Math.round(17+6*e); if (e>.5) { n2='10'; tot=20; } }
 if (k==='glass'&&p>.7) { x3=Math.round(102+(72-102)*seg(p,.7,.85)); if (p>.85) tot=21; }
 cardF(44,58,'10','heart',P.red); if (w2===12) cardF(58,58,n2,'club',P.black); else { R(58,58+17-h2,w2,h2,P.cream); text(n2,59,59+17-h2,P.black,1); }
 if (x3!==null) cardF(x3,58,'4','heart',P.red);
 if (k==='drink'&&p>.62&&p<.95) for (let i=0;i<6;i++) px(58+((i*7+Math.floor(t*20))%16),56+((i*5+Math.floor(t*15))%20),P.goldHi);
 if (k==='eat'&&p>.62&&p<.95) for (let i=0;i<5;i++) px(56+((i*9+Math.floor(t*12))%20),78+(i%2),P.creamSh);
 R(2,40,40,11,P.ink); text('TOT',4,42,P.cream,1); text(String(tot),24,42,tot===21?P.goldHi:P.cream,1);
 if (p<.12) { const e0=seg(p,0,.12), y=Math.round(112-20*e0); bigCard(96,y,12,17,false,k,t); ell(96,y+12,9,6,P.skin); }
 else if (p<.62) { let w, h, cx, cy, face=false; if (p<.28) { const e1=eo(seg(p,.12,.28)); w=12+36*e1; h=17+53*e1; cx=96+(64-96)*e1; cy=92+(64-92)*e1; } else if (p<.55) { w=48; h=70; cx=64; cy=64; if (p<.38) { const f=seg(p,.28,.38); w=48*Math.abs(Math.cos(f*Math.PI)); face=f>.5; } else face=true; } else { const e2=seg(p,.55,.62); w=48*(1-e2); h=70*(1-e2); cx=64+(64-64)*e2; cy=64+(66-64)*e2; face=true; }
  if (p>.28&&p<.6) dell(64,64,40,46,P.goldHi,0.12); bigCard(cx,cy,w,h,face,k,t); if (p>.38&&p<.42) over(W,H,P.white,()=>0.4); if (p>.4&&p<.55&&Math.floor(t*10)%2) { px(40,30,P.goldHi); px(88,40,P.goldHi); px(44,96,P.goldHi); px(86,92,P.goldHi); } }
 if (p>.62) {
  if (k==='tea') { for (let i=0;i<10;i++) { const kk=(t*0.8+i/10)%1; px(104+Math.round(Math.sin(kk*8+i)*3),44-kk*20,P.steam); } const lv=Math.sin(seg(p,.62,.95)*Math.PI); dell(106,22,8,10,P.cream,lv*0.6); if (p>.7) stext('NEXT: 9',62,20,P.cream,1); }
  if (k==='watch') { over(W,H,'#7a5a30',()=>0.35*Math.sin(seg(p,.62,1)*Math.PI)); art('watch',64,20,0); if (p>.68) stext('TIME STOP',37,40,P.goldHi,1); }
  if (k==='glass'&&p<.8) { const e3=seg(p,.62,.8); for (let i=0;i<14;i++) { const a=i*0.45, r=e3*40; px(64+Math.cos(a)*r,64+Math.sin(a)*r,i%2?'#9ad8e0':P.white); } stext('+4 COPIED',37,20,P.goldHi,1); }
  if (k==='glass'&&p>=.8) stext('21!',50,20,P.goldHi,2);
  if (k==='vorpal'&&p<.8) { const e4=seg(p,.62,.72); for (let s=0;s<=e4;s+=0.02) { const x=8+112*s, y=104-96*s; R(x,y,3,3,(e4-s)<0.15?P.white:P.goldHi); } if (p>.66&&p<.69) over(W,H,P.white,()=>0.5); }
  if (k==='vorpal'&&p>.68) stext('CRITICAL!',37,20,P.goldHi,1);
  if (k==='drink'&&p>.75) stext('7 > 4',49,20,P.cream,1);
  if (k==='eat'&&p>.75) stext('7 > 10',46,20,P.cream,1);
 } } });

const bigC = (x,y,n,suit,col) => { R(x-1,y-1,26,36,P.ink); R(x,y,24,34,P.cream); R(x+21,y+1,2,32,P.creamSh); text(n,x+2,y+2,col,1); bmp(PIP9[suit],x+7,y+16,col); };
const bigB = (x,y) => { R(x-1,y-1,26,36,P.ink); R(x,y,24,34,P.cream); R(x+2,y+2,20,30,P.redDk); for (let yy=y+6;yy<y+30;yy+=8) for (let xx=x+6;xx<x+20;xx+=8) px(xx,yy,P.gold); };
const effC = (x,y,k,t) => { const C=CARDS[k]; R(x-1,y-1,26,36,P.ink); R(x,y,24,34,C.r); R(x+2,y+2,20,30,P.cream); const sv=c; art(k,x+12,y+14,t); R(x+2,y+27,20,5,C.r); };
S.battle = (o) => ({ raw:(t,W,H)=>{ const m=c, T=t%16, rd=T<6?0:(T<11?1:2), rt=rd===0?T:(rd===1?T-6:T-11);
 S.roomCourt({mood:rd===1&&rt>2?'tension':'calm',boss:'none'}).raw(t,W,H); use(m);
 let qm='idle', qt=t, flash=false;
 if (rd===0&&rt>2.45&&rt<4.9) { qm='bonk'; qt=rt-2.45; }
 if (rd===1&&rt>2&&rt<4.6) qm='laugh';
 if ((rd===0&&rt>4.6&&rt<4.78)||(rd===2&&rt>2.2&&rt<2.38)) flash=true;
 const cv=charImg('battleQ',qt,'queen',{mode:qm}); if (flash) tintImg(cv,'#ffffff',1); use(m); m.imageSmoothingEnabled=false; m.drawImage(cv,112,0,256,224);
 const slots=[150,178,206,234], dk=[262,200];
 const deal=(i,card,t0)=>{ const e=eo(seg(rt,t0,t0+0.35)); if (e<=0) return; const x=Math.round(dk[0]+(slots[i]-dk[0])*e), y=Math.round(dk[1]+(200-dk[1])*e); bigC(x,y,card[0],card[1],card[2]); };
 bigB(dk[0]+4,dk[1]-2); bigB(dk[0]+2,dk[1]-1); bigB(dk[0],dk[1]);
 const hands=[[['10','heart',P.red],['6','club',P.black],['2','diamond',P.red]],[['10','spade',P.black],['8','diamond',P.red],['7','club',P.black]],[['A','heart',P.red],['K','spade',P.black]]][rd];
 deal(0,hands[0],0); deal(1,hands[1],0.25); if (hands[2]) deal(2,hands[2],1.6);
 let you=rd===0?(rt<1.95?16:(rt<3.5?18:20)):(rd===1?(rt<1.95?18:25):21), her=[18,17,20][rd];
 effC(330,206,'drink',t); effC(356,204,'tea',t); effC(382,206,'vorpal',t);
 R(150,174,180,20,P.ink); const tl='YOU '+you+' · HER '+her; stext(tl,Math.round(240-tw(tl,2)/2),177,you>21?P.redHi:(you===21?P.goldHi:P.cream),2);
 const drum=Math.floor(t*7)%6; ell(24,268,46,24,P.lavDk); ell(28,264,42,20,P.lav); ell(70,248,14,10,P.white); for (let i=0;i<4;i++) R(82+i*8,220-(drum===i?3:0),6,16,P.skin); ell(96,238,18,12,P.skin); R(86,244,20,3,P.skinSh); R(112,234,8,5,P.skin);
 const secs=Math.max(0,15-Math.floor(rt*3)), frac=secs/15; circ(36,34,23,P.goldDk); circ(36,34,21,P.cream); for (let a=0;a<frac*Math.PI*2;a+=0.05) line(36,34,36+Math.sin(a)*19,34-Math.cos(a)*19,secs<=3&&Math.floor(t*6)%2?P.redHi:'#f0c8cc'); for (let i=0;i<12;i++) { const a=i*Math.PI/6; px(36+Math.cos(a)*20,34+Math.sin(a)*20,P.ink); } R(33,8,7,4,P.goldDk); stext(String(secs),secs>9?30:33,30,P.ink,1,P.cream);
 const php=rd===0?30:(rd===1?(rt<2.4?30:23):23); stext('ALICE',12,64,P.cream,1); R(12,74,92,8,P.ink); R(13,75,Math.round(90*php/30),6,'#58c06a'); R(13,75,Math.round(90*php/30),1,'#9ae8a8'); text(php+'/30',70,64,P.cream,1);
 const ehp=rd===0?(rt<4.6?50:45):(rd===1?45:(rt<2.2?45:33)); const qn='QUEEN OF HEARTS'; stext(qn,W-12-tw(qn),10,P.cream,1); R(W-152,22,140,8,P.ink); R(W-151,23,Math.round(138*ehp/50),6,P.red); R(W-151,23,Math.round(138*ehp/50),1,P.redHi); text(ehp+'/50',W-50,34,P.cream,1);
 const ib=rd===0?seg(rt,0.8,3.4):(rd===1?0.6*seg(rt,0.8,5):0.3*seg(rt,0.8,5)), full=ib>=1, on=Math.floor(t*8)%2; R(180,4,120,8,P.ink); R(181,5,Math.round(118*(rd===0&&rt>3.5?0:ib)),6,full?(on?P.redHi:P.goldHi):P.goldHi); bmp(PIP5.club,170,5,P.cream); if (full&&rt<3.6) stext('!',304,2,P.redHi,1);
 const hint='[H] HIT   [S] STAY   [1-3] PLAY'; text(hint,Math.round(240-tw(hint)/2),258,'#9a8ab0',1);
 const pop=(s,x,y,t0,col,sc)=>{ if (rt<t0||rt>t0+1.4) return; const e=seg(rt,t0,t0+1.4); stext(s,x,Math.round(y-e*24),col,sc); };
 if (rd===0) { pop('HIT',156,160,1.6,P.cream,1); if (rt>4.0&&rt<4.6) stext('STAY',112,206,P.cream,2); pop('-5',228,80,4.6,P.redHi,3); if (rt>4.7&&rt<5.9) stext('ROUND WON',186,140,P.goldHi,2); }
 if (rd===1) { pop('HIT',156,160,1.6,P.cream,1); if (rt>2&&rt<3.4) { const sh=Math.round(Math.sin(t*60)*2); stext('BUST!',Math.round(240-tw('BUST!',6)/2)+sh,100,P.redHi,6); over(W,H,P.redDk,(x,y)=>{ const dd=Math.min(x,y,W-1-x,H-1-y); return dd<40?(1-dd/40)*0.6:0; }); } pop('-7',40,96,2.4,P.redHi,2); }
 if (rd===2) { if (rt>0.6&&rt<2.0) { stext('21!',Math.round(240-tw('21!',6)/2),96,P.goldHi,6); if (Math.floor(t*10)%2) { px(170,92,P.white); px(318,104,P.white); px(200,140,P.goldHi); } } if (rt>2.0&&rt<2.35) { const e=seg(rt,2.0,2.25); for (let s=0;s<=e;s+=0.01) { const x=120+240*s, y=150-130*s; R(x,y,4,4,(e-s)<0.12?P.white:P.goldHi); } if (rt<2.1) over(W,H,P.white,()=>0.45); } pop('-12 CRIT!',196,90,2.2,P.goldHi,2); }
} });

S.ending = (o) => ({ raw:(t,W,H)=>{ const m=c, win=o.kind==='win', T=t%9;
 if (win) {
  S.roomCourt({mood:'calm',boss:'none'}).raw(t,W,H); use(m);
  const hl=T>2.5, hp=seg(T,2.6,4.6); const cv=charImg('endW',T<1.5?t:1.5,'queen',{mode:'idle',headless:hl,hp:hp}); if (T>1.2&&T<1.35) tintImg(cv,'#ffffff',1); use(m); m.imageSmoothingEnabled=false; m.drawImage(cv,112,0,256,224);
  if (T>1.0&&T<1.3) { const e=seg(T,1.0,1.2); for (let s=0;s<=e;s+=0.01) R(100+280*s,180-160*s,4,4,(e-s)<0.12?P.white:P.goldHi); }
  if (T>1.5&&T<5.4) gray(W,H,T<5?1:1-seg(T,5,5.4));
  if (T>2.1&&T<2.6) { const e=seg(T,2.1,2.5), ax=Math.round(560-460*e), ay=78; R(ax,ay-2,140,4,'#1a1018'); poly([[ax-6,ay-26],[ax+24,ay-18],[ax+24,ay+18],[ax-6,ay+26],[ax+4,ay]],'#1a1018'); }
  if (T>2.45&&T<2.6) over(W,H,P.white,()=>0.7);
  if (T>5.2) { const s='VICTORY!'; stext(s,Math.round(240-tw(s,5)/2),12+(Math.floor(t*2)%2),(j)=>['#fff2b0','#ffe08a','#ffe08a','#e8b04a','#e8b04a','#c88a2a','#a8702a'][j],5); for (let i=0;i<10;i++) { const a=t*2+i*0.63; if (Math.floor(t*8+i)%3) px(240+Math.cos(a)*130,34+Math.sin(a)*22,P.goldHi); } if (T>6&&!o.noPress) stext('THE COURT IS YOURS',Math.round(240-tw('THE COURT IS YOURS',2)/2),56,P.cream,2); }
 } else {
  if (!CCS.endBg) { CCS.endBg=mk(W,H); } const L=CCS.endBg, lc=L.getContext('2d'); use(lc);
  S.roomCourt({mood:T<2.6?'rage':'rage',boss:'none'}).raw(t,W,H); use(lc);
  const qm=T<2.8?'action':'laugh', qt=T<2.8?Math.min(T,2.4)+0.4:t; const cv=charImg('endL',qt,'queen',{mode:qm,bubble:['OFF WITH','HER HEAD!']}); use(lc); lc.imageSmoothingEnabled=false; lc.drawImage(cv,112,0,256,224);
  use(m); m.fillStyle=P.ink; m.fillRect(0,0,W,H); m.imageSmoothingEnabled=false;
  const e=eo(seg(T,3.2,4.2)); m.save(); m.translate(W/2,H/2+e*120); m.rotate(-e*0.18); m.scale(1+e*0.25,1+e*0.25); m.drawImage(L,-W/2,-H/2); m.restore();
  if (T>2.6&&T<3.25) { const e2=seg(T,2.6,3.15); const ax=Math.round(560-520*e2), ay=Math.round(-40+260*e2); poly([[ax-60,ay-60],[ax+40,ay-40],[ax+50,ay+30],[ax-40,ay+70],[ax-10,ay]],'#cfd0dc'); poly([[ax-50,ay-50],[ax+30,ay-34],[ax+38,ay+22],[ax-32,ay+58],[ax-6,ay]],'#e8e8f0'); R(ax+40,ay-6,200,10,P.woodDk); }
  if (T>3.15&&T<3.3) over(W,H,P.white,()=>0.85);
  if (T>4.6) { const ir=Math.max(0,1-seg(T,4.6,6)); over(W,H,P.ink,(x,y)=>{ const d=Math.sqrt(((x-240)/240)**2+((y-80)/135)**2); return d>ir*1.4?1:(d>ir*1.4-0.15?0.5:0); }); }
  if (T>6) { stext('GAME OVER',Math.round(240-tw('GAME OVER',5)/2),100,P.redHi,5); if (!o.noPress&&T>7&&(T%1.2)<0.8) stext('PRESS START TO TRY AGAIN',Math.round(240-tw('PRESS START TO TRY AGAIN',2)/2),160,P.cream,2); }
 } } });

S.hole = (o) => ({ raw:(t,W,H)=>{ const T=t%7, cx=240, cy=135, N=14, sp=T<5?3.2:3.2*(1-seg(T,5,6));
 R(0,0,W,H,'#0a0608');
 const RC=[['#6a4430','#5a3a24'],['#5a3a24','#4a2e1e'],['#4a2e1e','#3a2418'],['#3a2418','#2a180f'],['#2a180f','#1a0e08']]; for (let k=1;k<=N;k++) { const z=k-((t*sp)%1); if (z<0.3) continue; const r=Math.round(260/z), band=RC[Math.min(4,Math.floor(z/N*5))], alt=(Math.floor(k+Math.floor(t*sp))%2), ox=cx+Math.round(Math.sin(t*0.7+k*0.4)*6); ell(ox,cy,r,Math.round(r*0.62),band[alt]); if (r>20) { for (let a2=0;a2<12;a2++) { const an=a2*Math.PI/6+k; px(ox+Math.cos(an)*r*0.96,cy+Math.sin(an)*r*0.6,band[1-alt]); } } }
 ell(cx,cy,14,9,'#0a0608');
 const items=['clock','book','jar','card','cup','map'];
 for (let i=0;i<12;i++) { const z=((i*0.83-t*sp*0.9)%N+N)%N+0.4, a=i*1.9+t*0.2, r=200/z, s=Math.max(1,Math.min(6,Math.round(9/z))), x=Math.round(cx+Math.cos(a)*r*1.1), y=Math.round(cy+Math.sin(a)*r*0.7), it=items[i%6];
  if (it==='clock') { circ(x,y,4*s,P.goldDk); circ(x,y,3*s,P.cream); line(x,y,x,y-2*s,P.ink); line(x,y,x+2*s,y,P.ink); }
  if (it==='book') { R(x-3*s,y-2*s,6*s,4*s,P.plumHi); R(x-3*s,y-2*s,s,4*s,P.gold); }
  if (it==='jar') { R(x-2*s,y-3*s,4*s,6*s,'#9ad8e0'); R(x-2*s,y-3*s,4*s,s,P.woodHi); R(x-2*s,y,4*s,2*s,P.mustard); }
  if (it==='card') { R(x-2*s,y-3*s,4*s,6*s,P.cream); R(x-s,y-s,2*s,2*s,P.red); }
  if (it==='cup') { R(x-2*s,y-s,4*s,3*s,P.white); R(x+2*s,y-s,s,2*s,P.white); R(x-3*s,y+2*s,6*s,Math.max(1,Math.round(s/2)),P.white); }
  if (it==='map') { R(x-3*s,y-2*s,6*s,4*s,P.creamSh); line(x-2*s,y,x+2*s,y-s,P.redDk); } }
 const fl=Math.round(Math.sin(t*14)*3); ell(36+fl,262,54,30,P.lavDk); ell(40,258,48,26,P.lav); ell(84,236,14,10,P.white); ell(100,224,14,10,P.skin); for (let i=0;i<4;i++) R(92+i*6,206+(i===1?fl:0),5,14,P.skin);
 ell(444-fl,262,54,30,P.lavDk); ell(440,258,48,26,P.lav); ell(396,236,14,10,P.white); ell(380,224,14,10,P.skin); for (let i=0;i<4;i++) R(366+i*6,206+(i===2?-fl:0),5,14,P.skin);
 if (T>4.2) { const lv=seg(T,4.2,4.8); over(W,H,P.ink,()=>lv*0.6); if (T>4.6&&!o.noText) { stext('ACT 2',Math.round(240-tw('ACT 2',3)/2),96,P.goldHi,3); stext('THE TULGEY WOOD',Math.round(240-tw('THE TULGEY WOOD',3)/2),130,P.lav,3); } }
 if (T>6.2) over(W,H,P.white,()=>seg(T,6.2,7));
} });

S.wipe = (o) => ({ raw:(t,W,H)=>{ const m=c, p=cyc(t,4.4);
 if (!CCS.wA) { CCS.wA=mk(W,H); CCS.wB=mk(W,H); } const A=CCS.wA, B=CCS.wB;
 use(A.getContext('2d')); S.roomCourt({mood:'calm',boss:'soldier'}).raw(t,W,H);
 use(B.getContext('2d')); S.roomCourt({mood:'calm',boss:'knave'}).raw(t,W,H);
 use(m); m.imageSmoothingEnabled=false; R(0,0,W,H,P.ink);
 const cw=60, ch=54;
 for (let j=0;j<5;j++) for (let i=0;i<8;i++) { const d=(i+j)/11, x=i*cw, y=j*ch;
  const f1=seg(p,.12+d*0.25,.22+d*0.25), f2=seg(p,.55+d*0.25,.65+d*0.25);
  let src=null, w=cw, back=false;
  if (f1<1) { w=Math.round(cw*Math.abs(Math.cos(f1*Math.PI))); if (f1<.5) src=A; else back=true; }
  else if (f2<=0) back=true;
  else { w=Math.round(cw*Math.abs(Math.cos(f2*Math.PI))); if (f2<.5) back=true; else src=B; }
  if (w<1) continue; const xx=x+Math.round((cw-w)/2);
  if (src) m.drawImage(src,x,y,cw,ch,xx,y,w,ch); else { R(xx,y,w,ch,P.cream); if (w>4) { R(xx+2,y+2,w-4,ch-4,P.redDk); if (w>20) { heart(xx+Math.round(w/2),y+22,6,P.red); R(xx+Math.round(w/2)-1,y+6,2,2,P.gold); R(xx+Math.round(w/2)-1,y+44,2,2,P.gold); } } R(xx,y,w,1,P.ink); R(xx,y,1,ch,P.ink); }
 }
 if (p>.45&&p<.6) stext('NEXT CHALLENGER',Math.round(240-tw('NEXT CHALLENGER',2)/2),126,P.goldHi,2);
} });

S.aliceHand = (o) => ({ raw:(t,W,H)=>{ c.clearRect(0,0,W,H); const k=o.kind||'idle', drum=Math.floor(t*7)%6, oy=H-270;
 const sleeve=()=>{ ell(24,268+oy,46,24,P.lavDk); ell(28,264+oy,42,20,P.lav); ell(70,248+oy,14,10,P.white); };
 if (k==='idle') { sleeve(); for (let i=0;i<4;i++) R(82+i*8,220+oy-(drum===i?3:0),6,16,P.skin); ell(96,238+oy,18,12,P.skin); R(86,244+oy,20,3,P.skinSh); R(112,234+oy,8,5,P.skin); }
 if (k==='hit') { const p=cyc(t,0.6), tap=(p<.25||(p>.5&&p<.75))?3:0; sleeve(); R(104,212+oy+tap,6,24,P.skin); px(106,212+oy+tap,P.skinHi); for (let i=0;i<3;i++) R(82+i*8,228+oy,6,7,P.skinSh); ell(96,240+oy+tap,18,11,P.skin); R(86,246+oy,20,3,P.skinSh); }
 if (k==='stay') { const x=Math.round(Math.sin(t*12)*6); sleeve(); R(78+x,214+oy,36,18,P.skin); for (let i=1;i<4;i++) R(78+x+i*9,216+oy,1,14,P.skinSh); R(78+x,214+oy,36,1,P.skinHi); ell(94+x,236+oy,18,10,P.skin); }
 if (k==='pump') { const e=Math.abs(Math.sin(t*6)), y=Math.round(-20*e); ell(24,268+oy,46,24,P.lavDk); ell(28,264+oy,42,20,P.lav); poly([[50,254+oy],[64,246+oy],[90,228+oy+y],[80,222+oy+y]],P.lav); ell(84,226+oy+y,12,10,P.white); ell(96,212+oy+y,14,12,P.skin); for (let i=0;i<4;i++) R(86+i*6,202+oy+y,5,5,P.skinSh); if (Math.floor(t*8)%2) { px(118,196+oy+y,P.goldHi); px(70,200+oy+y,P.goldHi); } }
} });
S.vignette = (o) => ({ raw:(t,W,H)=>{ c.clearRect(0,0,W,H); const col=o.col||P.ink, reach=o.reach||56, lv=o.lv||0.9; for (let y=0;y<H;y++) for (let x=0;x<W;x++) { const dd=Math.min(x,y,W-1-x,H-1-y); if (dd<reach && BAY[y&3][x&3] < (1-dd/reach)*lv*16) px(x,y,col); } } });
S.cardArt = (o) => ({ raw:(t,W,H)=>{ c.clearRect(0,0,W,H); const C={r:o.frame||P.greyHi}; const cx=W/2, cy=H/2; if (o.icon) { art(o.art,cx,cy+2,0.6); return; } R(0,0,W,H,P.ink); R(1,1,W-2,H-2,C.r); R(3,3,W-6,H-6,P.cream); if (o.num) { text(o.num,6,6,P.ink,2); text('+'+o.num,Math.round(cx-tw('+'+o.num,3)/2),cy-14,P.redDk,3); } else art(o.art,cx,cy-6,0.6); R(3,H-15,W-6,12,C.r); text(o.name,Math.round(cx-tw(o.name)/2),H-13,P.ink,1); } });
S.cardFace = (o) => ({ raw:(t,W,H)=>{ c.clearRect(0,0,W,H); if (o.back) { bigB(1,1); return; } bigC(1,1,o.rank,o.suit,(o.suit==='heart'||o.suit==='diamond')?P.red:P.black); } });
this._E = { P, render, S };
return this._E;
}
