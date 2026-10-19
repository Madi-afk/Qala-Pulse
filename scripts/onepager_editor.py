"""Embed a self-contained text editor in the SVG one-pager source."""
from pathlib import Path
import re

SCRIPTS=Path(__file__).resolve().parent

def add_editor(document):
    if 'id="onepager-editor-script"' in document:
        return document
    css=(SCRIPTS/'onepager_editor.css').read_text(encoding='utf-8')
    js=(SCRIPTS/'onepager_editor.js').read_text(encoding='utf-8')
    toolbar='''<div class="toolbar" aria-label="Document editing tools">
<button id="download-edit">Download HTML</button><button id="print-edit">Print / Save PDF</button>
<button class="secondary" id="undo-edit" disabled>Undo</button><button class="secondary" id="redo-edit" disabled>Redo</button>
<button class="secondary" id="reset-edit">Reset edits</button><span class="save-status" id="save-status" role="status">Click any text to edit it.</span></div>'''
    panel='''<aside class="editor-panel" aria-label="Text editor"><h2>Edit your one pager</h2>
<p class="editor-hint">Click a text line on the page or choose it below. Changes appear immediately.</p>
<label>Text element<select id="element-select"></select></label><fieldset id="edit-fields" disabled>
<label>Text<textarea id="edit-text" spellcheck="true"></textarea></label>
<div class="editor-grid"><label>Font size (pt)<input id="edit-size" type="number" min="4" max="80" step="0.5"></label>
<label>Text color<input id="edit-color" type="color"></label></div>
<label>Font weight<select id="edit-font"><option value="InterRegular">Regular</option><option value="InterSemiBold">Semibold</option><option value="InterBold">Bold</option></select></label>
<div class="editor-grid"><label>Horizontal position<input id="edit-x" type="number" step="1"></label><label>Vertical position<input id="edit-y" type="number" step="1"></label></div>
</fieldset><p id="edit-warning" class="editor-warning" role="status"></p>
<p class="editor-hint">Edits are saved locally in your browser. Download HTML to keep or share the editable document. To export a new PDF, use A4, no margins and background graphics.</p></aside>'''
    document=re.sub(r'<div class="toolbar">.*?</div>',toolbar,document,count=1,flags=re.S)
    document=document.replace('<main aria-label=', '<div class="editor-layout"><main aria-label=',1)
    document=document.replace('</main>','</main>'+panel+'</div>',1)
    document=document.replace('</head>','<style id="onepager-editor-style">'+css+'</style></head>')
    document=document.replace('</body>','<script id="onepager-editor-script">'+js+'</script></body>')
    return document

if __name__=='__main__':
    path=SCRIPTS.parent/'output/pdf/qalapulse/QalaPulse_OnePager.html'
    path.write_text(add_editor(path.read_text(encoding='utf-8')),encoding='utf-8')
    print('Visual editor added:',path)
