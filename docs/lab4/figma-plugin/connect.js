// Connect the existing Lab 4 frames on the current page without rebuilding them.
async function connectExisting() {
  stage('Проверка существующих экранов');
  const page=figma.currentPage;
  const all=page.findAllWithCriteria({types:['FRAME']});
  const frames={},problems=[];
  for(const item of [...SPEC.screens,...SPEC.modals]){
    const matches=all.filter(n=>n.name.startsWith(item.id+' · '));
    if(matches.length!==1){problems.push(item.id+': найдено '+matches.length+' экранов');continue;}
    frames[item.id]=matches[0];
    if(matches[0].findAllWithCriteria({types:['TEXT']}).length<2)problems.push(item.id+': экран не заполнен');
  }
  function find(root,name){
    const nodes=root.findAll(n=>n.name===name);
    return nodes.find(n=>n.type==='INSTANCE'||n.type==='FRAME')||nodes.find(n=>n.type==='TEXT');
  }
  for(const item of [...SPEC.screens,...SPEC.modals]){
    if(!frames[item.id])continue;
    for(const b of [...(item.blocks||[]),...(item.buttons||[])]){
      if(['button','card'].includes(b.type)&&!find(frames[item.id],b.text))problems.push(item.id+': нет кнопки «'+b.text+'»');
    }
  }
  if(problems.length)throw new Error('Сначала завершите создание макетов на текущей странице:\n'+problems.join('\n'));
  const fonts=new Map();
  for(const root of Object.values(frames))for(const t of root.findAllWithCriteria({types:['TEXT']})){
    for(const segment of t.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(segment.fontName),segment.fontName);
  }
  await Promise.all([...fonts.values()].map(font=>figma.loadFontAsync(font)));
  const checkedMatches=all.filter(n=>n.name.startsWith('11b · '));
  if(checkedMatches.length>1)throw new Error('На странице несколько состояний 11b. Оставьте одно или выберите другую страницу.');
  let checked=checkedMatches[0];
  if(!checked){
    checked=frames['11'].clone();page.appendChild(checked);checked.name='11b · Результат проверен';
    checked.x=Math.max(...page.children.map(n=>n.x+n.width))+100;checked.y=frames['11'].y;
  }
  frames['11b']=checked;
  const changed=new Set(),connections=[],skipped=[];
  function nodeAction(id,overlay=false){return {type:'NODE',destinationId:frames[id].id,navigation:overlay?'OVERLAY':'NAVIGATE',transition:null,resetScrollPosition:true};}
  async function link(node,action,trigger={type:'ON_CLICK'}){
    if(!node)throw new Error('Не найден элемент для связи: '+buildStage);
    for(let p=node;p&&p.type!=='PAGE';p=p.parent)if(p.id===action.destinationId){skipped.push(node.name);return;}
    const previous=node.reactions.filter(r=>r.trigger&&r.trigger.type!==trigger.type);
    await node.setReactionsAsync([...previous,{trigger,actions:[action]}]);
    changed.add(node.id);connections.push({from:node.id,to:action.destinationId||'CLOSE',trigger:trigger.type});
  }
  const targets={'photo-camera':'07','photo-gallery':'07',login:'06',register:'06','confirm-existing':'14','confirm-duplicate':'03',publish:'13',retry:'11',resolved:'03',partial:'03',unresolved:'03',comment:'14','my-incidents':'01',logout:'04','review-next':'12'};
  async function wire(node,action){
    if(!action)return;
    if(action.startsWith('go:'))await link(node,nodeAction(action.slice(3)));
    else if(action.startsWith('modal:'))await link(node,nodeAction(action.slice(6),true));
    else if(['close','apply-filters','reset-filters'].includes(action))await link(node,{type:'CLOSE'});
    else if(targets[action])await link(node,nodeAction(targets[action]));
  }
  const navItems=[['Главная','01'],['Карта','02'],['+','06'],['События','14'],['Профиль','15']];
  for(const item of [...SPEC.screens,...SPEC.modals]){
    stage('Связи экрана '+item.id);
    const root=frames[item.id];
    for(const b of [...(item.blocks||[]),...(item.buttons||[])]){
      if(!b.action||b.disabled||b.loading||b.gate)continue;
      const node=find(root,b.text)||root.findOne(n=>n.name===b.type+' / '+b.text);
      if(node)await wire(node,b.action);
    }
    if(item.back)await wire(find(root,'‹ Назад'),'go:'+item.back);
    if(item.nav){const bar=find(root,'Bottom navigation');if(!bar)throw new Error('Нет нижнего меню: '+item.id);for(const [label,id]of navItems)if(id!==item.id)await wire(find(bar,label),'go:'+id);}
  }
  stage('Обязательная проверка AI');
  const check=find(frames['11'],'Review checkbox'),checkDone=find(checked,'Review checkbox');
  const disabledNext=find(frames['11'],'Найти похожие обращения'),enabledNext=find(checked,'Найти похожие обращения');
  if(!check||!checkDone||!disabledNext||!enabledNext)throw new Error('Не найдены элементы проверки AI на экране 11.');
  await disabledNext.setReactionsAsync(disabledNext.reactions.filter(r=>r.trigger&&r.trigger.type!=='ON_CLICK'));changed.add(disabledNext.id);
  const defaultButton=page.findAllWithCriteria({types:['COMPONENT']}).find(n=>n.name==='State=Default');
  if(defaultButton&&enabledNext.type==='INSTANCE')enabledNext.swapComponent(defaultButton);
  for(const t of enabledNext.findAllWithCriteria({types:['TEXT']}))t.characters='Найти похожие обращения';
  for(const t of checkDone.findAllWithCriteria({types:['TEXT']}))t.characters='☑ Я проверил(а) и исправил(а) результат';
  await link(check,nodeAction('11b'));await link(checkDone,nodeAction('11'));await link(enabledNext,nodeAction('12'));
  if(SPEC.screens.find(s=>s.id==='11').back)await link(find(checked,'‹ Назад'),nodeAction('09'));
  await link(frames['10'],nodeAction('11'),{type:'AFTER_TIMEOUT',timeout:1.5});
  const starts=page.flowStartingPoints.filter(p=>p.nodeId!==frames['01'].id&&p.nodeId!==frames['04'].id);
  page.flowStartingPoints=[...starts,{nodeId:frames['01'].id,name:'QalaPulse · основной сценарий'},{nodeId:frames['04'].id,name:'Вход и регистрация'}];
  for(const c of connections)if(c.to!=='CLOSE'&&!Object.values(frames).some(f=>f.id===c.to))throw new Error('Связь ведёт за пределы набора экранов.');
  figma.viewport.scrollAndZoomIntoView(Object.values(frames));
  console.log('QalaPulse connections',{page:page.id,connections,changed:[...changed],skipped});
  figma.closePlugin('Связи добавлены: '+connections.length+'. Выберите 01 · Главная и нажмите Present (▶).');
}
