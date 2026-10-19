// Structural smoke check. This does not emulate Figma's layout engine.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
let sequence = 0;
let connectionRuns = 0;
const nodes = new Map();
class Node {
  constructor(type) { this.type=type;this.id=String(++sequence);this.children=[];this.reactions=[];this.width=100;this.height=100;nodes.set(this.id,this); }
  appendChild(n) { if(n.parent)n.parent.children=n.parent.children.filter(x=>x!==n);n.parent=this;this.children.push(n); }
  resize(w,h) { assert(w>0&&h>0);this.width=w;this.height=h; }
  resizeWithoutConstraints(w,h) { this.resize(w,h); }
  setBoundVariable() {}
  getPluginData(key) { return this.pluginData?.[key]||''; }
  setPluginData(key,value) { this.pluginData={...this.pluginData,[key]:value}; }
  async setTextStyleIdAsync() {}
  getStyledTextSegments() { return [{fontName:this.fontName}]; }
  addComponentProperty(n,type,value) { return n; }
  findAllWithCriteria({types}) { return this.findAll(n=>types.includes(n.type)); }
  findAll(pred) { return this.children.flatMap(n=>[...(pred(n)?[n]:[]),...n.findAll(pred)]); }
  findOne(pred) { return this.findAll(pred)[0]||null; }
  clone() { const n=new Node(this.type);for(const k of Object.keys(this)){if(!['children','parent','id'].includes(k))n[k]=this[k];}for(const child of this.children)n.appendChild(child.clone());return n; }
  createInstance() { const n=this.clone();n.type='INSTANCE';return n; }
  setProperties(values) { for(const t of this.findAllWithCriteria({types:['TEXT']})){const key=t.componentPropertyReferences?.characters;if(key in values)t.characters=values[key];} }
  swapComponent(c) { this.children=[];for(const child of c.children)this.appendChild(child.clone()); }
  async setReactionsAsync(reactions) {
    if(process.env.LAB4_TEST_ERROR==='1')throw 'Test: Figma returned a string error';
    const ancestors=new Set();for(let n=this;n&&n.type!=='PAGE';n=n.parent)ancestors.add(n.id);
    for(const reaction of reactions)for(const action of reaction.actions){
      if(action.navigation==='NAVIGATE')assert(!ancestors.has(action.destinationId),'Self-navigation must be excluded');
    }
    this.reactions=reactions;
  }
}
const root=new Node('DOCUMENT');
const figma={root,mixed:Symbol('mixed'),viewport:{scrollAndZoomIntoView(){}},
  showUI:html=>{
    assert.equal(process.env.LAB4_TEST_ERROR,'1',html);
    assert(html.includes('Test: Figma returned a string error'));
    assert(html.includes('Экран 01'));
    assert(!html.includes('undefined'));
    assert.notEqual(root.children[0].getPluginData('lab4-complete'),'true');
    console.log('PASS: string error preserved with screen context; incomplete page not marked complete');
  },
  loadFontAsync:async()=>{},setCurrentPageAsync:async p=>{figma.currentPage=p;},
  createTextStyle:()=>({id:String(++sequence)}),
  combineAsVariants:(variants,page)=>{const set=new Node('COMPONENT_SET');page.appendChild(set);variants.forEach(n=>set.appendChild(n));return set;},
  variables:{createVariableCollection:()=>({defaultModeId:'default'}),createVariable:()=>({setValueForMode(){},setVariableCodeSyntax(){}}),setBoundVariableForPaint:p=>p},
  closePlugin:message=>{
    assert(!message.startsWith('Не удалось'),message);
    const page=root.children[0];
    assert.equal(page.children.filter(n=>/^\d{2} · /.test(n.name||'')).length,16); // 15 screens + flow board
    assert.equal(page.children.filter(n=>/^M\d · /.test(n.name||'')).length,5);
    let links=0;
    for(const n of page.findAll(n=>!!n.reactions))for(const reaction of n.reactions)for(const action of reaction.actions){if(action.destinationId)assert(nodes.has(action.destinationId));links++;}
    assert(links>80);
    assert.equal(page.flowStartingPoints.length,2);
    console.log('PASS: plugin structure, 15 screens + checked state, 5 modals, '+links+' reactions, valid destinations');
    if(process.env.LAB4_TEST_CONNECT==='1'&&connectionRuns<2){
      connectionRuns++;
      const countBefore=page.children.length;
      vm.runInContext('connectExisting().catch(showBuildError)',context);
      assert.equal(page.children.length,countBefore);
    }else if(connectionRuns===2){
      const review=page.children.find(n=>n.name==='11 · Проверка результата');
      const next=review.findOne(n=>n.name==='Найти похожие обращения');
      assert.equal(next.reactions.length,0);
      console.log('PASS: reconnect twice; no new screens, disabled review gate retained, start points unique');
    }
  }
};
for(const [method,type]of Object.entries({createPage:'PAGE',createFrame:'FRAME',createText:'TEXT',createSection:'SECTION',createComponent:'COMPONENT',createRectangle:'RECTANGLE'}))figma[method]=()=>{const n=new Node(type);(type==='PAGE'?root:figma.currentPage).appendChild(n);return n;};
const context=vm.createContext({figma,console,Promise,Error});
vm.runInContext(fs.readFileSync(__dirname+'/figma-plugin/code.js','utf8'),context);
