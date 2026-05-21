import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { PDFParse } from 'pdf-parse';

const [input, outDir, pagesArg, widthArg = '1400'] = process.argv.slice(2);

if (!input || !outDir || !pagesArg) {
  console.error('Usage: node scripts/render-pdf-pages.mjs <input.pdf> <outDir> <pages|start-end> [desiredWidth]');
  process.exit(1);
}

function parsePages(value) {
  return value.split(',').flatMap((part) => {
    const match = part.trim().match(/^(\d+)-(\d+)$/);
    if (match) {
      const start = Number(match[1]);
      const end = Number(match[2]);
      return Array.from({ length: end - start + 1 }, (_, index) => start + index);
    }
    return [Number(part.trim())];
  }).filter(Number.isFinite);
}

const pages = parsePages(pagesArg);
await mkdir(outDir, { recursive: true });

const data = await readFile(input);
const parser = new PDFParse({ data });

try {
  for (const page of pages) {
    const result = await parser.getScreenshot({
      partial: [page],
      desiredWidth: Number(widthArg),
      imageDataUrl: false,
      imageBuffer: true,
    });
    const image = result.pages?.[0]?.data;
    if (!image) {
      console.error(`No image returned for page ${page}`);
      continue;
    }
    const output = join(outDir, `page-${String(page).padStart(3, '0')}.png`);
    await writeFile(output, image);
    console.error(`Rendered ${output}`);
  }
} finally {
  await parser.destroy();
}
