// Contract tests against a small Plugin API double; not a replacement for Figma visual QA.
const fs=require('node:fs');const path=require('node:path');const vm=require('node:vm');const assert=require('node:assert/strict');
let legacyFailure=process.env.LAB56_LEGACY_FLOW_FAILURE==='1';
let serial=0;const nodes=new Map(),styles=new Map(),variables=new Map(),collections=[];
class Node{
 constructor(type){this.id='test:'+ ++serial;this.type=type;this.name='';this.children=[];this.reactions=[];this.fills=[];this.strokes=[];this.x=0;this.y=0;this.width=100;this.height=100;nodes.set(this.id,this);}
 get flowStartingPoints(){return this._flowStartingPoints||[];}
 set flowStartingPoints(value){assert.equal(new Set(value.map(p=>p.nodeId)).size,value.length,'Found duplicate input nodeIds');this._flowStartingPoints=value;}
 getPluginData(key){return this.pluginData?.[key]||'';}
 setPluginData(key,value){this.pluginData={...this.pluginData,[key]:value};}
 appendChild(n){if(n.parent)n.parent.children=n.parent.children.filter(x=>x!==n);this.children.push(n);n.parent=this;}
 resize(w,h){assert(w>0&&h>0);this.width=w;this.height=h;}
 rescale(r){this.width*=r;this.height*=r;for(const c of this.children){c.x*=r;c.y*=r;c.rescale(r);}}
 setBoundVariable(key,value){assert(value,'missing variable '+key);this.boundVariables={...this.boundVariables,[key]:{type:'VARIABLE_ALIAS',id:value.id}};this[key]=resolve(value.values[value.mode]);}
 findAll(pred){return this.children.flatMap(n=>[...(pred(n)?[n]:[]),...n.findAll(pred)]);}
 findOne(pred){return this.findAll(pred)[0]||null;}
 findAllWithCriteria({types}){return this.findAll(n=>types.includes(n.type));}
 async setTextStyleIdAsync(id){const s=styles.get(id);assert(s);this.textStyleId=id;Object.assign(this,{fontName:s.fontName,fontSize:s.fontSize,lineHeight:s.lineHeight});}
 getStyledTextSegments(){return[{fontName:this.fontName}];}
 addComponentProperty(name,type,defaultValue){return name;}
 clone(){const n=new Node(this.type);for(const key of Object.keys(this))if(!['id','parent','children'].includes(key))n[key]=structuredClone(this[key]);for(const c of this.children)n.appendChild(c.clone());return n;}
 createInstance(){const n=this.clone();n.type='INSTANCE';n.masterId=this.id;return n;}
 async setReactionsAsync(reactions){if(process.env.LAB56_FORCE_ERROR==='1')throw 'Simulated native string error';for(const r of reactions)for(const a of r.actions||[])if(a.destinationId)assert(nodes.has(a.destinationId),'destination must exist');this.reactions=reactions;
  let owner=this;while(owner.parent&&owner.parent.type!=='PAGE')owner=owner.parent;
  if(owner.parent?.type==='PAGE'&&owner.width===390&&reactions.length&&!owner.parent.flowStartingPoints.some(p=>p.nodeId===owner.id))owner.parent.flowStartingPoints=[...owner.parent.flowStartingPoints,{nodeId:owner.id,name:'Auto '+owner.name}];
 }
}
function resolve(v){return v&&v.type==='VARIABLE_ALIAS'?resolve(variables.get(v.id).values[variables.get(v.id).mode]):v;}
const root=new Node('DOCUMENT');const existing=new Node('PAGE');existing.name='User work';root.appendChild(existing);const existingText=new Node('TEXT');existingText.characters='Keep this untouched';existing.appendChild(existingText);
const existingFrame=new Node('FRAME');existingFrame.name='Existing user screen';existingFrame.x=12000;existingFrame.y=700;existingFrame.resize(500,600);existing.appendChild(existingFrame);
existing.flowStartingPoints=[{nodeId:existingFrame.id,name:'Existing user flow'}];
for(let i=0;i<2;i++){const p=new Node('PAGE');p.name='Existing page '+i;root.appendChild(p);}
const originalPageCount=root.children.length;
let completed;const finished=new Promise((resolve,reject)=>completed={resolve,reject});
const figma={root,currentPage:existing,command:'build',mixed:Symbol('mixed'),viewport:{scrollAndZoomIntoView(){}},
 loadFontAsync:async f=>assert.equal(f.family,'Noto Sans'),setCurrentPageAsync:async p=>figma.currentPage=p,
 getNodeByIdAsync:async id=>nodes.get(id),getStyleByIdAsync:async id=>styles.get(id),
 createTextStyle:()=>{const s={id:'style:'+ ++serial};styles.set(s.id,s);return s;},
 createNodeFromSvg:svg=>{const n=new Node('FRAME');n.svg=svg;const v=new Node('VECTOR');v.strokes=[{type:'SOLID',color:{r:0,g:0,b:0}}];n.appendChild(v);const dims=svg.match(/width="([\d.]+)" height="([\d.]+)"/);if(dims)n.resize(+dims[1],+dims[2]);figma.currentPage.appendChild(n);return n;},
 combineAsVariants:(items,parent)=>{const set=new Node('COMPONENT_SET');parent.appendChild(set);items.forEach(x=>set.appendChild(x));return set;},
 createComponentFromNode:node=>{node.type='COMPONENT';return node;},
 variables:{
  createVariableCollection:name=>{const c={name,id:'collection:'+ ++serial,defaultModeId:'mode:'+serial};collections.push(c);return c;},
  createVariable:(name,c,type)=>{const v={id:'variable:'+ ++serial,name,type,mode:c.defaultModeId,values:{},collection:c.id,setValueForMode(mode,value){this.values[mode]=value;},setVariableCodeSyntax(platform,value){this.codeSyntax={...this.codeSyntax,[platform]:value};}};variables.set(v.id,v);return v;},
  setBoundVariableForPaint:(p,field,v)=>{assert(v);return {...p,[field]:resolve(v.values[v.mode]),boundVariables:{[field]:{type:'VARIABLE_ALIAS',id:v.id}}};},
  getVariableByIdAsync:async id=>variables.get(id)
 },
 closePlugin:message=>completed.resolve(message),
 showUI:html=>{if(legacyFailure){assert(html.includes('Found duplicate input nodeIds'));completed.resolve('legacy duplicate reproduced');return;}if(process.env.LAB56_FORCE_ERROR==='1'){assert(html.includes('Simulated native string error'));assert(html.includes('STARTER FIX v2'));assert(!html.includes('undefined'));completed.resolve('error preserved');}else completed.reject(new Error(html));}
};
for(const [method,type]of Object.entries({createPage:'PAGE',createFrame:'FRAME',createText:'TEXT',createComponent:'COMPONENT',createRectangle:'RECTANGLE'}))figma[method]=()=>{if(type==='PAGE')throw new Error('Starter plan only comes with 3 pages');const n=new Node(type);figma.currentPage.appendChild(n);return n;};
const context=vm.createContext({figma,console,Promise,Error,Set,Map,Uint8Array});
let code=fs.readFileSync(path.join(__dirname,'figma-plugin/code.js'),'utf8').replace(/\r\n/g,'\n');
if(legacyFailure)code=code.replace("const board=await ensureFlowBoard(page,ownedRoots);\nsetLabFlowStarts(page,[...Object.values(screens),...Object.values(overlays),dialogMasters,dialogReview,board]);", "page.flowStartingPoints=[...page.flowStartingPoints,{nodeId:screens.home.id,name:'Legacy duplicate'}];\nconst board=await ensureFlowBoard(page,ownedRoots);");
vm.runInContext(code,context);
function click(frame,label){const n=frame.findOne(n=>n.name===label&&n.reactions.length);assert(n,'Missing interactive '+label+' in '+frame.name);return n.reactions[0].actions[0];}
function destination(frame,label){const action=click(frame,label);assert(action.destinationId);return nodes.get(action.destinationId);}
async function main(){
 let message=await finished;assert.equal(existingText.characters,'Keep this untouched');
 if(process.env.LAB56_FORCE_ERROR==='1'){console.log('PASS: meaningful persistent error, pre-existing user work preserved');return;}
 if(legacyFailure){
   const partial=JSON.parse(existing.getPluginData('qalapulse-lab56-build-v2'));assert.equal(partial.complete,false);
   const originalNodes=new Map(partial.rootIds.map(id=>{const n=nodes.get(id);return [id,{x:n.x,y:n.y}];}));
   assert(!existing.children.some(n=>n.name==='02 · User flow & demonstration'));
   const home=existing.children.find(n=>n.name.startsWith('home · '));const note=home.findOne(n=>n.type==='TEXT'&&n.characters==='Good morning, Madi');note.characters='My preserved edit';
   legacyFailure=false;completed={resolve(value){message=value;},reject(e){throw e;}};
   await vm.runInContext('runLab()',context);
   assert(JSON.parse(existing.getPluginData('qalapulse-lab56-build-v2')).complete);
   for(const [id,pos]of originalNodes){assert.equal(nodes.get(id).x,pos.x);assert.equal(nodes.get(id).y,pos.y);}
   assert.equal(note.characters,'My preserved edit');assert.equal(existing.children.filter(n=>n.name==='02 · User flow & demonstration').length,1);
   fs.writeFileSync(path.join(__dirname,'recovery-verification.json'),JSON.stringify({nativeFigmaExecuted:false,legacyFailureReproduced:true,sameScreenIdsPreserved:true,userEditPreserved:true,missingFlowBoardCreatedOnce:true},null,2));
   console.log('PASS: reproduced v2 duplicate-start failure, recovered same screens and user edit, created only missing flow board');
 }
 assert.equal(root.children.length,originalPageCount,'Do not create pages on Starter');assert.equal(existingFrame.x,12000);assert.equal(existingFrame.y,700);assert.equal(existing.flowStartingPoints[0].name,'Existing user flow');
 const page=existing;const ledger=JSON.parse(page.getPluginData('qalapulse-lab56-build-v2'));assert(ledger.complete);for(const id of ledger.rootIds)assert(nodes.get(id).x>=13300,'New content must sit to the right of existing work');const frame=id=>page.children.find(n=>n.name.startsWith(id+' · '));
 let current=frame('home');for(const label of ['Report an issue','Choose photo','Choose from gallery','Continue','Confirm location','Analyse issue'])current=destination(current,label);
 assert.equal(current,frame('analyze'));current=nodes.get(current.reactions[0].actions[0].destinationId);assert.equal(current,frame('review'));
 assert.equal(current.findOne(n=>n.name==='Find similar issues').reactions.length,0);
 for(const label of ['Review confirmation','Find similar issues','Create a new report','Publish report','View my report'])current=destination(current,label);
 assert.equal(current,frame('created'));
 const dup=frame('duplicates');const confirm=destination(destination(dup,'Confirm existing issue'),'Yes, it still exists');assert.equal(confirm,frame('confirmed'));assert(confirm.findOne(n=>n.type==='TEXT'&&n.characters.includes('4 residents')));
 const publish=destination(dup,'Create a new report'),offline=destination(publish,'Preview network error');assert.equal(destination(offline,'Keep as draft'),frame('draft'));assert.equal(destination(offline,'Retry publication'),frame('success'));assert.equal(destination(frame('draft'),'Resume draft'),frame('describe'));
 assert.equal(click(publish,'Cancel').type,'CLOSE');assert.equal(destination(destination(destination(frame('map'),'Categories & filters'),'Road damage'),'Apply filters'),frame('filtered'));
 const before=nodes.size;completed={resolve(){},reject(e){throw e;}};await vm.runInContext('runLab()',context);assert.equal(nodes.size,before,'Repeat build must not duplicate nodes');
 const result={nativeFigmaExecuted:false,note:'Contract tests only. Figma rendering and actual prototype playback require native import.',screens:page.children.filter(n=>n.width===390&&n.height===844&&!n.name.startsWith('Overlay')).length,overlays:page.children.filter(n=>n.name.startsWith('Overlay')).length,checks:['complete publication path','human review gate','duplicate confirmation','offline save and retry','filter selection','overlay cancellation','repeat build preserves node count','pre-existing work preserved','Starter three-page limit: no page creation','existing flow start preserved','new content placed outside existing bounds','automatic Figma flow starts deduplicated'],message};
 fs.writeFileSync(path.join(__dirname,'verification.json'),JSON.stringify(result,null,2));
 exportPreview(page);console.log(JSON.stringify(result,null,2));
}
function exportPreview(page){
 const escape=s=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const color=p=>p?.color?'rgba('+['r','g','b'].map(k=>Math.round(p.color[k]*255)).join(',')+','+(p.opacity??1)+')':'transparent';
 const html=n=>{
  const vertical=n.layoutMode==='VERTICAL',horizontal=n.layoutMode==='HORIZONTAL';const autoHeight=vertical?n.primaryAxisSizingMode==='AUTO':horizontal?n.counterAxisSizingMode==='AUTO':false;
  const style=['box-sizing:border-box','position:relative','flex-shrink:0','width:'+n.width+'px','height:'+(autoHeight||n.textAutoResize==='HEIGHT'?'auto':n.height+'px'),'background:'+color(n.fills[0]),'border-radius:'+(n.cornerRadius||0)+'px','overflow:'+(n.clipsContent?'hidden':'visible')];
  if(n.parent&&n.parent.layoutMode!=='VERTICAL'&&n.parent.layoutMode!=='HORIZONTAL')style.push('position:absolute','left:'+n.x+'px','top:'+n.y+'px');
  if(n.strokes.length)style.push('outline:'+(n.strokeWeight||1)+'px solid '+color(n.strokes[0]));
  if(vertical||horizontal)style.push('display:flex','flex-direction:'+(vertical?'column':'row'),'gap:'+(n.itemSpacing||0)+'px','padding:'+[n.paddingTop||0,n.paddingRight||0,n.paddingBottom||0,n.paddingLeft||0].map(x=>x+'px').join(' '),'align-items:'+(n.counterAxisAlignItems==='CENTER'?'center':'flex-start'),'justify-content:'+(n.primaryAxisAlignItems==='CENTER'?'center':'flex-start'));
  if(n.type==='TEXT')style.push('background:transparent','color:'+color(n.fills[0]),'font-family:Noto Sans','font-size:'+n.fontSize+'px','line-height:'+(n.lineHeight?.value||21)+'px','font-weight:'+(n.fontName?.style==='Bold'?700:n.fontName?.style==='SemiBold'?600:400),'white-space:pre-wrap','overflow-wrap:break-word','text-align:'+(n.textAlignHorizontal==='CENTER'?'center':'left'));
  const action=n.reactions?.[0]?.actions?.[0];let attr='';if(action){attr=' data-action="'+escape(JSON.stringify(action))+'"';style.push('cursor:pointer');}if(n.reactions?.[0]?.trigger?.type==='AFTER_TIMEOUT')attr+=' data-timeout="1400"';
  let body=n.type==='TEXT'?escape(n.characters):n.svg?n.svg.replace(/width="[\d.]+" height="[\d.]+"/,'width="100%" height="100%"'):n.children.map(html).join('');
  if(n.svg&&n.name.startsWith('Icon/'))body=body.replace(/stroke="#[0-9a-fA-F]+"/, 'stroke="'+color(n.children[0]?.strokes[0])+'"');
  return '<div data-id="'+n.id+'" data-name="'+escape(n.name)+'"'+attr+' style="'+style.join(';')+'">'+body+'</div>';
 };
 const roots=page.children.filter(n=>(n.width===390&&n.height===844)||/^(00|01|02|03) ·/.test(n.name));
 const start=roots.find(n=>n.name.startsWith('home ·'));
 const data=roots.map(n=>({id:n.id,name:n.name,w:n.width,h:n.height,html:html(n)}));
 const script=`const frames=${JSON.stringify(data).replace(/</g,'\\u003c')};let base='${start.id}',overlay=null,timer;const stage=document.getElementById('stage'),select=document.getElementById('screen');for(const f of frames){const o=document.createElement('option');o.value=f.id;o.textContent=f.name;select.append(o);}function show(id){base=id;overlay=null;render();}function render(){clearTimeout(timer);let f=frames.find(f=>f.id===base);stage.style.width=f.w+'px';stage.style.height=f.h+'px';stage.innerHTML=f.html+(overlay?frames.find(f=>f.id===overlay).html:'');select.value=base;const timeout=stage.querySelector('[data-timeout]');if(timeout&&!overlay)timer=setTimeout(()=>act(JSON.parse(timeout.dataset.action)),1400);}function act(a){if(a.type==='CLOSE')overlay=null;else if(a.navigation==='OVERLAY'||a.navigation==='SWAP')overlay=a.destinationId;else{base=a.destinationId;overlay=null;}render();}stage.addEventListener('click',e=>{const n=e.target.closest('[data-action]');if(n&&!n.dataset.timeout)act(JSON.parse(n.dataset.action));});select.onchange=()=>show(select.value);document.getElementById('restart').onclick=()=>show('${start.id}');render();`;
 const font=fs.readFileSync(path.join(__dirname,'../lab4/assets/NotoSans.ttf')).toString('base64');
 const document='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>QalaPulse · Lab 5–6 Preview</title><style>@font-face{font-family:"Noto Sans";src:url(data:font/ttf;base64,'+font+')}body{margin:0;background:#e8ebe5;color:#202d29;font:14px "Noto Sans",sans-serif}header{position:sticky;top:0;background:white;padding:16px;display:flex;gap:16px;align-items:center;z-index:100}select,button{font:inherit;padding:8px;border:1px solid #dfe3db;border-radius:8px;background:white}main{padding:24px;overflow:auto}#stage{position:relative;margin:auto;background:#f6f5f0;box-shadow:0 12px 40px #202d2920}#stage>div{position:absolute!important;left:0!important;top:0!important}aside{max-width:740px;margin:24px auto;padding:0 24px;color:#5e6b64}</style><header><strong>QalaPulse / Labs 5–6</strong><select id="screen" aria-label="Screen"></select><button id="restart">Restart</button></header><main><div id="stage"></div></main><aside>Local preview from the Figma source. This checks content and flows; it is not a screenshot or proof of execution in Figma. Camera, location, AI and publication use demonstration data.</aside><script>'+script+'</script></html>';
 fs.writeFileSync(path.join(__dirname,'preview.html'),document);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
