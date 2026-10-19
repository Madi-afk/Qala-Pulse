"""Create matching vector PDF and editable SVG-in-HTML investor one pagers."""

from pathlib import Path
import base64
import html
import json
import shutil
import textwrap

from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader
from onepager_editor import add_editor

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/pdf/qalapulse'
TMP = ROOT / 'tmp/pdfs/qalapulse'
W, H = 595.2756, 841.8898
NAVY, BLUE, CYAN = '#09152B', '#2878FF', '#3DDCFF'
GRAY, MUTED, LINE = '#F3F6FA', '#536176', '#DAE2EC'
for face in ['Regular', 'SemiBold', 'Bold']:
    pdfmetrics.registerFont(TTFont(face, str(OUT / f'assets/Inter-{face}.ttf')))


class Sheet:
    def __init__(self, path):
        self.pdf = canvas.Canvas(str(path), pagesize=(W, H), pageCompression=1)
        self.pdf.setTitle('QalaPulse | Investor One Pager')
        self.pdf.setAuthor('QalaPulse')
        self.pdf.setSubject('CivicTech MVP, proposed business model and pilot partnership invitation')
        self.svg = []
        self.text_bounds = []

    def rect(self, x, y, w, h, fill, radius=0, stroke=None, sw=.6):
        c = self.pdf
        c.setFillColor(HexColor(fill))
        if stroke:
            c.setStrokeColor(HexColor(stroke))
        c.setLineWidth(sw)
        c.roundRect(x, H-y-h, w, h, radius, fill=1, stroke=int(bool(stroke)))
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke or "none"}" stroke-width="{sw}"/>')

    def line(self, points, color, width=1):
        c = self.pdf
        c.setStrokeColor(HexColor(color)); c.setLineWidth(width)
        c.setLineCap(1); c.setLineJoin(1)
        p = c.beginPath(); p.moveTo(points[0][0], H-points[0][1])
        for x,y in points[1:]: p.lineTo(x,H-y)
        c.drawPath(p)
        pts = ' '.join(f'{x},{y}' for x,y in points)
        self.svg.append(f'<polyline points="{pts}" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')

    def circle(self,x,y,r,fill,stroke=None,sw=1):
        c=self.pdf; c.setFillColor(HexColor(fill)); c.setLineWidth(sw)
        if stroke: c.setStrokeColor(HexColor(stroke))
        c.circle(x,H-y,r,fill=1,stroke=int(bool(stroke)))
        self.svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke or "none"}" stroke-width="{sw}"/>')

    def text(self,x,y,value,size=10,face='Regular',color=NAVY):
        width=pdfmetrics.stringWidth(value,face,size)
        assert x>=0 and x+width<=W+.1 and y-size>=0 and y+size*.25<H, (value,x,y,width)
        self.pdf.setFillColor(HexColor(color)); self.pdf.setFont(face,size)
        self.pdf.drawString(x,H-y,value)
        self.svg.append(f'<text x="{x}" y="{y}" font-family="Inter{face}" font-size="{size}" fill="{color}">{html.escape(value)}</text>')
        self.text_bounds.append({'text':value,'x':x,'baseline':y,'width':width,'size':size})
        return width

    def para(self,x,y,value,width,size=10,leading=14,face='Regular',color=MUTED):
        lines=[]
        for paragraph in value.split('\n'):
            line=''
            for word in paragraph.split():
                test=(line+' '+word).strip()
                if pdfmetrics.stringWidth(test,face,size)>width and line:
                    lines.append(line); line=word
                else: line=test
            lines.append(line)
        for i,line in enumerate(lines): self.text(x,y+i*leading,line,size,face,color)
        return y+len(lines)*leading

    def label(self,x,y,value,color=BLUE):
        self.text(x,y,value,8,'Bold',color)

    def logo(self,x,y,color=NAVY):
        self.rect(x,y,25,25,BLUE,7)
        self.circle(x+12.5,y+12,7,BLUE,'#FFFFFF',1.1)
        self.line([(x+5,y+13),(x+10,y+13),(x+12,y+8),(x+15,y+17),(x+17,y+12),(x+21,y+12)],'#FFFFFF',1.2)
        self.text(x+34,y+18,'QalaPulse',19,'Bold',color)

    def finish(self):
        self.pdf.showPage();self.pdf.save()
        css=''
        for face in ['Regular','SemiBold','Bold']:
            data=base64.b64encode((OUT/f'assets/Inter-{face}.ttf').read_bytes()).decode()
            css+=f"@font-face{{font-family:Inter{face};src:url(data:font/ttf;base64,{data}) format('truetype');}}\n"
        return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" role="img" aria-labelledby="title desc"><title id="title">QalaPulse investor one pager</title><desc id="desc">A citizen reporting platform, its current MVP, proposed organization subscriptions and invitation to pilot partners.</desc><defs><style>{css}</style></defs>\n'+ '\n'.join(self.svg)+'</svg>'


def icon(s,x,y,kind,color=BLUE):
    if kind=='camera':
        s.rect(x,y+3,17,12,'#FFFFFF',3,color,1.2);s.circle(x+8.5,y+9,3,'#FFFFFF',color,1.2)
        s.line([(x+4,y+3),(x+6,y),(x+11,y),(x+13,y+3)],color,1.2)
    elif kind=='detect':
        for dx,dy in [(0,0),(12,0),(0,12),(12,12)]: s.rect(x+dx,y+dy,4,4,color,1)
        s.line([(x+5,y+8),(x+8,y+11),(x+14,y+4)],color,1.2)
    elif kind=='map':
        s.line([(x,y+2),(x+5,y),(x+11,y+3),(x+17,y),(x+17,y+14),(x+11,y+17),(x+5,y+14),(x,y+16),(x,y+2)],color,1.2)
        s.line([(x+5,y),(x+5,y+14)],color,1);s.line([(x+11,y+3),(x+11,y+17)],color,1)
    else:
        s.circle(x+8,y+8,8,'#FFFFFF',color,1.2);s.line([(x+4,y+8),(x+7,y+11),(x+12,y+5)],color,1.3)


def phone(s,x,y):
    w,h=197,337
    s.rect(x+5,y+5,w,h,'#DDE5F2',25)
    s.rect(x,y,w,h,NAVY,24)
    s.rect(x+6,y+6,w-12,h-12,'#FFFFFF',19)
    s.rect(x+68,y+10,61,8,NAVY,4)
    s.text(x+16,y+20,'9:41',6.5,'SemiBold')
    s.text(x+157,y+20,'LTE',6.2,'SemiBold')
    s.text(x+16,y+42,'Your city, in view.',12,'Bold')
    s.text(x+16,y+56,'Almaty  /  Nearby issues',7.4,'Regular',MUTED)
    # Original schematic, not an OSM screenshot or measured incident data.
    mx,my=x+10,y+69
    s.rect(mx,my,177,136,'#EAF0F7',8)
    for dx,dy,ww,hh in [(8,10,34,23),(55,8,35,26),(106,12,58,20),(12,50,33,24),(57,48,25,23),(101,48,63,19),(5,98,40,28),(57,91,39,36),(118,90,47,33)]:
        s.rect(mx+dx,my+dy,ww,hh,'#DCE5EF',3)
    s.rect(mx+115,my+88,50,37,'#D3E9DF',5)
    for points in [[(mx+2,my+83),(mx+175,my+83)],[(mx+48,my+2),(mx+48,my+132)],[(mx+97,my+3),(mx+109,my+133)],[(mx+3,my+37),(mx+173,my+37)]]:s.line(points,'#FFFFFF',8)
    s.line([(mx+1,my+83),(mx+175,my+83)],'#B7CDED',.7)
    s.text(mx+116,my+79,'Abay Ave.',6,'Regular',MUTED)
    s.text(mx+123,my+108,'Park',6,'Regular','#50705E')
    for dx,dy,label,color in [(48,69,'R',BLUE),(108,42,'L',NAVY),(132,112,'W',BLUE)]:
        s.circle(mx+dx,my+dy,10,'#FFFFFF');s.circle(mx+dx,my+dy,8,color)
        s.text(mx+dx-2.4,my+dy+2.5,label,6.8,'Bold','#FFFFFF')
    s.circle(mx+82,my+104,5,'#FFFFFF');s.circle(mx+82,my+104,3,BLUE)
    for dx,ww,label in [(0,42,'All'),(47,58,'Roads'),(110,65,'Lighting')]:
        s.rect(x+13+dx,y+213,ww,17,BLUE if dx==0 else GRAY,8)
        s.text(x+24+dx,y+225,label,6.7,'SemiBold','#FFFFFF' if dx==0 else MUTED)
    s.rect(x+12,y+238,173,61,'#FFFFFF',8,LINE)
    s.rect(x+20,y+246,43,12,'#EAF2FF',4)
    s.text(x+25,y+254.5,'Published',6,'SemiBold',BLUE)
    s.text(x+20,y+269,'Open manhole near a bus stop',8,'SemiBold')
    s.text(x+20,y+282,'Community confirmations: 3',6.9,'Regular',MUTED)
    s.text(x+20,y+292,'Illustrative incident',5.8,'Regular',MUTED)
    s.text(x+21,y+317,'Home',6,'Regular',MUTED)
    s.text(x+59,y+317,'Map',6,'Bold',BLUE)
    s.circle(x+99,y+314,10,BLUE);s.line([(x+95,y+314),(x+103,y+314)],'#FFFFFF',1.3);s.line([(x+99,y+310),(x+99,y+318)],'#FFFFFF',1.3)
    s.text(x+120,y+317,'Alerts',6,'Regular',MUTED);s.text(x+155,y+317,'Profile',6,'Regular',MUTED)
    # AI concept chip below map, outside device to keep the screen readable.
    s.rect(x-33,y+150,144,34,'#FFFFFF',8,LINE)
    s.circle(x-20,y+167,5,BLUE);s.line([(x-22,y+167),(x-20,y+169),(x-17,y+164)],'#FFFFFF',.8)
    s.text(x-9,y+163,'AI suggestion / demo',7.4,'SemiBold')
    s.text(x-9,y+174,'Review before publishing',6.8,'Regular',MUTED)


def build(name,dark=False):
    path=TMP/f'{name}.pdf';s=Sheet(path)
    s.rect(0,0,W,H,'#FFFFFF')
    if dark:s.rect(0,0,W,435,NAVY)
    ink='#FFFFFF' if dark else NAVY
    sub='#B9C9E0' if dark else MUTED
    accent=CYAN if dark else BLUE
    s.logo(34,29,ink)
    s.text(363,43,'CIVICTECH  /  GOVTECH  /  AI',8,'SemiBold',sub)
    s.line([(34,67),(561,67)],'#29374C' if dark else LINE,.7)
    s.label(35,89,'CITIES BEGIN WITH PARTICIPATION',accent)
    for i,line in enumerate(['Every City Has','Problems.','Every Voice','Should Matter.']):
        s.text(33,124+i*35,line,30,'Bold',accent if i>=2 else ink)
    s.para(35,258,'QalaPulse - Turning everyday city issues into visible, actionable insights.',270,11.5,16,'SemiBold',ink)
    s.label(35,321,'THE PROBLEM',accent)
    s.para(35,340,'A broken road. A dark street. A report lost across channels. Residents need visibility; organizations need structured information.',267,10,14,color=sub)
    s.text(35,410,'BUILT FOR KAZAKHSTAN',7.7,'Bold',accent)
    s.text(35,424,'Russian + Kazakh  /  Citizen-first',8.4,'Regular',sub)
    phone(s,359,79)
    s.text(365,433,'Concept UI / schematic map / sample data',6.7,'Regular',sub)

    s.label(35,450,'OUR SOLUTION')
    steps=[('SNAP','Photo + location','camera'),('DETECT','AI aid + human review','detect'),('MAP','Visible local reports','map'),('TRACK','Statuses + confirmations','track')]
    for i,(title,caption,kind) in enumerate(steps):
        x=35+i*134
        icon(s,x,465,kind)
        s.text(x+25,476,title,10,'Bold')
        s.text(x,497,caption,8.3,'Regular',MUTED)
        if i<3:s.line([(x+109,471),(x+118,471),(x+115,468)],'#A7B6C8',.8)
    s.line([(35,511),(561,511)],LINE,.7)
    s.label(35,530,'WHY QALAPULSE? / INTENDED VALUE')
    for i,(title,copy) in enumerate([
        ('For citizens','Easier reporting.\nVisibility after submission.'),
        ('For cities','Structured information\nabout urban issues.'),
        ('For communities','A shared picture of\nlocal problems.')]):
        x=35+i*180
        s.text(x,549,title,11,'SemiBold')
        s.para(x,565,copy,166,9.2,12.5)

    s.rect(34,597,527,65,GRAY,9)
    s.label(47,614,'PRODUCT PROGRESS',NAVY)
    for i,(title,copy) in enumerate([
        ('Flutter MVP','RU/KK, auth, drafts, duplicates'),
        ('PostGIS + Docker','Backend and geospatial stack'),
        ('38 Flutter tests*','Reported technical checks')]):
        x=47+i*175
        s.text(x,635,title,12,'Bold',BLUE if i==2 else NAVY)
        s.text(x,650,copy,8,'Regular',MUTED)
    s.text(35,675,'*Repository QA report; not pilot outcomes. AI is mock-first; cloud quality is unvalidated.',7.3,'Regular',MUTED)
    s.text(35,687,'No government integration. Privacy redaction and device acceptance need pilot validation.',7.3,'Regular',MUTED)

    s.label(35,709,'BUSINESS OPPORTUNITY')
    s.para(35,725,'Free for residents. Proposed organization subscriptions for monitoring and analytics, plus implementation fees.',320,9.2,12.2)
    s.para(378,725,'Scale hypothesis: validate one local pilot, then repeat with new organizations.',179,9.2,12.2)
    s.text(35,764,'Pricing and buyer demand remain unvalidated.',7.4,'Regular',MUTED)
    s.rect(34,777,527,52,NAVY,8)
    s.text(47,798,"Let's Build Cities That Listen.",17,'Bold','#FFFFFF')
    s.text(47,811,'Seeking pilot partners, strategic collaborators and early-stage investors.',8.2,'Regular','#E1EAF7')
    s.text(47,823,'Contact: [Founder name] | [email / LinkedIn]',7.5,'Regular',CYAN)
    svg=s.finish()
    return path,svg,s.text_bounds


def main():
    OUT.mkdir(parents=True,exist_ok=True);TMP.mkdir(parents=True,exist_ok=True)
    results={}
    for name,dark in [('editorial',False),('navy',True)]:
        path,svg,bounds=build(name,dark)
        (TMP/f'{name}.svg').write_text(svg,encoding='utf-8')
        results[name]={'pdf':str(path),'text_bounds':bounds}
        if name=='editorial':
            shutil.copy2(path,OUT/'QalaPulse_Investor_OnePager.pdf')
            document='''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>QalaPulse | Investor One Pager</title><style>
*{box-sizing:border-box}body{margin:0;background:#e7ecf2;color:#09152b;font-family:Arial,sans-serif}
.toolbar{max-width:210mm;margin:20px auto;display:flex;gap:14px;align-items:center;padding:0 8px;font-size:13px}
button{border:0;border-radius:6px;background:#2878ff;color:white;padding:10px 16px;font:inherit;cursor:pointer}
main{width:210mm;height:297mm;margin:0 auto 32px;background:white;box-shadow:0 8px 32px #09152b16}
svg{display:block;width:100%;height:100%}button:focus-visible{outline:3px solid #09152b;outline-offset:3px}
@page{size:A4;margin:0}@media print{body{background:white}.toolbar{display:none}main{margin:0;box-shadow:none;break-inside:avoid}*{print-color-adjust:exact;-webkit-print-color-adjust:exact}}
@media screen and (max-width:820px){main{width:100%;height:auto;aspect-ratio:210/297}.toolbar{flex-wrap:wrap}}
</style></head><body><div class="toolbar"><button onclick="window.print()">Print / Save as PDF</button><span>Editable SVG text and vectors. Replace the contact placeholder before sending.</span></div><main aria-label="QalaPulse investor one pager">'''+svg+'''</main></body></html>'''
            (OUT/'QalaPulse_OnePager.html').write_text(add_editor(document),encoding='utf-8')
    (TMP/'layout_checks.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    pdf=PdfReader(OUT/'QalaPulse_Investor_OnePager.pdf')
    assert len(pdf.pages)==1
    page=pdf.pages[0]
    assert abs(float(page.mediabox.width)-W)<.1 and abs(float(page.mediabox.height)-H)<.1
    text=page.extract_text()
    for phrase in ['Every City Has','Should Matter.','38 Flutter tests','Seeking pilot partners','Contact: [Founder name]','No government integration']:
        assert phrase in text,phrase
    assert len(page.images)==0, 'Artwork must remain vector'
    print('PASS: one A4 page; expected claims and contact placeholder; vector graphics and extractable text.')
    print('Two compositions generated; editorial selected for print clarity and stronger phone contrast.')


if __name__=='__main__':main()
