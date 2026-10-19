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
