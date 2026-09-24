// Check page saves through artifact host's own save where host offers one; not Nim because
//   what is under check is page's reach for `window.claude`, which only browser holds.
//   Host is stood in for: script put in before page's own records every save it is handed
//   and answers as it is told. Real host asks reader to confirm; that prompt is host's and
//   out of reach here, so check holds page to contract of `claude.use("downloads")` alone.

import type { Browser } from '@playwright/test';
import { report } from './report';

/** One save host was handed: name page asked for, and bytes. */
interface SaveHanded {
  filename: string;
  bytes: number[];
}

/** Stand-in host's state, on page's window. */
interface HostStandIn {
  answer: string;
  saves: SaveHanded[];
}

/** CRC-32 as zip computes it, written out here so page's own is not what checks itself. */
function crcOf(bytes: Uint8Array): number {
  let crc = 0xFFFFFFFF;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = crc & 1 ? 0xEDB88320 ^ (crc >>> 1) : crc >>> 1;
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

/** Name and contents of zip's only entry, or reason it is not zip of one stored entry. */
function entryOnly(bytes: Uint8Array): { name: string; data: Uint8Array } | string {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  if (bytes.length < 30 || view.getUint32(0, true) !== 0x04034B50) return 'no local header';
  if (view.getUint16(8, true) !== 0) return 'entry is not stored';
  const size = view.getUint32(18, true);
  const length_name = view.getUint16(26, true);
  const start = 30 + length_name + view.getUint16(28, true);
  const data = bytes.subarray(start, start + size);
  if (crcOf(data) !== view.getUint32(14, true)) return 'checksum does not match contents';
  const end = bytes.length - 22;
  if (end < 0 || view.getUint32(end, true) !== 0x06054B50) return 'no end record';
  if (view.getUint16(end + 10, true) !== 1) return 'more than one entry';
  const name = new TextDecoder().decode(bytes.subarray(30, 30 + length_name));
  return { name, data };
}

/** Open page afresh in `browser`, with host stood in before page's own script runs. */
export async function driveHostSave(
  browser: Browser, url: string, size: { width: number; height: number },
): Promise<void> {
  const page = await browser.newPage({ viewport: size });
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.addInitScript(() => {
    const host: HostStandIn = { answer: 'saved', saves: [] };
    const save = async (request: { filename: string; data: Blob }): Promise<{ status: string }> => {
      const bytes = Array.from(new Uint8Array(await request.data.arrayBuffer()));
      host.saves.push({ filename: request.filename, bytes });
      if (host.answer !== 'saved') throw { code: host.answer, message: 'stand-in' };
      return { status: 'saved' };
    };
    const window_host = window as unknown as {
      host_stand_in: HostStandIn;
      claude: { use: (name: string) => Promise<unknown> };
    };
    window_host.host_stand_in = host;
    window_host.claude = {
      use: async (name) => (name === 'downloads' ? Object.freeze({ save }) : null),
    };
  });
  await page.goto(url);
  await page.waitForFunction(
    () => typeof nimSceneCount === 'function' && nimSceneCount() > 0,
    null, { timeout: 60000, polling: 'raf' },
  );
  const saves = () => page.evaluate(
    () => (window as unknown as { host_stand_in: HostStandIn }).host_stand_in.saves);
  const labels = () => page.evaluate(
    () => nimSceneHandlesCreated().map((handle) => nimObjectLabel(handle)));
  const toastSays = () => page.evaluate(() => ({
    text: document.getElementById('toast')?.textContent ?? '',
    is_link: document.querySelector('#toast a') !== null,
  }));

  // Scene: extension host refuses, so page hands it zip holding scene file unchanged.
  const labels_saved = await labels();
  await page.evaluate(() => document.getElementById('button-save-scene')?.click());
  await page.waitForFunction(
    () => (window as unknown as { host_stand_in: HostStandIn }).host_stand_in.saves.length > 0,
    null, { timeout: 10000 },
  ).catch(() => undefined);
  const scene = (await saves())[0];
  const entry = scene === undefined ? 'nothing handed' : entryOnly(new Uint8Array(scene.bytes));
  const magic = typeof entry === 'string' ?
    '' : new TextDecoder().decode(entry.data.subarray(0, 4));
  report(
    'on the artifact host, a scene saves through the host, as a zip that holds the scene file',
    scene?.filename === 'scene.zip' && typeof entry !== 'string' &&
      entry.name === 'scene.rgascene' && magic === await page.evaluate(() => nimSceneMagic()),
    scene === undefined ? 'host was handed nothing' :
      `${scene.filename}, ${typeof entry === 'string' ? entry : `${entry.name} opens ${magic}`}`,
  );

  // What host saved loads back, through page's own file input, as scene it was.
  await page.evaluate(() => nimSceneClear());
  await page.setInputFiles('#file-load-scene', {
    name: scene?.filename ?? 'scene.zip', mimeType: 'application/zip',
    buffer: Buffer.from(scene?.bytes ?? []),
  });
  await page.waitForFunction(
    (count) => nimSceneCount() === count, labels_saved.length, { timeout: 10000 },
  ).catch(() => undefined);
  const labels_loaded = await labels();
  report(
    'and the zip the host saved loads back as the scene it holds',
    labels_loaded.length > 0 && labels_loaded.join('|') === labels_saved.join('|'),
    `${labels_loaded.length} of ${labels_saved.length} objects back; says ` +
      `"${(await toastSays()).text}"`,
  );

  // Image: extension host takes, so PNG goes as itself.
  await page.evaluate(() => document.getElementById('button-export-png')?.click());
  await page.waitForFunction(
    () => (window as unknown as { host_stand_in: HostStandIn }).host_stand_in.saves.length > 1,
    null, { timeout: 10000 },
  ).catch(() => undefined);
  const image = (await saves())[1];
  const signature = (image?.bytes ?? []).slice(1, 4).map((byte) => String.fromCharCode(byte));
  report(
    'an image saves through the host as the PNG itself',
    image?.filename === 'rga_visualiser.png' && signature.join('') === 'PNG',
    image === undefined ? 'host was handed nothing' :
      `${image.filename}, ${image.bytes.length} bytes, opens ${signature.join('')}`,
  );

  // Reader's "no" is answer: page offers nothing else in its place.
  await page.evaluate(() => {
    (window as unknown as { host_stand_in: HostStandIn }).host_stand_in.answer = 'declined';
    document.getElementById('button-save-scene')?.click();
  });
  await page.waitForFunction(
    () => (window as unknown as { host_stand_in: HostStandIn }).host_stand_in.saves.length > 2,
    null, { timeout: 10000 },
  ).catch(() => undefined);
  await page.waitForTimeout(200);
  const said = await toastSays();
  report(
    'a save the reader declines on the host is not offered again by another route',
    (await saves()).length === 3 && said.text === 'Not saved.' && !said.is_link,
    `host handed ${(await saves()).length} saves; says "${said.text}", link ${said.is_link}`,
  );

  report('the page on the artifact host raised no error', errors.length === 0, errors.join(' | '));
  await page.close();
}
