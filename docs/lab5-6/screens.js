// Requires page, styles, components and tokens restored from the foundation ledger.
const screens={},overlays={},links=[];
// COMMON
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
