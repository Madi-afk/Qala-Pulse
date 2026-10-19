// Shared, native editable Figma primitives. Containers use auto layout.
const PAGE_NAME = 'Lab 5–6 · QalaPulse UI & Prototype';
await Promise.all(['Regular','SemiBold','Bold'].map(style => figma.loadFontAsync({family:'Noto Sans',style})));
const rgb = hex => ({r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255});
const paint = key => figma.variables.setBoundVariableForPaint({type:'SOLID',color:rgb('#202D29')},'color',tokens[key]);
function frame(parent,name,w=350,h=10,dir='VERTICAL',fill=null,gap=12,pad=0,fixed=false){
  const n=figma.createFrame();n.name=name;n.resize(w,h);n.layoutMode=dir;n.primaryAxisSizingMode=dir==='VERTICAL'?(fixed?'FIXED':'AUTO'):'FIXED';n.counterAxisSizingMode=dir==='VERTICAL'?'FIXED':(fixed?'FIXED':'AUTO');n.fills=fill?[paint(fill)]:[];n.clipsContent=false;
  parent.appendChild(n);n.itemSpacing=gap;n.paddingTop=pad;n.paddingBottom=pad;n.paddingLeft=pad;n.paddingRight=pad;
  if(tokens['space/'+gap])n.setBoundVariable('itemSpacing',tokens['space/'+gap]);
  if(tokens['space/'+pad])for(const prop of ['paddingTop','paddingBottom','paddingLeft','paddingRight'])n.setBoundVariable(prop,tokens['space/'+pad]);
  return n;
}
function rounded(n,key='radius/14'){n.setBoundVariable('cornerRadius',tokens[key]);return n;}
async function txt(parent,value,style='Body',color='text',w=350){
  const n=figma.createText();n.name=value.slice(0,80);n.fontName=styles[style].fontName;n.characters=value;await n.setTextStyleIdAsync(styles[style].id);n.resize(w,20);n.textAutoResize='HEIGHT';n.fills=[paint(color)];parent.appendChild(n);return n;
}
function rect(parent,name,w,h,color,radius=null){const n=figma.createRectangle();n.name=name;n.resize(w,h);n.fills=[paint(color)];if(radius)rounded(n,radius);parent.appendChild(n);return n;}
const PATHS={
 home:'M3 10 12 3l9 7M5 9v12h5v-7h4v7h5V9',
 map:'M3 5l6-2 6 2 6-2v16l-6 2-6-2-6 2V5m6-2v16m6-14v16',
 plus:'M12 5v14M5 12h14',
 bell:'M6 9a6 6 0 0 1 12 0v6l2 3H4l2-3V9m4 12h4',
 user:'M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0M4 21v-2a8 8 0 0 1 16 0v2',
 camera:'M3 7h4l2-3h6l2 3h4v14H3V7m13 6a4 4 0 1 1-8 0 4 4 0 0 1 8 0',
 pin:'M19 9c0 5-7 12-7 12S5 14 5 9a7 7 0 1 1 14 0m-4 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
 check:'M5 12l4 4L20 5',
 arrow:'M5 12h14m-6-6 6 6-6 6',
 back:'M19 12H5m6-6-6 6 6 6',
 close:'m6 6 12 12M18 6 6 18',
 search:'M16 10a6 6 0 1 1-12 0 6 6 0 0 1 12 0m-2 4 7 7',
 filter:'M4 6h16M7 12h10m-7 6h4',
 mic:'M9 4a3 3 0 0 1 6 0v8a3 3 0 0 1-6 0V4M5 10v2a7 7 0 0 0 14 0v-2m-7 9v3m-4 0h8',
 warning:'M12 3 2 21h20L12 3m0 6v6m0 3v1',
 more:'M5 12h1m6 0h1m6 0h1',
 radar:'M21 12a9 9 0 1 1-9-9m0 3a6 6 0 1 0 6 6m-6-3a3 3 0 1 0 3 3m-3 0 8-8',
 image:'M3 3h18v18H3V3m0 14 6-7 4 4 3-3 5 6M7 7h1',
 wifi:'M2 8a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0m-10 4a5 5 0 0 1 6 0m-3 4h.1',
 clock:'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0m-9-6v6l4 2',
 edit:'m4 16 12-12 4 4L8 20H4v-4m10-10 4 4',
 play:'M7 3v18l14-9L7 3',
 shield:'M12 2 3 6v6c0 5 9 10 9 10s9-5 9-10V6l-9-4m-4 10 3 3 5-6'
};
function icon(parent,name,color='primary',size=24){
  const master=components['Icon/'+name];let n;
  if(master){n=master.createInstance();parent.appendChild(n);if(size!==24)n.rescale(size/24);}else{n=figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="'+PATHS[name]+'" fill="none" stroke="#24634C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>');parent.appendChild(n);if(size!==24)n.rescale(size/24);}
  n.name='Icon/'+name;for(const v of n.findAllWithCriteria({types:['VECTOR']}))if(v.strokes.length)v.strokes=[paint(color)];return n;
}
async function button(parent,label,target=null,kind='Primary',state='Default',width=350){
  const master=components['Button/'+kind+'/'+state];const n=master.createInstance();parent.appendChild(n);n.name=label;n.resize(width,52);
  const t=n.findAllWithCriteria({types:['TEXT']})[0];t.characters=state==='Loading'?'Please wait…':label;t.resize(width-32,22);
  if(target&&state==='Default')links.push({node:n,target});return n;
}
async function field(parent,label,value,target=null,state='Default'){
  const n=components['Input/'+state].createInstance();parent.appendChild(n);n.name='Field / '+label;
  const t=n.findAllWithCriteria({types:['TEXT']});t[0].characters=label;t[1].characters=value;
  if(target)links.push({node:n,target});return n;
}
async function badge(parent,label,color='primary',bg='secondary',width=170){const n=rounded(frame(parent,label,width,28,'HORIZONTAL',bg,4,0,true),'radius/8');n.counterAxisAlignItems='CENTER';n.primaryAxisAlignItems='CENTER';const t=await txt(n,label,'Caption',color,width-12);t.textAlignHorizontal='CENTER';return n;}
async function note(parent,value,tone='secondary',symbol='shield'){const n=rounded(frame(parent,'Notice',350,10,'HORIZONTAL',tone,8,12));icon(n,symbol,tone==='warningBg'?'accent':'primary',20);await txt(n,value,'Caption',tone==='warningBg'?'accent':'muted',298);return n;}
async function heading(parent,title,subtitle=null){await txt(parent,title,'Heading');if(subtitle)await txt(parent,subtitle,'Body','muted');}
async function top(parent,title,back=null){const n=frame(parent,'App bar',350,48,'HORIZONTAL',null,12,0,true);n.counterAxisAlignItems='CENTER';if(back){const b=frame(n,'Back',44,44,'HORIZONTAL',null,0,10,true);icon(b,'back');links.push({node:b,target:back});}else{const mark=rounded(frame(n,'QalaPulse',36,36,'HORIZONTAL','primary',0,6,true),'radius/12');icon(mark,'radar','surface');}await txt(n,title,'Subheading','text',back?238:290);return n;}
async function mapArt(parent,h=240){
  const n=rounded(frame(parent,'Map / illustrative Almaty block',350,h,'VERTICAL','secondary',0,0,true));n.clipsContent=true;
  const art=figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="350" height="'+h+'" viewBox="0 0 350 240"><rect width="350" height="240" fill="#E5EDE4"/><g fill="#D2DECf"><rect x="20" y="15" width="75" height="70" rx="10"/><rect x="230" y="140" width="90" height="78" rx="12"/></g><g stroke="#FFFFFF" fill="none" stroke-width="14"><path d="M-20 96L380 140M110-20 70 270M260-20 208 270M-20 204 380 228M-20 28 380 57"/></g><g fill="#DFE3DB"><rect x="124" y="62" width="54" height="30" rx="4"/><rect x="272" y="74" width="60" height="35" rx="4"/><rect x="113" y="153" width="63" height="41" rx="4"/><rect x="12" y="126" width="38" height="54" rx="4"/></g><circle cx="188" cy="122" r="32" fill="#24634C" opacity=".12"/><circle cx="188" cy="122" r="13" fill="#24634C" stroke="white" stroke-width="4"/><circle cx="80" cy="190" r="9" fill="#A34D19" stroke="white" stroke-width="3"/></svg>');n.appendChild(art);art.resize(350,h);return n;
}
async function demoImage(parent,h=190){
  const n=rounded(frame(parent,'Demo incident image',350,h,'VERTICAL','secondary',0,0,true));n.clipsContent=true;
  const art=figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="350" height="'+h+'" viewBox="0 0 350 190"><rect width="350" height="190" fill="#DCE5DE"/><path d="M125 0h100l100 190H25z" fill="#687970"/><path d="m93 70-22 38 29 21 22-18 54 15 48-10 15-33-31-26-61 9z" fill="#293C32"/><path d="m89 76 28 13 44-15 42 0 21 26" fill="none" stroke="#9CAA9E" stroke-width="8"/><path d="m155 2-5 30m50 109 14 43" stroke="#E6DDAB" stroke-width="5"/><path d="m15 15 17 27m292-16-15 32" stroke="#ADC1AB" stroke-width="14"/></svg>');n.appendChild(art);art.resize(350,h);return n;
}
async function card(parent,target='details',title='Pothole near the bus stop',meta='Abay Avenue · 120 m away'){
  const n=components.IncidentCard.createInstance();parent.appendChild(n);n.name='Incident / '+title;
  const t=n.findAllWithCriteria({types:['TEXT']});t.find(x=>x.name==='Card title').characters=title;t.find(x=>x.name==='Card meta').characters=meta;
  const count=t.find(x=>x.characters.includes('confirmations'));const status=t.find(x=>x.characters==='Published in QalaPulse');
  if(meta.startsWith('Draft')){status.characters='Draft · waiting to be sent';status.parent.fills=[paint('warningBg')];status.fills=[paint('accent')];count.characters='Not published · saved on this device';}
  else if(title==='Pothole beside the crossing')count.characters='High priority  ·  0 confirmations';
  if(target)links.push({node:n,target});return n;
}
async function nav(parent,active){const n=components['Navigation/'+active].createInstance();parent.appendChild(n);n.name='Bottom navigation';n.x=0;n.y=760;for(const c of n.children){if(c.name.startsWith('Tab/')){const id=c.name.slice(4);if(id!==active)links.push({node:c,target:id==='create'?'photo':id});}}return n;}
async function screen(id,title,back=null,active=null){const f=figma.createFrame();f.name=id+' · '+title;f.resize(390,844);f.fills=[paint('background')];f.clipsContent=true;page.appendChild(f);const i=Object.keys(screens).length;f.x=80+(i%6)*470;f.y=1780+Math.floor(i/6)*970;screens[id]=f;
  const b=frame(f,'Screen content',350,10,'VERTICAL',null,12);b.x=20;b.y=16;
  const status=frame(b,'Status bar',350,18,'HORIZONTAL',null,0,0,true);await txt(status,'9:41','Caption','text',290);await txt(status,'•••  ▰','Caption','text',60);
  await top(b,title,back);if(active)await nav(f,active);return b;
}
async function footer(body,label,target,secondary=null){const f=body.parent;const b=frame(f,'Actions',350,10,'VERTICAL','background',8);b.x=20;b.y=secondary?688:744;await button(b,label,target);if(secondary)await button(b,secondary.label,secondary.target,'Secondary');return b;}
async function step(body,num,title,sub){await txt(body,'REPORT AN ISSUE  /  '+num+' OF 5','Caption','primary');const p=frame(body,'Step progress',350,4,'HORIZONTAL',null,4,0,true);for(let i=1;i<=5;i++)rect(p,'Step '+i,66.8,4,i<=num?'primary':'line','radius/8');await heading(body,title,sub);}
