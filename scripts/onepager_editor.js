(() => {
  'use strict';
  const svg=document.querySelector('main svg');
  const nodes=[...svg.querySelectorAll('text')];
  const fields=['text','size','color','font','x','y'];
  const controls=Object.fromEntries(fields.map(key=>[key,document.getElementById('edit-'+key)]));
  const select=document.getElementById('element-select');
  const status=document.getElementById('save-status');
  const warning=document.getElementById('edit-warning');
  const key='qalapulse.onepager.editor.v1:'+location.pathname;
  let selected=-1,history=[],future=[];
  function snapshot(){return nodes.map(n=>({text:n.textContent,size:n.getAttribute('font-size'),color:n.getAttribute('fill'),font:n.getAttribute('font-family'),x:n.getAttribute('x'),y:n.getAttribute('y')}));}
  const original=snapshot();
  function restore(data){
    if(!Array.isArray(data)||data.length!==nodes.length)return false;
    if(data.some(v=>!v||typeof v.text!=='string'||!Number.isFinite(Number(v.size))||!Number.isFinite(Number(v.x))||!Number.isFinite(Number(v.y))||!/^#[0-9a-f]{6}$/i.test(v.color)||!['InterRegular','InterSemiBold','InterBold'].includes(v.font)))return false;
    data.forEach((v,i)=>{const n=nodes[i];n.textContent=v.text;for(const [k,a]of Object.entries({size:'font-size',color:'fill',font:'font-family',x:'x',y:'y'}))n.setAttribute(a,v[k]);});return true;
  }
  function menu(){select.innerHTML='';nodes.forEach((n,i)=>{const o=document.createElement('option');o.value=i;o.textContent=(i+1)+'. '+n.textContent.slice(0,60);select.appendChild(o);});if(selected>=0)select.value=selected;}
  function saved(){try{localStorage.setItem(key,JSON.stringify(snapshot()));status.textContent='Saved in this browser. Download HTML to keep a portable copy.';}catch{status.textContent='Browser storage unavailable. Use Download HTML to keep your changes.';}}
  function sync(){
    document.getElementById('undo-edit').disabled=!history.length;document.getElementById('redo-edit').disabled=!future.length;
    if(selected<0)return;
    const v=snapshot()[selected];fields.forEach(f=>controls[f].value=v[f]);
    const b=nodes[selected].getBBox();
    warning.textContent=b.x<0||b.y<0||b.x+b.width>595.28||b.y+b.height>841.89?'This text extends beyond the A4 page. Reduce its size or adjust its position.':'Each item is one fixed line. Long text may overlap nearby content; check the print preview.';
  }
  function choose(i){
    if(!nodes[i])return;nodes.forEach(n=>n.removeAttribute('data-selected'));selected=i;nodes[i].setAttribute('data-selected','true');select.value=i;document.getElementById('edit-fields').disabled=false;sync();
  }
  nodes.forEach((n,i)=>n.addEventListener('click',()=>choose(i)));
  select.addEventListener('change',()=>choose(Number(select.value)));
  function apply(){
    if(selected<0)return;
    const size=Number(controls.size.value),x=Number(controls.x.value),y=Number(controls.y.value);
    if(!Number.isFinite(size)||size<4||size>80||!Number.isFinite(x)||!Number.isFinite(y))return;
    const before=snapshot(),n=nodes[selected];
    n.textContent=controls.text.value.replace(/[\r\n]+/g,' ');
    n.setAttribute('font-size',String(size));n.setAttribute('fill',controls.color.value);n.setAttribute('font-family',controls.font.value);n.setAttribute('x',String(x));n.setAttribute('y',String(y));
    if(JSON.stringify(before)!==JSON.stringify(snapshot())){history.push(before);if(history.length>100)history.shift();future=[];saved();menu();}
    // Preserve the caret in the text field while applying live edits.
    document.getElementById('undo-edit').disabled=!history.length;document.getElementById('redo-edit').disabled=!future.length;
    const b=n.getBBox();warning.textContent=b.x<0||b.y<0||b.x+b.width>595.28||b.y+b.height>841.89?'Text extends beyond the page. Reduce font size or move it.':'Changes applied. Check spacing before printing; text lines do not wrap automatically.';
  }
  fields.forEach(f=>controls[f].addEventListener('input',apply));
  document.getElementById('undo-edit').addEventListener('click',()=>{if(!history.length)return;future.push(snapshot());restore(history.pop());menu();sync();saved();});
  document.getElementById('redo-edit').addEventListener('click',()=>{if(!future.length)return;history.push(snapshot());restore(future.pop());menu();sync();saved();});
  document.getElementById('reset-edit').addEventListener('click',()=>{history.push(snapshot());future=[];restore(original);menu();sync();saved();});
  document.getElementById('print-edit').addEventListener('click',()=>window.print());
  document.getElementById('download-edit').addEventListener('click',()=>{
    const clone=document.documentElement.cloneNode(true);
    clone.querySelectorAll('[data-selected]').forEach(n=>n.removeAttribute('data-selected'));
    clone.querySelector('#save-status').textContent='Click any text to edit it.';
    clone.querySelector('#element-select').innerHTML='';
    clone.querySelectorAll('#edit-fields input,#edit-fields textarea').forEach(n=>{n.value='';if(n.tagName==='TEXTAREA')n.textContent='';else n.removeAttribute('value');});
    const blob=new Blob(['<!doctype html>\n'+clone.outerHTML],{type:'text/html;charset=utf-8'});
    const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='QalaPulse_OnePager_Edited.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
    status.textContent='Editable HTML downloaded. Use Print / Save PDF for the updated PDF.';
  });
  try{const raw=localStorage.getItem(key);if(raw&&restore(JSON.parse(raw)))status.textContent='Your previous edits were restored from this browser.';}catch{}
  menu();choose(0);
})();
