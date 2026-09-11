import sys, csv
from PIL import Image, ImageDraw
X0,Y0,CW,CH = (int(v) for v in sys.argv[1:5])
out = sys.argv[5]
cells={}
with open('/tmp/t/soot_cells.tsv') as fh:
    r=csv.DictReader(fh, delimiter='\t')
    for row in r: cells[(int(row['x']),int(row['y']))]=row
im=Image.open('/tmp/t/soot_full.ppm').convert('RGB')
crop=im.crop((X0*16,Y0*16,(X0+CW)*16,(Y0+CH)*16))
S=5
crop=crop.resize((crop.width*S,crop.height*S),Image.NEAREST)
G=26
W=crop.width+G; H=crop.height+G+40
img=Image.new('RGB',(W,H),(16,16,16)); img.paste(crop,(G,G))
d=ImageDraw.Draw(img); cell=16*S
COL={'stair':(60,255,255),'cliff':(255,90,60),'rail':(255,150,255),
     'water':(90,150,255),'floor':(255,255,255),'wall':(255,90,255),
     'tree':(120,255,120),'prop':(200,160,255)}
for j in range(CH):
    for i in range(CW):
        c=cells.get((X0+i,Y0+j))
        if not c: continue
        x=G+i*cell; y=G+j*cell
        role=c['role']; lvl=c['level']
        # tint the cell faintly by role so edges are readable
        if role in ('stair','cliff','rail'):
            ov=Image.new('RGBA',(cell,cell),COL[role]+(70,))
            img.paste(Image.alpha_composite(img.crop((x,y,x+cell,y+cell)).convert('RGBA'),ov).convert('RGB'),(x,y))
        d.rectangle([x,y,x+cell,y+cell],outline=(70,70,70))
        # the LEVEL, large and legible
        if lvl!='-':
            d.text((x+cell//2-4,y+cell//2-8),lvl,fill=(0,0,0))
            d.text((x+cell//2-5,y+cell//2-9),lvl,fill=(255,240,80))
        if role=='stair':
            d.text((x+3,y+3),'S',fill=(0,255,255))
for i in range(CW+1):
    d.line([(G+i*cell,G),(G+i*cell,G+crop.height)],fill=(90,90,90))
    if i<CW: d.text((G+i*cell+cell//2-8,6),str(X0+i),fill=(255,200,120))
for j in range(CH+1):
    d.line([(G,G+j*cell),(G+crop.width,G+j*cell)],fill=(90,90,90))
    if j<CH: d.text((3,G+j*cell+cell//2-6),str(Y0+j),fill=(255,200,120))
d.text((6,H-32),"yellow number = CURRENT 3D level (courses of 16px)   cyan S / tint = stair",fill=(230,230,230))
d.text((6,H-18),"red tint = cliff    magenta tint = railing",fill=(230,230,230))
img.save(out); print(out, img.size)
