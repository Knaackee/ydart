import * as Y from 'yjs';

const doc = new Y.Doc();
doc.clientID = 1;
const text = doc.getText('content');
const meta = doc.getMap('meta');

text.insert(0, 'hello from yjs');
meta.set('source', 'yjs');
meta.set('version', 1);

const update = Y.encodeStateAsUpdate(doc);
const stateVector = Y.encodeStateVector(doc);

console.log(JSON.stringify({
  content: text.toString(),
  updateBase64: Buffer.from(update).toString('base64'),
  stateVectorBase64: Buffer.from(stateVector).toString('base64'),
}, null, 2));
