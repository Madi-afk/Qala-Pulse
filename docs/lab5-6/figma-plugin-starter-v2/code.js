// QalaPulse Lab 5–6. Generated from local sources; no network access.
async function buildFoundations(){
const page=figma.currentPage;
const tokens={},styles={},components={},links=[];
const primitive=figma.variables.createVariableCollection('QalaPulse UI / Primitives');
const semantic=figma.variables.createVariableCollection('QalaPulse UI / Semantic');
// Semantic alias construction follows createSemanticTokens.js from figma-generate-library.
const palette={primary:'#24634C',secondary:'#E5EDE4',background:'#F6F5F0',text:'#202D29',accent:'#A34D19',muted:'#5E6B64',line:'#DFE3DB',surface:'#FFFFFF',warningBg:'#F8EBDD',error:'#B3261E',errorBg:'#FCEAE8',disabled:'#DFE3DB',pressed:'#194733'};
for(const [name,hex]of Object.entries(palette)){
  const color={r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255};
  const p=figma.variables.createVariable('color/'+name,primitive,'COLOR');p.scopes=[];p.setValueForMode(primitive.defaultModeId,color);p.setVariableCodeSyntax('WEB','var(--qp-raw-'+name+')');
  const v=figma.variables.createVariable(name,semantic,'COLOR');v.scopes=['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR'];v.setValueForMode(semantic.defaultModeId,{type:'VARIABLE_ALIAS',id:p.id});v.setVariableCodeSyntax('WEB','var(--qp-'+name+')');tokens[name]=v;
}
for(const [prefix,values,scope] of [['space',[0,4,8,12,16,20,24,32],'GAP'],['radius',[8,12,14,24],'CORNER_RADIUS']])for(const value of values){const v=figma.variables.createVariable(prefix+'/'+value,semantic,'FLOAT');v.scopes=[scope];v.setValueForMode(semantic.defaultModeId,value);v.setVariableCodeSyntax('WEB','var(--qp-'+prefix+'-'+value+')');tokens[prefix+'/'+value]=v;}
await Promise.all(['Regular','SemiBold','Bold'].map(style=>figma.loadFontAsync({family:'Noto Sans',style})));
for(const [name,size,line,weight]of [['Display',32,38,'Bold'],['Heading',28,34,'Bold'],['Subheading',20,26,'Bold'],['Body',14,21,'Regular'],['Button',15,22,'SemiBold'],['Caption',12,18,'Regular']]){const s=figma.createTextStyle();s.name='QalaPulse UI/'+name;s.fontName={family:'Noto Sans',style:weight};s.fontSize=size;s.lineHeight={unit:'PIXELS',value:line};styles[name]=s;}
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

const masters=frame(page,'Component masters',2750,10,'VERTICAL',null,24);masters.x=6500;masters.y=80;
for(const name of Object.keys(PATHS)){const c=figma.createComponent();c.name='QalaPulse/Icon/'+name;c.resize(24,24);c.fills=[];masters.appendChild(c);icon(c,name);components['Icon/'+name]=c;c.description='24px outline icon; use with a text label or accessible name.';}
const variants=[];
for(const kind of ['Primary','Secondary'])for(const state of ['Default','Pressed','Disabled','Loading']){
  const c=figma.createComponent();c.name='Style='+kind+', State='+state;c.resize(350,52);c.layoutMode='HORIZONTAL';c.primaryAxisAlignItems='CENTER';c.counterAxisAlignItems='CENTER';rounded(c,'radius/14');c.fills=[paint(state==='Disabled'?'disabled':kind==='Secondary'?'surface':state==='Pressed'?'pressed':'primary')];c.strokes=kind==='Secondary'?[paint('line')]:[];
  const t=await txt(c,state==='Loading'?'Please wait…':'Continue','Button',state==='Disabled'?'muted':kind==='Primary'?'surface':'primary',318);t.textAlignHorizontal='CENTER';variants.push(c);components['Button/'+kind+'/'+state]=c;
}
// Variant grid follows createComponentWithVariants.js. Native product shapes replace generic kit defaults.
const bs=figma.combineAsVariants(variants,page);bs.name='QalaPulse/Button';masters.appendChild(bs);bs.resize(1520,170);variants.forEach((c,i)=>{c.x=16+(i%4)*374;c.y=16+Math.floor(i/4)*78;});bs.description='52px target, radius 14. Primary for the next step; secondary for alternatives. Disabled and loading states have no navigation.';
const labelProperty=bs.addComponentProperty('Label','TEXT','Continue');variants.forEach(c=>{c.findAllWithCriteria({types:['TEXT']})[0].componentPropertyReferences={characters:labelProperty};});
const inputs=[];
for(const state of ['Default','Focus','Error']){const c=figma.createComponent();c.name='State='+state;c.resize(350,80);c.layoutMode='VERTICAL';c.primaryAxisSizingMode='FIXED';c.counterAxisSizingMode='FIXED';c.paddingTop=12;c.paddingBottom=12;c.paddingLeft=16;c.paddingRight=16;c.itemSpacing=4;c.fills=[paint('surface')];c.strokes=[paint(state==='Focus'?'primary':state==='Error'?'error':'line')];c.strokeWeight=state==='Default'?1:2;rounded(c,'radius/12');await txt(c,'Field label','Caption','muted',318);await txt(c,'Your text here','Body','text',318);inputs.push(c);components['Input/'+state]=c;}
const ins=figma.combineAsVariants(inputs,page);ins.name='QalaPulse/Input';masters.appendChild(ins);ins.resize(1140,112);inputs.forEach((c,i)=>{c.x=16+i*374;c.y=16;});ins.description='Persistent label, 80px field, radius 12. Error needs explanatory helper text. Prototype fields use preset values.';
for(const [name,index,value]of [['Label',0,'Field label'],['Value',1,'Your text here']]){const key=ins.addComponentProperty(name,'TEXT',value);inputs.forEach(c=>{c.children[index].componentPropertyReferences={characters:key};});}
const search=figma.createComponent();search.name='QalaPulse/Search';search.resize(350,52);search.layoutMode='HORIZONTAL';search.counterAxisAlignItems='CENTER';search.paddingLeft=16;search.paddingRight=16;search.itemSpacing=12;search.fills=[paint('surface')];search.strokes=[paint('line')];rounded(search,'radius/12');icon(search,'search','muted');await txt(search,'Search nearby issues','Body','muted',280);masters.appendChild(search);components.Search=search;search.description='Search entry point; opens a preset search state in this prototype.';
const c=figma.createComponent();c.name='QalaPulse/IncidentCard';c.resize(350,174);c.layoutMode='VERTICAL';c.primaryAxisSizingMode='AUTO';c.counterAxisSizingMode='FIXED';c.paddingTop=16;c.paddingBottom=16;c.paddingLeft=16;c.paddingRight=16;c.itemSpacing=8;c.fills=[paint('surface')];c.strokes=[paint('line')];rounded(c);await badge(c,'Published in QalaPulse','primary','secondary',178);(await txt(c,'Pothole near the bus stop','Button','text',318)).name='Card title';(await txt(c,'Abay Avenue · 120 m away','Caption','muted',318)).name='Card meta';await txt(c,'High priority  ·  3 confirmations','Caption','accent',318);masters.appendChild(c);components.IncidentCard=c;c.description='Issue card: status, title, location, priority and community confirmation. Values are illustrative demo data.';
for(const active of ['home','map','create','events','profile']){
  const n=figma.createComponent();n.name='QalaPulse/Navigation/'+active;n.resize(390,84);n.layoutMode='HORIZONTAL';n.paddingLeft=10;n.paddingRight=10;n.paddingTop=8;n.paddingBottom=12;n.itemSpacing=0;n.fills=[paint('background')];
  for(const [id,label,symbol]of [['home','Home','home'],['map','Map','map'],['create','Create','plus'],['events','Updates','bell'],['profile','Profile','user']]){const t=frame(n,'Tab/'+id,74,64,'VERTICAL',null,4,0,true);t.counterAxisAlignItems='CENTER';const pill=rounded(frame(t,'Selection',56,32,'HORIZONTAL',id===active?'secondary':null,0,4,true),'radius/24');pill.primaryAxisAlignItems='CENTER';icon(pill,symbol,id===active?'primary':'muted');const l=await txt(t,label,'Caption',id===active?'primary':'muted',74);l.textAlignHorizontal='CENTER';}
  masters.appendChild(n);components['Navigation/'+active]=n;n.description='Five top-level destinations. Selected tab is not a self-navigation target.';
}
const header=frame(page,'00 · Design system / foundations',2750,560,'VERTICAL','surface',24,32,true);header.x=80;header.y=80;
await txt(header,'QalaPulse / A city shaped by its people','Display','text',2650);await txt(header,'LAB 05 — UI DESIGN & DESIGN SYSTEM     /     LAB 06 — INTERACTIVE PROTOTYPE','Button','primary',2650);
const swatches=frame(header,'Color palette',2650,128,'HORIZONTAL',null,16,0,true);
for(const [name,label]of [['primary','Primary'],['secondary','Secondary'],['background','Background'],['text','Text'],['accent','Accent']]){const sw=frame(swatches,label,250,10,'VERTICAL',null,8);rounded(rect(sw,label,250,64,name),'radius/12');await txt(sw,label+'  '+palette[name],'Button','text',250);}
await txt(header,'Noto Sans · one family · Regular / SemiBold / Bold','Subheading','text',2600);
await txt(header,'Heading 28/34    Subheading 20/26    Body 14/21    Button 15/22    Caption 12/18','Body','muted',2600);
await txt(header,'8px spacing rhythm · 20px screen gutters · 52px buttons · 14px cards · 12px inputs · 24px icons · 390 × 844 mobile frames','Body','muted',2600);
const showcase=frame(page,'01 · UI component library / instances',2750,1000,'VERTICAL','surface',24,32,true);showcase.x=80;showcase.y=700;
await txt(showcase,'Reusable components, consistent decisions.','Heading','text',2620);
const row=frame(showcase,'Buttons and fields',2640,10,'HORIZONTAL',null,24);
const col=frame(row,'Button states',350,10,'VERTICAL',null,12);await txt(col,'Buttons / 52px','Subheading');await button(col,'Report an issue');await button(col,'Save draft',null,'Secondary');await button(col,'Pressed',null,'Primary','Pressed');await button(col,'Continue',null,'Primary','Disabled');await button(col,'Please wait',null,'Primary','Loading');
const col2=frame(row,'Input states',350,10,'VERTICAL',null,12);await txt(col2,'Inputs / 80px','Subheading');await field(col2,'Title','Pothole near the bus stop');await field(col2,'Email','madi@example.com',null,'Focus');await field(col2,'Email','madi',null,'Error');await txt(col2,'Enter a valid email address.','Caption','error');
const col3=frame(row,'Cards and search',350,10,'VERTICAL',null,12);await txt(col3,'Cards & search','Subheading');col3.appendChild(search.createInstance());await card(col3,null);
const col4=frame(row,'Navigation and icons',450,10,'VERTICAL',null,16);await txt(col4,'Navigation & icons','Subheading','text',450);col4.appendChild(components['Navigation/home'].createInstance());const ir=frame(col4,'Icon family',420,24,'HORIZONTAL',null,16,0,true);for(const name of ['camera','pin','mic','shield','edit','warning','check'])icon(ir,name);
await txt(col4,'Icons carry meaning alongside labels.\nStatus uses text and color, never color alone.','Body','muted',420);
const typography=frame(showcase,'Typography styles',2630,10,'HORIZONTAL',null,32);
for(const [style,sample] of [['Heading','Your city.\nYour voice.'],['Subheading','Issues near you'],['Body','A photo, a location and a clear description help neighbours understand the issue.'],['Button','Report an issue'],['Caption','Published in QalaPulse']]){const box=frame(typography,style,350,10,'VERTICAL',null,12);await txt(box,style,'Caption','muted');await txt(box,sample,style);}
await txt(showcase,'Component use: primary buttons move the task forward; secondary buttons offer alternatives. All fields keep their labels. Modals ask for a decision and always include Cancel.','Body','muted',2520);
await txt(showcase,'Prototype scope: English classroom design based on the RU/KK Flutter app. Camera, location, AI and network actions are simulated. All locations and counts are demonstration data.','Caption','muted',2520);
const result={pageId:page.id,collections:{primitive:primitive.id,semantic:semantic.id},styles:Object.fromEntries(Object.entries(styles).map(([k,v])=>[k,v.id])),components:Object.fromEntries(Object.entries(components).map(([k,v])=>[k,v.id])),tokens:Object.fromEntries(Object.entries(tokens).map(([k,v])=>[k,v.id])),createdNodeIds:[page.id,...page.findAll(()=>true).map(n=>n.id)],reviewFrames:[header.id,showcase.id]};
return result;

}
async function buildScreens(ledger){

const page=await figma.getNodeByIdAsync(ledger.pageId);await figma.setCurrentPageAsync(page);
const tokens={},styles={},components={};
for(const [key,id]of Object.entries(ledger.tokens))tokens[key]=await figma.variables.getVariableByIdAsync(id);
for(const [key,id]of Object.entries(ledger.styles))styles[key]=await figma.getStyleByIdAsync(id);
for(const [key,id]of Object.entries(ledger.components))components[key]=await figma.getNodeByIdAsync(id);

// Requires page, styles, components and tokens restored from the foundation ledger.
const screens={},overlays={},links=[];
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

let b=await screen('home','QalaPulse',null,'home');
await txt(b,'Good morning, Madi','Body','muted');await heading(b,'Your city starts\nwith you.','Spot an issue. Help your neighbours. Follow the change.');
await button(b,'Report an issue','photo');await button(b,'Explore the map','map','Secondary');
await txt(b,'Needs attention','Subheading');await card(b);await note(b,'Published here does not mean submitted to a government agency.');

b=await screen('map','Explore nearby','home','map');
const search=components.Search.createInstance();b.appendChild(search);links.push({node:search,target:'search'});
await button(b,'Categories & filters','@filters','Secondary');const m=await mapArt(b,230);links.push({node:m,target:'details'});
await txt(b,'Abay Avenue · within 1 km','Caption','muted');await card(b);await txt(b,'Illustrative map · tap a marker to view an issue','Caption','muted');

b=await screen('search','Search results','map','map');await field(b,'Search','pothole');await txt(b,'1 matching issue nearby','Subheading');await card(b);await button(b,'Clear search','map','Secondary');
b=await screen('filtered','Road issues nearby','map','map');await badge(b,'Road damage · 1 km');const fm=await mapArt(b,260);links.push({node:fm,target:'created'});await card(b,'created','Pothole beside the crossing','Abay Avenue · 180 m away');await button(b,'Reset filters','map','Secondary');

async function detail(id,created=false,confirmed=false){const d=await screen(id,created?'Your report':'Issue details',created?'success':'map');
await badge(d,'Published in QalaPulse','primary','secondary',178);await heading(d,created?'Pothole beside\nthe crossing':'Pothole near\nthe bus stop');await demoImage(d,140);await txt(d,'Illustrative image · no personal data','Caption','muted');
await txt(d,'Abay Avenue, Almaty · '+(created?'just now':'today, 09:12'),'Caption','muted');await txt(d,created?'A deep pothole beside the pedestrian crossing makes the road unsafe.':'A deep pothole beside the bus stop makes the road unsafe. Please take care here.','Body');
await txt(d,created?'High priority · road safety risk':confirmed?'High priority · 4 residents confirmed':'High priority · 3 residents confirmed','Button','accent');
const timeline=frame(d,'Status history',350,10,'VERTICAL','surface',4,12);await txt(timeline,'Status history','Button','text',326);await txt(timeline,'● Published in QalaPulse  →  awaiting review','Caption','muted',326);
if(confirmed)await note(d,'Your confirmation was added. You cannot confirm the same status twice.');
else await button(d,created?'More options':'Problem still exists',created?'@more':'@confirmExists','Secondary');
await footer(d,created?'View on map':'Report a resolution',created?'filtered':'@resolution');return d;}
await detail('details');await detail('confirmed',false,true);

b=await screen('login','Welcome back','home');await heading(b,'A better city,\ntogether.','Sign in to report an issue and follow its progress.');await field(b,'Email','madi@example.com');await field(b,'Password','••••••••••••');await note(b,'Classroom prototype: sign-in uses a preset account.');await footer(b,'Sign in','home');

b=await screen('photo','New report','home');await step(b,1,'Start with a photo','Show the issue clearly and avoid including people.');const upload=rounded(frame(b,'Photo upload',350,224,'VERTICAL','secondary',16,24,true));upload.primaryAxisAlignItems='CENTER';upload.counterAxisAlignItems='CENTER';icon(upload,'camera','primary',48);const u=await txt(upload,'Add a photo','Subheading','primary',302);u.textAlignHorizontal='CENTER';const uc=await txt(upload,'Camera or gallery','Body','muted',302);uc.textAlignHorizontal='CENTER';links.push({node:upload,target:'@photoSource'});await note(b,'You will review the public image before publishing.');await button(b,'Choose photo','@photoSource');await button(b,'Continue',null,'Primary','Disabled');

b=await screen('photoReady','New report','photo');await step(b,1,'Photo added','A clear image helps others understand the issue.');await demoImage(b,224);await txt(b,'Demo image · road damage','Caption','muted');await button(b,'Replace photo','@photoSource','Secondary');await footer(b,'Continue','location');

b=await screen('location','New report','photoReady');await step(b,2,'Where is the issue?','Confirm the location or choose a point manually.');const lm=await mapArt(b,220);links.push({node:lm,target:'@location'});await field(b,'Location','Abay Avenue, Almaty','@location');await txt(b,'43.2389° N, 76.8897° E · demo coordinates','Caption','muted');await button(b,'Choose point manually','@location','Secondary');await footer(b,'Confirm location','describe');

b=await screen('describe','New report','location');await step(b,3,'Tell us what happened','Add a short description or a voice note.');await field(b,'Description','Pothole beside the pedestrian crossing.','@editDescription');await button(b,'Record a voice note','@voice','Secondary');await note(b,'Your description stays in the draft if the connection drops.');await footer(b,'Analyse issue','analyze',{label:'Save draft',target:'draft'});

b=await screen('analyze','Reviewing your report','describe');await step(b,4,'Preparing a suggestion','Your photo and description stay together.');const progress=rounded(frame(b,'Analysis progress',350,180,'VERTICAL','secondary',20,24,true));progress.primaryAxisAlignItems='CENTER';icon(progress,'radar','primary',48);await txt(progress,'Organising the details…','Subheading','primary',302);await txt(progress,'You make the final decision.','Body','muted',302);await note(b,'Mock AI demo: suggestions come from preset text, not image recognition.','warningBg','warning');await button(b,'Analysing…',null,'Primary','Loading');links.push({node:screens.analyze,target:'review',timeout:1.4});

async function review(id,checked){const d=await screen(id,'Review suggestion','describe');await step(d,4,'Make it accurate','Check every field before continuing.');await field(d,'Category','Road damage','@editCategory');await field(d,'Title','Pothole beside the crossing','@editTitle');await field(d,'Severity','7 / 10 — high','@editSeverity');await note(d,'Demo suggestion · confidence not measured. You can edit the result.','warningBg','warning');
const gate=rounded(frame(d,'Review confirmation',350,52,'HORIZONTAL',checked?'secondary':'surface',12,12,true));icon(gate,checked?'check':'shield');await txt(gate,checked?'I reviewed these details':'Tap to confirm you reviewed the details','Caption','text',290);links.push({node:gate,target:checked?'review':'reviewReady',smart:true});
const act=frame(d.parent,'Actions',350,52,'VERTICAL','background',0,0,true);act.x=20;act.y=744;await button(act,'Find similar issues',checked?'duplicates':null,'Primary',checked?'Default':'Disabled');return d;}
await review('review',false);await review('reviewReady',true);

b=await screen('duplicates','Similar issues','reviewReady');await step(b,5,'Already reported?','Confirm an existing issue or publish a new one.');await badge(b,'1 possible match','accent','warningBg');await card(b,'details','Pothole near the bus stop','Abay Avenue · 85 m from your point');await txt(b,'Nearby location · similar description · today','Caption','muted');await note(b,'A match is only a suggestion. Reports are never merged automatically.');await footer(b,'Confirm existing issue','@confirmExists',{label:'Create a new report',target:'@publication'});

b=await screen('success','Report published');const done=rounded(frame(b,'Success mark',80,80,'HORIZONTAL','secondary',0,20,true),'radius/24');icon(done,'check','primary',40);await heading(b,'Your voice is\non the map.','Your report is now visible in QalaPulse.');await badge(b,'Published in QalaPulse','primary','secondary',178);await card(b,'created','Pothole beside the crossing','Your report · just now');await note(b,'No government submission has been made. Follow updates here.');await footer(b,'View my report','created',{label:'Back to home',target:'home'});
await detail('created',true);

b=await screen('draft','Draft saved','describe');icon(b,'wifi','primary',48);await heading(b,'Ready when you are.','Your photo, location and description are saved on this device.');await card(b,null,'Pothole beside the crossing','Draft · waiting to be sent');await note(b,'Retry keeps the same report; it does not create a second copy.');await footer(b,'Resume draft','describe',{label:'Back to home',target:'home'});

b=await screen('events','Updates','home','events');await heading(b,'Stay in the loop.');const event=rounded(frame(b,'Publication event',350,10,'VERTICAL','surface',12,16));await txt(event,'Your report is published','Button','text',318);await txt(event,'Pothole beside the crossing · just now','Caption','muted',318);await txt(event,'Open the report to see its status and community updates.','Body','text',318);links.push({node:event,target:'created'});await note(b,'Updates reflect activity inside QalaPulse.');

b=await screen('profile','Your profile','home','profile');icon(b,'user','primary',48);await heading(b,'Madi','madi@example.com');await button(b,'My reports','created','Secondary');await button(b,'My confirmations','confirmed','Secondary');await button(b,'Saved draft','draft','Secondary');await button(b,'Language & settings','@settings','Secondary');await button(b,'Sign out','login','Secondary');await txt(b,'English classroom design. App languages: RU / KK.','Caption','muted');

// Full-screen transparent overlays avoid unsupported read-only overlay-position properties.
async function modal(id,title,message,choices){
  const f=figma.createFrame();f.name='Overlay / '+id;f.resize(390,844);f.fills=[{type:'SOLID',color:rgb('#202D29'),opacity:.42}];f.clipsContent=true;page.appendChild(f);const i=Object.keys(overlays).length;f.x=80+(i%6)*470;f.y=7000+Math.floor(i/6)*970;overlays[id]=f;
  const panel=rounded(frame(f,'Dialog / '+title,350,10,'VERTICAL','surface',16,20),'radius/24');panel.x=20;panel.y=210;
  await txt(panel,title,'Subheading','text',310);await txt(panel,message,'Body','muted',310);
  for(const ch of choices)await button(panel,ch.label,ch.target,ch.secondary?'Secondary':'Primary','Default',310);
  await button(panel,'Cancel','close','Secondary','Default',310);return f;
}
await modal('photoSource','Add a photo','Choose the source for your report. The prototype uses an illustrative demo image.',[{label:'Take a photo',target:'photoReady'},{label:'Choose from gallery',target:'photoReady',secondary:true}]);
await modal('location','Confirm this point','Abay Avenue, Almaty\n43.2389° N, 76.8897° E\n\nIn the app you can move the map pin. This prototype uses a preset point.',[{label:'Use this location',target:'describe'}]);
await modal('filters','Filter the map','Choose which issues to show within 1 km.',[{label:'Road damage',target:'@filtersRoad',secondary:true},{label:'All categories',target:'map'}]);
await modal('filtersRoad','Map filters','✓ Road damage selected\nRadius: 1 km',[{label:'Apply filters',target:'filtered'}]);
await modal('publication','Publish this report?','Your photo, description and location will be visible in QalaPulse. This does not submit an official government request.',[{label:'Publish report',target:'success'},{label:'Preview network error',target:'@offline',secondary:true}]);
await modal('offline','Connection lost','Your draft is safe. Retry when you are online; the same report will only be created once.',[{label:'Retry publication',target:'success'},{label:'Keep as draft',target:'draft',secondary:true}]);
await modal('confirmExists','Confirm this issue?','Add your confirmation that the nearby issue still exists. No new report will be created.',[{label:'Yes, it still exists',target:'confirmed'}]);
await modal('resolution','Has it been fixed?','Your feedback helps residents verify the result. A report is not automatically resolved by this prototype.',[{label:'Yes, fully resolved',target:'@feedback'},{label:'Only partly resolved',target:'@feedback',secondary:true}]);
await modal('feedback','Thank you','Your feedback has been recorded in this demo. The report remains available for community review.',[{label:'Back to the issue',target:'details'}]);
await modal('more','Report options','Choose an action for this report.',[{label:'Report inappropriate content',target:'@report',secondary:true},{label:'Open the map',target:'filtered',secondary:true}]);
await modal('report','Report inappropriate content','Reason: contains personal information.\n\nA moderator will review the report.',[{label:'Send content report',target:'@reported'}]);
await modal('reported','Report received','Your content report was sent for moderation in this demo.',[{label:'Back to my report',target:'created'}]);
await modal('voice','Voice description','Russian and Kazakh are supported in the app. This prototype simulates a short voice recording.',[{label:'Start recording',target:'@recording'}]);
await modal('recording','Recording · 00:08','▂ ▅ ▃ ▇ ▄ ▆ ▂ ▅ ▃ ▇\n\nDescribe what you see and where it is.',[{label:'Stop recording',target:'@transcript'}]);
await modal('transcript','Review transcript','“A pothole beside the pedestrian crossing makes the road unsafe.”\n\nDemo transcript. Check the text before using it.',[{label:'Use this description',target:'describe'},{label:'Record again',target:'@recording',secondary:true}]);
await modal('editDescription','Edit description','Preset editing example:\nPothole beside the pedestrian crossing.',[{label:'Save description',target:'describe'}]);
await modal('editCategory','Choose a category','Current selection: Road damage.\nOther app categories include garbage, open manholes and street lights.',[{label:'Use Road damage',target:'review'}]);
await modal('editTitle','Edit title','Preset editing example:\nPothole beside the crossing',[{label:'Save title',target:'review'}]);
await modal('editSeverity','Review severity','Current severity: 7 / 10.\nPotential danger to vehicles and pedestrians.',[{label:'Confirm 7 / 10',target:'review'}]);
await modal('settings','Language & settings','The production app supports Russian and Kazakh. This English version is for the laboratory submission.',[{label:'Done',target:'profile'}]);

for(const link of links){
  let action;const overlay=link.target.startsWith('@');
  if(link.target==='close')action={type:'CLOSE'};
  else{const target=overlay?overlays[link.target.slice(1)]:screens[link.target];if(!target)throw new Error('Missing destination: '+link.target);
    let owner=link.node;while(owner.parent&&owner.parent.type!=='PAGE')owner=owner.parent;
    if(owner.id===target.id)continue;
    const fromOverlay=Object.values(overlays).some(n=>n.id===owner.id);
    action={type:'NODE',destinationId:target.id,navigation:overlay?(fromOverlay?'SWAP':'OVERLAY'):'NAVIGATE',transition:{type:link.smart?'SMART_ANIMATE':'DISSOLVE',easing:{type:'EASE_OUT'},duration:link.smart?.2:.18},resetScrollPosition:true};
  }
  await link.node.setReactionsAsync([{trigger:link.timeout?{type:'AFTER_TIMEOUT',timeout:link.timeout}:{type:'ON_CLICK'},actions:[action]}]);
}
// Main dialog components stay outside the review frames; overlays contain instances.
const dialogMasters=frame(page,'Dialog & menu masters',2100,10,'VERTICAL',null,24);dialogMasters.x=9400;dialogMasters.y=80;
const dialogReview=frame(page,'03 · Dialogs and menus / instances',2750,560,'HORIZONTAL','surface',24,24,true);dialogReview.x=3100;dialogReview.y=800;
const dialogComponents=[];
for(const [key,overlay]of Object.entries(overlays)){
  const panel=overlay.children[0];const component=figma.createComponentFromNode(panel);component.name='QalaPulse/Dialog/'+key;component.description='Dialog with explicit cancel and decision actions. Prototype data is illustrative.';dialogMasters.appendChild(component);dialogComponents.push(component);
  const instance=component.createInstance();overlay.appendChild(instance);instance.x=20;instance.y=210;
  if(['photoSource','publication','offline','more','filters'].includes(key))dialogReview.appendChild(component.createInstance());
}
const ownedRoots=[...Object.values(screens),...Object.values(overlays),dialogMasters,dialogReview,page.children.find(n=>n.name==='00 · Design system / foundations')];
const board=await ensureFlowBoard(page,ownedRoots);
setLabFlowStarts(page,[...Object.values(screens),...Object.values(overlays),dialogMasters,dialogReview,board]);
const ids=[board,dialogMasters,dialogReview,...Object.values(screens),...Object.values(overlays)].flatMap(n=>[n.id,...n.findAll(()=>true).map(x=>x.id)]);
return {pageId:page.id,createdNodeIds:ids,screens:Object.fromEntries(Object.entries(screens).map(([k,v])=>[k,v.id])),overlays:Object.fromEntries(Object.entries(overlays).map(([k,v])=>[k,v.id])),links:links.map(l=>({nodeId:l.node.id,label:l.node.name,target:l.target,timeout:l.timeout||null})),flowBoardId:board.id,dialogComponents:dialogComponents.map(n=>n.id)};

}
async function ensureFlowBoard(page, roots){
  const existing=roots.find(n=>n.name==='02 · User flow & demonstration');
  if(existing)return existing;
  const header=roots.find(n=>n.name==='00 · Design system / foundations');
  if(!header)throw new Error('Design system board missing; recovery stopped to preserve existing work.');
  const texts=roots.flatMap(n=>n.findAllWithCriteria?n.findAllWithCriteria({types:['TEXT']}):[]);
  const sizes={Display:32,Heading:28,Subheading:20,Body:14,Button:15,Caption:12};
  const colorSamples={};
  for(const name of ['text','primary','muted']){
    const phrase=name==='text'?'QalaPulse / A city shaped by its people':name==='primary'?'LAB 05':'Heading 28/34';
    const sample=texts.find(t=>t.characters.startsWith(phrase));
    if(!sample)throw new Error('Missing '+name+' style sample for recovery.');
    colorSamples[name]=sample.fills;
  }
  await Promise.all(['Regular','SemiBold','Bold'].map(style=>figma.loadFontAsync({family:'Noto Sans',style})));
  function frame(parent,name,width,height,layout,fill,gap,padding){
    const f=figma.createFrame();f.name=name;parent.appendChild(f);f.resize(width,height);
    f.layoutMode=layout;f.primaryAxisSizingMode='FIXED';f.counterAxisSizingMode='FIXED';f.itemSpacing=gap;
    f.paddingTop=padding;f.paddingBottom=padding;f.paddingLeft=padding;f.paddingRight=padding;f.fills=header.fills;return f;
  }
  async function txt(parent,value,style,color,width){
    const sample=texts.find(t=>t.fontSize===sizes[style]&&t.fontName.family==='Noto Sans');
    if(!sample)throw new Error('Missing '+style+' typography for recovery.');
    const t=figma.createText();parent.appendChild(t);
    if(typeof sample.textStyleId==='string'&&sample.textStyleId)await t.setTextStyleIdAsync(sample.textStyleId);
    else{t.fontName=sample.fontName;t.fontSize=sample.fontSize;t.lineHeight=sample.lineHeight;}
    t.characters=value;t.resize(width,Math.max(1,t.height));t.textAutoResize='HEIGHT';t.fills=colorSamples[color];return t;
  }
const board=frame(page,'02 · User flow & demonstration',2750,650,'VERTICAL','surface',24,32,true);board.x=header.x+3020;board.y=header.y;
await txt(board,'From a photo to a visible report.','Display','text',2600);
await txt(board,'Home → Add photo → Choose source → Photo added → Location → Description → AI suggestion → Human review → Similar issues → Confirm publication → Success → Report details','Subheading','primary',2550);
await txt(board,'Alternative A: Similar issues → Confirm existing → 4 confirmations.\nAlternative B: Publish → Preview network error → Keep as draft → Resume → Retry.\nAlternative C: Map → Filters → Road damage → Apply → Filtered results.','Body','text',2500);
await txt(board,'Interaction rules','Subheading','text',2500);await txt(board,'Dissolve 180ms for navigation and overlays. Smart Animate 200ms for the review checkbox. Analysis moves forward after 1.4s. Cancel closes the current overlay. Active navigation tabs never navigate to themselves.','Body','muted',2500);
await txt(board,'2-minute presentation','Subheading','text',2500);await txt(board,'1. Introduce the green palette and Noto Sans.\n2. Start the “Report a city issue” flow.\n3. Add the demo photo, confirm the point and description.\n4. Show that Continue is disabled until the AI suggestion is reviewed.\n5. Show the duplicate choice, then create a new report.\n6. Confirm publication and open the report. Explain that published means visible in QalaPulse.','Body','text',2500);
await txt(board,'User testing: run the scenario with 3 classmates. Record task completion, time, wrong taps and comments. Do not treat an automated graph check as human testing.','Caption','muted',2500);
  return board;
}

const BUILD_VERSION='STARTER FIX v2.1';
let buildStage='Starting';
function errorText(error){return error&&typeof error.message==='string'?error.message:typeof error==='string'?error:JSON.stringify(error)||String(error);}
function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function reportError(error){figma.showUI('<main style="font:14px system-ui;padding:20px"><h2>Build could not finish</h2><p>Build: STARTER FIX v2.1 · current page only</p><p>Stage: '+escapeHtml(buildStage)+'</p><pre style="white-space:pre-wrap">'+escapeHtml(errorText(error))+'</pre><p>Existing work has been preserved. Keep this error visible for diagnosis.</p></main>',{width:540,height:360});}
async function verifyPage(page,rootIds,skipFlowCheck=false){
  const roots=rootIds?page.children.filter(n=>rootIds.includes(n.id)):page.children;
  const owned=roots.flatMap(n=>[n,...n.findAll(()=>true)]);
  await Promise.all(['Regular','SemiBold','Bold'].map(style=>figma.loadFontAsync({family:'Noto Sans',style})));
  const frames=roots.filter(n=>n.type==='FRAME'&&n.width===390&&n.height===844);
  const overlayFrames=frames.filter(n=>n.name.startsWith('Overlay / '));
  const screenFrames=frames.filter(n=>!n.name.startsWith('Overlay / '));
  const ids=new Set(frames.map(n=>n.id));const links=[];const errors=[];
  for(const owner of frames)for(const node of [owner,...owner.findAll(()=>true)])for(const reaction of node.reactions||[])for(const action of reaction.actions||[]){
    if(action.type==='NODE'){
      if(!ids.has(action.destinationId))errors.push('Invalid destination: '+node.name);
      if(action.destinationId===owner.id)errors.push('Self-navigation: '+node.name);
      links.push({from:owner.id,to:action.destinationId,navigation:action.navigation,node:node.name});
    }
  }
  const byName=Object.fromEntries(screenFrames.map(n=>[n.name.split(' · ')[0],n]));
  const reachable=new Set([byName.home?.id]);let changed=true;while(changed){changed=false;for(const l of links)if(reachable.has(l.from)&&!reachable.has(l.to)){reachable.add(l.to);changed=true;}}
  if(!reachable.has(byName.success?.id))errors.push('Success is not reachable from Home');
  if(!reachable.has(byName.confirmed?.id))errors.push('Confirmation is not reachable from Home');
  if(!reachable.has(byName.draft?.id))errors.push('Draft is not reachable from Home');
  const review=byName.review;const disabled=review&&review.findOne(n=>n.name==='Find similar issues');
  if(!disabled||disabled.reactions?.length)errors.push('Human review gate is not disabled');
  for(const m of overlayFrames)if(!m.findOne(n=>n.name==='Cancel'&&(n.reactions||[]).some(r=>(r.actions||[]).some(a=>a.type==='CLOSE'))))errors.push('Missing working Cancel: '+m.name);
  const texts=owned.filter(n=>n.type==='TEXT');if(texts.some(t=>t.fontName===figma.mixed||t.fontName.family!=='Noto Sans'))errors.push('Inconsistent font family');
  if(screenFrames.length<8)errors.push('Fewer than eight screens');
  if(!skipFlowCheck&&(page.flowStartingPoints||[]).filter(p=>ids.has(p.nodeId)).length!==3)errors.push('Missing flow start points');
  if(errors.length)throw new Error(errors.join('\n'));
  return {screens:screenFrames.length,overlays:overlayFrames.length,links:links.length,components:owned.filter(n=>n.type==='COMPONENT').length,instances:owned.filter(n=>n.type==='INSTANCE').length,reachableStates:reachable.size,errors};
}
function setLabFlowStarts(page,roots){
  const ownedIds=new Set(roots.map(n=>n.id));
  const byName=Object.fromEntries(roots.map(n=>[n.name.split(' · ')[0],n]));
  const desired=[['home','01 · Report a city issue'],['map','02 · Discover and confirm'],['login','03 · Sign in']].map(([key,name])=>{
    if(!byName[key])throw new Error('Missing prototype start screen: '+key);
    return {nodeId:byName[key].id,name};
  });
  // Figma can create flow starts when connections are added. Replace only our starts.
  const merged=new Map((page.flowStartingPoints||[]).filter(p=>!ownedIds.has(p.nodeId)).map(p=>[p.nodeId,p]));
  for(const point of desired)merged.set(point.nodeId,point);
  page.flowStartingPoints=Array.from(merged.values());
}
const LAB_KEY='qalapulse-lab56-build-v2';
async function runLab(){
  const savedPage=figma.root.children.find(p=>p.getPluginData(LAB_KEY));
  const legacy=figma.root.children.find(p=>p.name==='Lab 5–6 · QalaPulse UI & Prototype');
  const previous=savedPage||legacy;
  if(previous){
    await figma.setCurrentPageAsync(previous);
    const saved=previous.getPluginData(LAB_KEY);
    const ledger=saved?JSON.parse(saved):null;
    if(ledger&&!ledger.complete){
      buildStage='Recovering prototype flow starts';
      const roots=previous.children.filter(n=>ledger.rootIds.includes(n.id));
      const result=await verifyPage(previous,ledger.rootIds,true);
      if(result.screens!==20||result.overlays!==20||!roots.some(n=>n.name==='Dialog & menu masters'))throw new Error('This partial build stopped before all screens and dialogs were ready. Recovery preserved the existing work.');
      const board=await ensureFlowBoard(previous,roots);
      if(!ledger.rootIds.includes(board.id))ledger.rootIds.push(board.id);
      previous.setPluginData(LAB_KEY,JSON.stringify(ledger));
      setLabFlowStarts(previous,previous.children.filter(n=>ledger.rootIds.includes(n.id)));
      await verifyPage(previous,ledger.rootIds);
      ledger.complete=true;previous.setPluginData(LAB_KEY,JSON.stringify(ledger));
    }
    buildStage='Verifying existing design';
    const result=await verifyPage(previous,ledger?.rootIds);
    figma.viewport.scrollAndZoomIntoView(previous.children.filter(n=>n.name.startsWith('home · ')&&(!ledger||ledger.rootIds.includes(n.id))));
    figma.closePlugin('Existing design verified: '+result.screens+' screens, '+result.overlays+' overlays, '+result.links+' transitions.');return;
  }
  if(figma.command==='verify')throw new Error('Create the Lab 5–6 design first.');
  const page=figma.currentPage;
  const before=new Set(page.children.map(n=>n.id));
  // Keep prototype frames at page level. A new page would exceed Starter's page limit.
  const right=page.children.reduce((max,n)=>Math.max(max,n.x+n.width),0);
  const offset=page.children.length?right+800:0;
  let complete=false;
  try{
    buildStage='Color palette, typography and component library';const foundation=await buildFoundations();
    buildStage='Screens, dialogs and prototype connections';await buildScreens(foundation);
    buildStage='Prototype checks';
    const rootIds=page.children.filter(n=>!before.has(n.id)).map(n=>n.id);
    const verified=await verifyPage(page,rootIds);
    console.log('QalaPulse Lab 5–6 verification',verified);complete=true;
  }finally{
    const added=page.children.filter(n=>!before.has(n.id));
    for(const node of added)node.x+=offset;
    if(added.length)page.setPluginData(LAB_KEY,JSON.stringify({rootIds:added.map(n=>n.id),complete}));
  }
  const ledger=JSON.parse(page.getPluginData(LAB_KEY));
  const verified=await verifyPage(page,ledger.rootIds);
  figma.viewport.scrollAndZoomIntoView(page.children.filter(n=>ledger.rootIds.includes(n.id)&&n.name.startsWith('home · ')));
  figma.closePlugin(BUILD_VERSION+' — Created '+verified.screens+' screens, '+verified.overlays+' overlays and '+verified.links+' transitions on the current page. Open Present → Report a city issue.');
}
runLab().catch(reportError);
