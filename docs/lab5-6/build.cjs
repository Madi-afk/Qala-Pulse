const fs=require('node:fs');
const path=require('node:path');
const dir=__dirname;
const common=fs.readFileSync(path.join(dir,'common.js'),'utf8');
const foundation=fs.readFileSync(path.join(dir,'foundations.js'),'utf8').replace('// COMMON',common);
const screens=fs.readFileSync(path.join(dir,'screens.js'),'utf8').replace('// COMMON',common);
const restore=`
const page=await figma.getNodeByIdAsync(ledger.pageId);await figma.setCurrentPageAsync(page);
const tokens={},styles={},components={};
for(const [key,id]of Object.entries(ledger.tokens))tokens[key]=await figma.variables.getVariableByIdAsync(id);
for(const [key,id]of Object.entries(ledger.styles))styles[key]=await figma.getStyleByIdAsync(id);
for(const [key,id]of Object.entries(ledger.components))components[key]=await figma.getNodeByIdAsync(id);
`;
const flowBoard=fs.readFileSync(path.join(dir,'flow-board.js'),'utf8');
const runtime=fs.readFileSync(path.join(dir,'runtime.js'),'utf8');
const code=`// QalaPulse Lab 5–6. Generated from local sources; no network access.\nasync function buildFoundations(){\n${foundation}\n}\nasync function buildScreens(ledger){\n${restore}\n${screens}\n}\n${flowBoard}
${runtime}`;
if(/figma\s*\.\s*createPage\s*\(/.test(code))throw new Error('Starter-compatible plugin must not create pages');
new (Object.getPrototypeOf(async function(){}).constructor)('figma',code);
fs.mkdirSync(path.join(dir,'figma-plugin'),{recursive:true});
fs.writeFileSync(path.join(dir,'figma-plugin','code.js'),code);
fs.writeFileSync(path.join(dir,'figma-plugin','manifest.json'),JSON.stringify({name:'QalaPulse Lab 5-6 — STARTER FIX v2',id:'qalapulse-lab5-6-starter-v2',api:'1.0.0',main:'code.js',editorType:['figma'],documentAccess:'dynamic-page',networkAccess:{allowedDomains:['none']},menu:[{name:'Create UI & interactive prototype',command:'build'},{name:'Check existing prototype',command:'verify'}]},null,2));
console.log('Built native Figma plugin ('+Buffer.byteLength(code)+' bytes); JavaScript syntax valid.');

const starterDir=path.join(dir,'figma-plugin-starter-v2');
fs.mkdirSync(starterDir,{recursive:true});
for(const file of ['code.js','manifest.json'])fs.copyFileSync(path.join(dir,'figma-plugin',file),path.join(starterDir,file));
