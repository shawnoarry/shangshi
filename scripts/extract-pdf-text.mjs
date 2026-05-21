import { readFile, writeFile } from 'node:fs/promises';
import { basename } from 'node:path';
import { PDFParse } from 'pdf-parse';

const [input, outText, outJsonl] = process.argv.slice(2);

if (!input || !outText || !outJsonl) {
  console.error('Usage: node scripts/extract-pdf-text.mjs <input.pdf> <out.txt> <out.jsonl>');
  process.exit(1);
}

const data = await readFile(input);
const parser = new PDFParse({ data });

try {
  const info = await parser.getInfo({ parsePageInfo: true });
  const total = info.total ?? info.pages?.length ?? 0;
  const lines = [
    `# ${basename(input)}`,
    `Pages: ${total}`,
    `Title: ${info.info?.Title ?? ''}`,
    `Author: ${info.info?.Author ?? ''}`,
    `Creator: ${info.info?.Creator ?? ''}`,
    `Producer: ${info.info?.Producer ?? ''}`,
    '',
  ];
  const jsonl = [];

  for (let page = 1; page <= total; page += 1) {
    const result = await parser.getText({ partial: [page] });
    const text = (result.text ?? '').replace(/\r\n/g, '\n').trim();
    lines.push(`\n\n--- Page ${page} ---\n${text}`);
    jsonl.push(JSON.stringify({ page, text }));
    if (page % 20 === 0 || page === total) {
      console.error(`Extracted page ${page}/${total}`);
    }
  }

  await writeFile(outText, lines.join('\n'), 'utf8');
  await writeFile(outJsonl, `${jsonl.join('\n')}\n`, 'utf8');
} finally {
  await parser.destroy();
}
