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
