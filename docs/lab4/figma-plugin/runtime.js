// SPEC is prepended by scripts/build_lab4.py. Standard Figma Plugin API only.
let buildStage='Подготовка';
function stage(name){buildStage=name;console.log('QalaPulse Lab4:',name);}
function errorText(error){
  if(typeof error==='string')return error;
  if(error&&typeof error.message==='string')return error.message;
  try{return JSON.stringify(error)||String(error);}catch{return String(error);}
}
function showBuildError(error){
  console.error(error);
  const escape=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const details='Этап: '+buildStage+'\n\n'+errorText(error)+'\n\n'+String(error&&error.stack||'');
  figma.showUI('<html><body style="font:14px system-ui;padding:20px"><h2>Генерация не завершена</h2><p>Страница сохранена. Скопируйте текст ошибки или сделайте снимок этого окна.</p><textarea readonly style="width:100%;height:230px;box-sizing:border-box">'+escape(details)+'</textarea><p>После исправления можно повторить запуск: предыдущая попытка сохранится.</p></body></html>',{width:560,height:420});
}
async function buildLab() {
  const pageName='Lab 4 · Final wireframes';
  const existing=figma.root.children.find(p=>p.name===pageName);
  if(existing){
    await figma.setCurrentPageAsync(existing);
    if(existing.getPluginData('lab4-complete')==='true'){
      figma.viewport.scrollAndZoomIntoView(existing.children);
      figma.closePlugin('Готовая страница открыта. Все макеты показаны в области просмотра.');return;
    }
    // Preserve incomplete builds and any edits instead of deleting them.
    existing.name=pageName+' · предыдущая попытка '+new Date().toISOString();
  }
  let fontFamily='Noto Sans';
  try{await Promise.all(['Regular','Bold'].map(style=>figma.loadFontAsync({family:fontFamily,style})));}
  catch{fontFamily='Inter';await Promise.all(['Regular','Bold'].map(style=>figma.loadFontAsync({family:fontFamily,style})));}
  const page=figma.createPage();page.name=pageName;await figma.setCurrentPageAsync(page);
  stage('Переменные и стили');
  const collection=figma.variables.createVariableCollection('Lab4 / Grayscale');
  const tokens={};
  for(const [name,n,scopes] of [['paper',1,['FRAME_FILL','SHAPE_FILL','TEXT_FILL']],['soft',.94,['FRAME_FILL','SHAPE_FILL']],['ink',.14,['FRAME_FILL','TEXT_FILL']],['muted',.42,['TEXT_FILL']],['line',.66,['STROKE_COLOR']],['disabled',.82,['FRAME_FILL']]]){
    const v=figma.variables.createVariable(name,collection,'COLOR');v.scopes=scopes;v.setValueForMode(collection.defaultModeId,{r:n,g:n,b:n});v.setVariableCodeSyntax('WEB','var(--lab-'+name+')');tokens[name]=v;
  }
  for(const [name,n,scopes]of [['gap',12,['GAP']],['padding',16,['GAP']],['radius',5,['CORNER_RADIUS']]]){const v=figma.variables.createVariable(name,collection,'FLOAT');v.scopes=scopes;v.setValueForMode(collection.defaultModeId,n);v.setVariableCodeSyntax('WEB','var(--lab-'+name+')');tokens[name]=v;}
  const paint=n=>figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0}},'color',tokens[n]);
  const styles={};
  for(const [name,size,bold]of [['Body',14,false],['Small',11,false],['Label',13,true],['Title',22,true],['Board',30,true]]){const st=figma.createTextStyle();st.name='Lab4/'+name;st.fontName={family:fontFamily,style:bold?'Bold':'Regular'};st.fontSize=size;st.lineHeight={unit:'PERCENT',value:140};styles[name]=st;}
  function box(parent,name,w=358,h=10,dir='VERTICAL',fixed=false){const f=figma.createFrame();f.name=name;f.layoutMode=dir;f.resize(w,h);f.primaryAxisSizingMode=fixed?'FIXED':'AUTO';f.counterAxisSizingMode='FIXED';f.setBoundVariable('itemSpacing',tokens.gap);f.fills=[];f.clipsContent=false;parent.appendChild(f);return f;}
  async function text(parent,str,w=358,style='Body',color='ink'){const n=figma.createText();n.name=str.slice(0,70);n.fontName=styles[style].fontName;n.characters=str;n.resize(w,20);n.textAutoResize='HEIGHT';await n.setTextStyleIdAsync(styles[style].id);n.fills=[paint(color)];parent.appendChild(n);return n;}
  stage('Компоненты');
  const assets=figma.createSection();assets.name='Компоненты · исходники';assets.x=2660;assets.y=100;assets.resizeWithoutConstraints(900,700);
  const buttons={},props={};const variants=[];
  for(const state of ['Default','Hover','Pressed','Disabled','Loading','Secondary']){
    const c=figma.createComponent();c.name='State='+state;c.resize(358,48);c.layoutMode='HORIZONTAL';c.primaryAxisAlignItems='CENTER';c.counterAxisAlignItems='CENTER';c.setBoundVariable('cornerRadius',tokens.radius);c.fills=[paint(['Disabled','Loading'].includes(state)?'disabled':state==='Secondary'?'paper':'ink')];c.strokes=[paint('line')];
    if(state==='Hover')c.opacity=.8;
    const label=await text(c,state==='Loading'?'Подождите…':'Продолжить',326,'Label',['Disabled','Loading','Secondary'].includes(state)?'ink':'paper');label.textAlignHorizontal='CENTER';buttons[state]=c;variants.push(c);
  }
  // Variant grid follows the createComponentWithVariants helper's layout pattern.
  const buttonSet=figma.combineAsVariants(variants,page);buttonSet.name='Lab4/Button';assets.appendChild(buttonSet);buttonSet.x=20;buttonSet.y=40;buttonSet.resize(760,230);buttonSet.description='Default, Hover, Pressed, Disabled, Loading, Secondary. Loading and disabled controls do not navigate.';
  const labelKey=buttonSet.addComponentProperty('Label','TEXT','Продолжить');
  variants.forEach((c,i)=>{c.x=(i%2)*380;c.y=Math.floor(i/2)*70;c.findAllWithCriteria({types:['TEXT']})[0].componentPropertyReferences={characters:labelKey};});
  const fieldComp=figma.createComponent();fieldComp.name='Lab4/Field';fieldComp.layoutMode='VERTICAL';fieldComp.resize(358,70);fieldComp.primaryAxisSizingMode='AUTO';fieldComp.itemSpacing=4;fieldComp.paddingTop=8;fieldComp.paddingBottom=8;fieldComp.paddingLeft=12;fieldComp.paddingRight=12;fieldComp.fills=[paint('paper')];fieldComp.strokes=[paint('line')];fieldComp.setBoundVariable('cornerRadius',tokens.radius);
  for(const [name,str,style,color]of [['Label','Название поля','Small','muted'],['Value','Введённое значение','Body','ink']]){const t=await text(fieldComp,str,334,style,color);const key=fieldComp.addComponentProperty(name,'TEXT',str);t.componentPropertyReferences={characters:key};props[name]=key;}
  assets.appendChild(fieldComp);fieldComp.x=20;fieldComp.y=330;fieldComp.description='Предзаполненное поле wireframe. Ввод проверяется в HTML-прототипе.';
  const cardComp=figma.createComponent();cardComp.name='Lab4/IncidentCard';cardComp.layoutMode='VERTICAL';cardComp.resize(358,98);cardComp.primaryAxisSizingMode='AUTO';cardComp.itemSpacing=6;cardComp.paddingTop=12;cardComp.paddingBottom=12;cardComp.paddingLeft=12;cardComp.paddingRight=12;cardComp.fills=[paint('paper')];cardComp.strokes=[paint('line')];cardComp.setBoundVariable('cornerRadius',tokens.radius);
  for(const [name,str,style,color]of [['Status','Опубликовано в QalaPulse','Small','muted'],['Title','Название обращения','Label','ink'],['Meta','120 м · 3 подтверждения','Small','muted']]){const t=await text(cardComp,str,334,style,color);const key=cardComp.addComponentProperty(name,'TEXT',str);t.componentPropertyReferences={characters:key};props['Card'+name]=key;}
  assets.appendChild(cardComp);cardComp.x=20;cardComp.y=470;
  const frames={},modalFrames={},links=[];
  for(const [i,s]of SPEC.screens.entries()){const f=box(page,s.id+' · '+s.title,390,844,'VERTICAL',true);f.x=80+(i%5)*470;f.y=1300+Math.floor(i/5)*940;f.fills=[paint('paper')];f.strokes=[paint('line')];f.paddingTop=16;f.paddingBottom=16;f.paddingLeft=16;f.paddingRight=16;f.clipsContent=true;frames[s.id]=f;}
  for(const [i,m]of SPEC.modals.entries()){const f=box(page,m.id+' · '+m.title,390,844,'VERTICAL',true);f.x=80+i*470;f.y=4200;f.paddingLeft=24;f.paddingRight=24;f.primaryAxisAlignItems='CENTER';f.fills=[{type:'SOLID',color:{r:0,g:0,b:0},opacity:.4}];modalFrames[m.id]=f;}
  function nav(id,overlay=false){return {type:'NODE',destinationId:(overlay?modalFrames[id]:frames[id]).id,navigation:overlay?'OVERLAY':'NAVIGATE',transition:null,resetScrollPosition:true};}
  async function actions(node,list,trigger={type:'ON_CLICK'}){
    // The active tab and demo controls need no navigation back to their own frame.
    const ancestors=new Set();for(let p=node;p&&p.type!=='PAGE';p=p.parent)ancestors.add(p.id);
    const filtered=list.filter(a=>!(a.type==='NODE'&&a.navigation==='NAVIGATE'&&ancestors.has(a.destinationId)));
    if(!filtered.length)return;
    try{await node.setReactionsAsync([{trigger,actions:filtered}]);}
    catch(error){throw new Error('Переход «'+node.name+'»: '+errorText(error));}
    links.push({node:node.id,name:node.name,actions:filtered});
  }
  const actionTargets={'photo-camera':'07','photo-gallery':'07',login:'06',register:'06','gps-map':'02',gps:'08','pick-location':'08','confirm-existing':'14','confirm-duplicate':'03',publish:'13',retry:'11',resolved:'03',partial:'03',unresolved:'03',comment:'14','refresh-events':'14','my-incidents':'01',logout:'04','review-next':'12','voice-record':'09','voice-play':'09','voice-reset':'09'};
  async function wire(n,a){if(!a)return;if(a.startsWith('go:'))await actions(n,[nav(a.slice(3))]);else if(a.startsWith('modal:'))await actions(n,[nav(a.slice(6),true)]);else if(['close','apply-filters','reset-filters'].includes(a))await actions(n,[{type:'CLOSE'}]);else if(actionTargets[a])await actions(n,[nav(actionTargets[a])]);}
  async function button(p,b,width=358){const state=b.loading?'Loading':b.disabled||b.gate?'Disabled':b.secondary?'Secondary':'Default';const n=buttons[state].createInstance();p.appendChild(n);n.setProperties({[labelKey]:b.text});n.resize(width,48);for(const t of n.findAllWithCriteria({types:['TEXT']}))t.resize(width-32,t.height);n.name=b.text;if(!b.disabled&&!b.gate&&!b.loading)await wire(n,b.action);return n;}
  async function field(p,b){const n=fieldComp.createInstance();p.appendChild(n);n.setProperties({[props.Label]:b.text,[props.Value]:b.inputType==='password'?'••••••••••':b.value||b.placeholder||''});n.name=b.text;if(b.height)n.resize(358,b.height);return n;}
  async function renderBlock(p,b){
    if(b.type==='button')return button(p,b);
    if(b.type==='field')return field(p,b);
    if(b.type==='choice')return field(p,{text:b.text+' · выбор',value:b.choices.join(' / ')});
    if(b.type==='checkbox'){const n=await button(p,{text:'☐ '+b.text,secondary:true});n.name='Review checkbox';return n;}
    if(b.type==='card'){const n=cardComp.createInstance();p.appendChild(n);n.setProperties({[props.CardTitle]:b.text,[props.CardMeta]:b.meta,[props.CardStatus]:b.status||'Опубликовано в QalaPulse'});n.name=b.text;await wire(n,b.action);return n;}
    if(b.type==='heading')return text(p,b.text,358,'Label');
    if(b.type==='text')return text(p,b.text,358,b.small?'Small':'Body',b.small?'muted':'ink');
    if(b.type==='note'||b.type==='badge'){const f=box(p,b.text);f.fills=[paint('soft')];f.paddingTop=10;f.paddingBottom=10;f.paddingLeft=12;f.paddingRight=12;await text(f,b.text,334,'Small','muted');return f;}
    if(b.type==='voice'){const f=box(p,'Voice recorder');f.strokes=[paint('line')];f.paddingTop=10;f.paddingBottom=10;await text(f,'Голосовое описание · демо',334,'Label');await button(f,{text:'Записать → Стоп → Прослушать',action:'voice-record',secondary:true});await text(f,'Состояния голоса интерактивны в HTML. В Figma показана структура управления.',334,'Small','muted');return f;}
    if(b.type==='progress'){const f=box(p,'Progress',358,22);const bar=box(f,'Progress bar',358,5,'HORIZONTAL',true);bar.fills=[paint('soft')];const fill=figma.createRectangle();bar.appendChild(fill);fill.resize(358*b.value/7,5);fill.fills=[paint('ink')];await text(f,b.text,358,'Small','muted');return f;}
    const f=box(p,b.type+' / '+b.text,358,b.height||140,'VERTICAL',true);f.fills=[paint('soft')];f.strokes=[paint('line')];f.primaryAxisAlignItems='CENTER';f.counterAxisAlignItems='CENTER';const label=await text(f,(b.type==='photo'?'[ ФОТО ]\n':b.type==='map'?'①             ②\n● Алматы\n':b.type==='success'?'✓\n':b.type==='loading'?'◌\n':'')+b.text,326,'Body','muted');label.textAlignHorizontal='CENTER';if(b.action)await wire(f,b.action);return f;
  }
  for(const s of SPEC.screens){stage('Экран '+s.id+' — '+s.title);const f=frames[s.id];await text(f,'09:41                                      QalaPulse',358,'Small','muted');const header=box(f,'Header');if(s.back){const back=await text(header,'‹ Назад',358,'Small');await wire(back,'go:'+s.back);}await text(header,s.title,358,'Title');await text(header,s.subtitle,358,'Small','muted');const body=box(f,'Body · vertical scroll');body.layoutSizingVertical='FILL';body.clipsContent=true;body.overflowDirection='VERTICAL';for(const b of s.blocks){stage('Экран '+s.id+' / '+b.type+' / '+(b.text||''));await renderBlock(body,b);}
    if(s.nav){stage('Экран '+s.id+' / нижняя навигация');const n=box(f,'Bottom navigation',358,48,'HORIZONTAL',true);n.itemSpacing=4;for(const [label,id]of [['Главная','01'],['Карта','02'],['+','06'],['События','14'],['Профиль','15']]){const f=box(n,label,68,44,'VERTICAL',true);f.primaryAxisAlignItems='CENTER';f.fills=[paint(id===s.id?'soft':'paper')];f.strokes=[paint('line')];const t=await text(f,label,68,'Small');t.textAlignHorizontal='CENTER';await wire(f,'go:'+id);}}
  }
  // A separate checked state uses basic navigation, so the mandatory human
  // review does not depend on paid advanced-prototyping variables.
  stage('Проверенное состояние AI');
  const checked=frames['11'].clone();page.appendChild(checked);checked.name='11b · Результат проверен';checked.x=2660;checked.y=2050;frames['11b']=checked;
  const checkUnchecked=frames['11'].findOne(n=>n.name==='Review checkbox');
  const checkChecked=checked.findOne(n=>n.name==='Review checkbox');
  await actions(checkUnchecked,[nav('11b')]);
  checkChecked.setProperties({[labelKey]:'☑ Я проверил(а) и исправил(а) результат'});await actions(checkChecked,[nav('11')]);
  const next=checked.findOne(n=>n.name==='Найти похожие обращения');next.swapComponent(buttons.Default);next.setProperties({[labelKey]:'Найти похожие обращения'});await wire(next,'review-next');
  await actions(frames['10'],[nav('11')],{type:'AFTER_TIMEOUT',timeout:1.5});
  for(const m of SPEC.modals){stage('Модальное окно '+m.id);const panel=box(modalFrames[m.id],'Dialog',342);panel.fills=[paint('paper')];panel.paddingTop=20;panel.paddingBottom=20;panel.paddingLeft=20;panel.paddingRight=20;panel.setBoundVariable('cornerRadius',tokens.radius);await text(panel,m.title,302,'Title');await text(panel,m.text,302,'Body');for(const b of m.blocks||[]){const n=await renderBlock(panel,b);n.resize(302,n.height);for(const t of n.findAllWithCriteria({types:['TEXT']}))t.resize(278,t.height);}for(const b of m.buttons)await button(panel,b,302);}
  stage('User Flow');
  const board=box(page,'00 · User Flow / Lab 4',2340);board.x=80;board.y=80;board.paddingTop=32;board.paddingBottom=32;board.paddingLeft=32;board.paddingRight=32;board.itemSpacing=20;board.fills=[paint('paper')];await text(board,'QalaPulse · Laboratory Work №4',2276,'Board');await text(board,'Wireframes Improvement and Interactive Elements',2276,'Title');await text(board,'15 основных экранов + состояние 11b «Проверено» · 5 модальных окон · кликабельные переходы\nОснова — существующее Flutter-приложение. UI серый и схематичный; фотографии, GPS и AI демонстрационные.',2276,'Body');
  for(const flow of SPEC.flows){await text(board,flow.title,2276,'Label');const row=box(board,'Flow / '+flow.title,2276,64,'HORIZONTAL');row.itemSpacing=10;row.counterAxisAlignItems='CENTER';for(const [i,step]of flow.steps.entries()){if(i)await text(row,'→',20,'Label');const node=box(row,step,flow.steps.length>9?153:220,64,'VERTICAL',true);node.paddingLeft=8;node.paddingRight=8;node.primaryAxisAlignItems='CENTER';node.fills=[paint(step.startsWith('M')?'soft':'paper')];node.strokes=[paint('line')];await text(node,step,node.width-16,'Small');}}
  await text(board,'Развилки: 11 → без проверки кнопка заблокирована; 11b → 12. Дубликат → подтвердить или создать новое. Любая модаль → «Отмена» / назад. Ошибка сети → черновик → повтор. Ни AI, ни поиск похожих обращений не принимают решение вместо жителя.',2276,'Body');
  await text(board,'Прототип: поля в Figma предзаполнены; выбор фильтров, запись голоса и ввод с валидацией проверяются в приложенном HTML. Нажатия не выполняют реальную съёмку, авторизацию или сетевые запросы. Это учебные wireframes, а не заявление о реализации новых функций.',2276,'Small','muted');
  const stateBoard=box(page,'Состояния кнопок и полей',760);stateBoard.x=2660;stateBoard.y=1100;stateBoard.paddingTop=24;stateBoard.paddingBottom=24;stateBoard.paddingLeft=24;stateBoard.paddingRight=24;stateBoard.fills=[paint('paper')];await text(stateBoard,'Button states',700,'Title');for(const state of ['Default','Hover','Pressed','Disabled','Loading']){const row=box(stateBoard,state,700,50,'HORIZONTAL');await text(row,state,180,'Body');const n=buttons[state].createInstance();row.appendChild(n);n.resize(358,48);}await text(stateBoard,'Disabled: нет фото / AI не проверен. Loading: повторное действие недоступно. Hover — только мышь; Active — нажатие на мобильном устройстве.',700,'Body');
  await field(stateBoard,{text:'Ошибка формы',value:'resident — некорректный email'});
  page.flowStartingPoints=[{nodeId:frames['01'].id,name:'QalaPulse · основной сценарий'},{nodeId:frames['04'].id,name:'Вход и регистрация'}];
  const textNodes=page.findAllWithCriteria({types:['TEXT']});const wrongFonts=textNodes.filter(t=>t.fontName!==figma.mixed&&t.fontName.family!==fontFamily);if(wrongFonts.length)throw new Error('Font validation failed');
  const result={screens:Object.keys(frames).length,modals:Object.keys(modalFrames).length,connections:links.length,components:page.findAllWithCriteria({types:['COMPONENT']}).length,instances:page.findAllWithCriteria({types:['INSTANCE']}).length,textNodes:textNodes.length};
  page.setPluginData('lab4-complete','true');
  console.log('QalaPulse Lab 4 validation',result);figma.viewport.scrollAndZoomIntoView([board,...Object.values(frames)]);figma.closePlugin('Создано: 15 экранов + проверенное состояние AI, 5 модалей, '+links.length+' связей. Откройте Prototype → Present.');
}
if(figma.command==='connect')connectExisting().catch(showBuildError);
else buildLab().catch(showBuildError);
