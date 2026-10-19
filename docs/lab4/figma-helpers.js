
const D={"createdNodeIds":["2:17","2:18","2:19","2:20","2:21","2:22","2:23","2:24","2:25","2:26","2:27","2:28","2:29","2:30","2:31","2:32","2:33","2:34","2:35","2:36","2:37","2:38","2:39","2:40","2:41","2:42","2:43","2:44","2:45","2:46","2:47","2:48","2:49","2:50","2:51","2:52","2:53","2:54","2:55","2:56"],"page":"0:1","board":"2:56","screens":{"1":"2:36","2":"2:37","3":"2:38","4":"2:39","5":"2:40","6":"2:41","7":"2:42","8":"2:43","9":"2:44","10":"2:45","11":"2:46","12":"2:47","13":"2:48","14":"2:49","15":"2:50"},"modals":{"1":"2:51","2":"2:52","3":"2:53","4":"2:54","5":"2:55"},"components":{"Default":{"id":"2:17","label":"Label#2:0"},"Hover":{"id":"2:19","label":"Label#2:1"},"Pressed":{"id":"2:21","label":"Label#2:2"},"Disabled":{"id":"2:23","label":"Label#2:3"},"Loading":{"id":"2:25","label":"Label#2:4"},"Secondary":{"id":"2:27","label":"Label#2:5"},"FieldLabel":"Label#2:6","FieldValue":"Value#2:7","Field":{"id":"2:29"},"CardStatus":"Status#2:8","CardTitle":"Title#2:9","CardMeta":"Meta#2:10","Card":{"id":"2:32"}},"styles":{"Body":"S:ef4f2533053712a430e7035af1c9e01fc5b813d0,","Label":"S:e494c90192e8b24bf4fc74919be686402fdb29fe,","Caption":"S:6e585a89451c93174909a7faae836b32fdde17c4,","Title":"S:8c39be44e767745849b675c4d3d5421825203099,","Board":"S:7a15daead6a677a5ea0c045418c6e6c6ab2cdce8,"},"variables":{"paper":"VariableID:2:3","soft":"VariableID:2:4","ink":"VariableID:2:5","muted":"VariableID:2:6","line":"VariableID:2:7","disabled":"VariableID:2:8","gap":"VariableID:2:9","padding":"VariableID:2:10","radius":"VariableID:2:11"},"collection":"VariableCollectionId:2:2","mode":"2:0"};
await Promise.all(["Regular","Bold"].map(style=>figma.loadFontAsync({family:"Noto Sans",style})));
const ids=[];const track=n=>(ids.push(n.id),n);
const vars=Object.fromEntries(await Promise.all(Object.entries(D.variables).map(async([k,id])=>[k,await figma.variables.getVariableByIdAsync(id)])));
const paint=name=>figma.variables.setBoundVariableForPaint({type:"SOLID",color:{r:0,g:0,b:0}},"color",vars[name]);
const components=Object.fromEntries(await Promise.all(Object.entries(D.components).filter(([k,v])=>v.id).map(async([k,v])=>[k,await figma.getNodeByIdAsync(v.id)])));
const routes=[];
async function txt(p,value,w=358,style="Body",color="ink"){
 const t=track(figma.createText());t.fontName={family:"Noto Sans",style:["Label","Title","Board"].includes(style)?"Bold":"Regular"};t.characters=value;t.resize(w,20);t.textAutoResize="HEIGHT";await t.setTextStyleIdAsync(D.styles[style]);t.fills=[paint(color)];p.appendChild(t);return t;
}
function stack(p,w=358,gap=12){const f=track(figma.createAutoLayout("VERTICAL"));f.resize(w,10);f.layoutSizingHorizontal="FIXED";f.primaryAxisSizingMode="AUTO";f.itemSpacing=gap;f.fills=[];p.appendChild(f);return f;}
async function link(node,target,kind="NAVIGATE",trigger={type:"ON_CLICK"}){
 const dest=target==="CLOSE"?null:(target.startsWith("M")?D.modals[target.slice(1)]:D.screens[target]);
 await node.setReactionsAsync([{trigger,actions:target==="CLOSE"?[{type:"CLOSE"}]:[{type:"NODE",destinationId:dest,navigation:kind,transition:null,resetScrollPosition:true}]}]);
 routes.push({node:node.id,label:node.name,to:target,type:kind});
}
async function btn(p,label,to=null,state="Default",w=358){
 const n=track(components[state].createInstance());p.appendChild(n);n.setProperties({[D.components[state].label]:label});n.resize(w,48);n.name=label;
 if(to)await link(n,to,to.startsWith("M")?"OVERLAY":"NAVIGATE");return n;
}
async function field(p,label,value){const n=track(components.Field.createInstance());p.appendChild(n);n.setProperties({[D.components.FieldLabel]:label,[D.components.FieldValue]:value});n.resize(358,n.height);n.name=label;return n;}
async function card(p,title,meta,to="3",status="Опубликовано в QalaPulse"){const n=track(components.Card.createInstance());p.appendChild(n);n.setProperties({[D.components.CardTitle]:title,[D.components.CardMeta]:meta,[D.components.CardStatus]:status});n.resize(358,n.height);n.name=title;if(to)await link(n,to);return n;}
async function note(p,value){const box=stack(p,358,0);box.fills=[paint("soft")];box.paddingTop=10;box.paddingBottom=10;box.paddingLeft=12;box.paddingRight=12;await txt(box,value,334,"Caption","muted");return box;}
async function placeholder(p,label,h=160){const f=stack(p,358,0);f.resize(358,h);f.layoutSizingVertical="FIXED";f.primaryAxisAlignItems="CENTER";f.counterAxisAlignItems="CENTER";f.fills=[paint("soft")];f.strokes=[paint("line")];const t=await txt(f,label,320,"Body","muted");t.textAlignHorizontal="CENTER";return f;}
async function phone(id,title,back=null,nav=true){
 const root=await figma.getNodeByIdAsync(D.screens[id]);if(root.children.length)throw new Error("Already populated "+id);
 await txt(root,"09:41                                       QalaPulse",358,"Caption","muted");
 const head=stack(root);head.layoutMode="HORIZONTAL";head.counterAxisAlignItems="CENTER";
 if(back){const b=await btn(head,"‹",back,"Secondary",40);b.resize(40,40);const t=b.findAllWithCriteria({types:["TEXT"]})[0];t.resize(20,20);}
 await txt(head,title,back?306:358,"Title");
 const body=stack(root);body.layoutSizingVertical="FILL";body.clipsContent=false;
 if(nav){const bar=track(figma.createAutoLayout("HORIZONTAL"));root.appendChild(bar);bar.resize(358,52);bar.itemSpacing=4;bar.fills=[];
 for(const [label,to]of [["Главная","1"],["Карта","2"],["+","6"],["События","14"],["Профиль","15"]]){const b=await btn(bar,label,to,to===id?"Default":"Secondary",68);const t=b.findAllWithCriteria({types:["TEXT"]})[0];t.resize(62,18);await t.setTextStyleIdAsync(D.styles.Caption);}}
 return {root,body};
}
function evidence(keys){const out=[];return Promise.all(keys.map(async k=>{const n=await figma.getNodeByIdAsync(D.screens[k]);const nodes=n.findAll(()=>true);return {id:n.id,name:n.name,width:n.width,height:n.height,nodeCount:nodes.length,types:nodes.reduce((a,x)=>(a[x.type]=(a[x.type]||0)+1,a),{}),imageNodes:nodes.filter(x=>Array.isArray(x.fills)&&x.fills.some(f=>f.type==="IMAGE")).map(x=>({id:x.id,name:x.name,type:x.type,width:x.width,height:x.height})),overflow:nodes.filter(x=>x.parent&&x.parent.type==="FRAME"&&x.y+x.height>x.parent.height+1).map(x=>({id:x.id,name:x.name,y:x.y,height:x.height,parentHeight:x.parent.height}))};}));}
