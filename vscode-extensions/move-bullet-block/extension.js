const vscode = require('vscode');

const bulletMarkerPattern = /^[ \t]*(?:[-*+]|\d+[.)])(?:\s|$)/;
const headingPattern = /^#{1,6}\s/;

function indentOf(text) {
  return text.match(/^[ \t]*/)[0].length;
}

function isBlank(text) {
  return /^\s*$/.test(text);
}

function isHeading(text) {
  return headingPattern.test(text);
}

function isBulletMarker(text) {
  return bulletMarkerPattern.test(text);
}

// Walk up from the cursor to the bullet marker line that owns it, or -1 if the cursor isn't in a list item.
function findOwnerLine(document, cursorLine) {
  for (let i = cursorLine; i >= 0; i--) {
    const text = document.lineAt(i).text;
    if (isBulletMarker(text)) return i;
    if (isBlank(text) || isHeading(text)) return -1;
  }
  return -1;
}

// The block is the owner line plus every deeper-indented line below it, stopping at a sibling, blank line, or heading.
function computeBlockEnd(document, ownerLine, indent) {
  let end = ownerLine;
  for (let i = ownerLine + 1; i < document.lineCount; i++) {
    const text = document.lineAt(i).text;
    if (isBlank(text) || isHeading(text) || indentOf(text) <= indent) break;
    end = i;
  }
  return end;
}

// The sibling group is every block at this indent, extending until a blank line, heading, or dedent.
function computeGroupStart(document, ownerLine, indent) {
  let start = ownerLine;
  for (let i = ownerLine - 1; i >= 0; i--) {
    const text = document.lineAt(i).text;
    if (isBlank(text) || isHeading(text) || indentOf(text) < indent) break;
    start = i;
  }
  return start;
}

function computeGroupEnd(document, blockEnd, indent) {
  let end = blockEnd;
  for (let i = blockEnd + 1; i < document.lineCount; i++) {
    const text = document.lineAt(i).text;
    if (isBlank(text) || isHeading(text) || indentOf(text) < indent) break;
    end = i;
  }
  return end;
}

async function moveBulletBlock(direction) {
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.document.languageId !== 'markdown') return;

  const document = editor.document;
  const cursorLine = editor.selection.active.line;

  const ownerLine = findOwnerLine(document, cursorLine);
  if (ownerLine === -1) {
    vscode.window.setStatusBarMessage('Move Bullet Block: cursor is not inside a list item', 3000);
    return;
  }

  const indent = indentOf(document.lineAt(ownerLine).text);
  const blockEnd = computeBlockEnd(document, ownerLine, indent);
  const groupStart = computeGroupStart(document, ownerLine, indent);
  const groupEnd = computeGroupEnd(document, blockEnd, indent);

  if (direction === 'bottom' && blockEnd === groupEnd) return;
  if (direction === 'top' && ownerLine === groupStart) return;

  const startPos = new vscode.Position(ownerLine, 0);
  const endPos = document.lineAt(blockEnd).rangeIncludingLineBreak.end;
  const blockRange = new vscode.Range(startPos, endPos);

  const eol = document.eol === vscode.EndOfLine.CRLF ? '\r\n' : '\n';
  let insertText = document.getText(blockRange);
  if (!insertText.endsWith(eol)) insertText += eol;

  const blockLineCount = blockEnd - ownerLine + 1;
  const newOwnerLine = direction === 'bottom'
    ? groupEnd - blockLineCount + 1
    : groupStart;
  const movedSelections = editor.selections.map((selection) => ({
    anchor: new vscode.Position(
      newOwnerLine + selection.anchor.line - ownerLine,
      selection.anchor.character,
    ),
    active: new vscode.Position(
      newOwnerLine + selection.active.line - ownerLine,
      selection.active.character,
    ),
  }));

  await editor.edit((editBuilder) => {
    editBuilder.delete(blockRange);
    if (direction === 'bottom') {
      const insertPos = document.lineAt(groupEnd).rangeIncludingLineBreak.end;
      editBuilder.insert(insertPos, insertText);
    } else {
      editBuilder.insert(new vscode.Position(groupStart, 0), insertText);
    }
  });

  editor.selections = movedSelections.map(({ anchor, active }) => new vscode.Selection(anchor, active));
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('moveBulletBlock.moveToBottom', () => moveBulletBlock('bottom')),
    vscode.commands.registerCommand('moveBulletBlock.moveToTop', () => moveBulletBlock('top')),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
