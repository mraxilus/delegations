// Handing file to reader, over routes platforms differ on; not Nim because these reach browser APIs
//   Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Handing file to reader.                                                */
/*                                                                        */
/* One route for scene file and image alike. It used to be five           */
/* statements written out twice -- build Blob, make `<a download>`,       */
/* click it -- with anchor never put in document. Detached                */
/* anchor's synthetic click is ignored by Safari outright and is          */
/* unreliable elsewhere, so saving anything from phone did nothing at     */
/* all, while caller toasted "Saved" regardless. Both halves of that      */
/* are fixed here: routes below are tried in order of how likely          */
/* platform is to honour them, and nothing claims file was written.       */
/* ---------------------------------------------------------------------- */

// What last delivery attempt tried and what came back, kept for reader to read.
//   Three rounds of this fault were spent guessing because every refusal was silent:
//   share sheet failed with its reason swallowed, and download frame refuses raises no
//   event at all. Page that cannot say what happened cannot be debugged from phone
//   nobody here can reach, so outcomes are recorded rather than inferred.
// Route-by-route account of one delivery, shown when every automatic route failed.
let report_delivery: string[] = [];

function describeEnvironment() {
  // Read at delivery time, not at load: transient activation is whole question for.
  //   share route and is only meaningful during gesture that asked.
  const policy = (document as Document & {
    featurePolicy?: { allowsFeature(name: string): boolean };
  }).featurePolicy;
  const share_allowed = policy === undefined ? 'unknown'
    : String(policy.allowsFeature('web-share'));
  return [
    'framed: ' + (window.self !== window.top),
    'origin: ' + (window.origin === 'null' ? 'opaque' : 'own'),
    'share api: ' + (navigator.share === undefined ? 'absent' : 'present'),
    'web-share: ' + share_allowed,
    'activation: ' + (navigator.userActivation === undefined ? 'unknown'
      : String(navigator.userActivation.isActive)),
  ];
}

async function shareFile(file: File, filename: string): Promise<boolean> {
  // `canShare` is preference, never precondition, and this is second time that.
  //   distinction has cost route: gating on it skipped `share` outright, first on any
  //   platform shipping one without other, then -- once that was fixed but `false`
  //   still returned early -- on frame where `canShare` says no for reason that is not
  //   platform's to give. So `false` is *reported* and attempt made anyway; only
  //   missing `share` is grounds not to try.
  if (navigator.share === undefined) {
    report_delivery.push('share: no api');
    return false;
  }
  if (navigator.canShare !== undefined && !navigator.canShare({ files: [file] })) {
    report_delivery.push('share: files no');
  }
  try {
    await navigator.share({ files: [file], title: filename });
    report_delivery.push('share: opened');
    return true;
  } catch (err) {
    // Cancelling sheet is decision, not failure -- report it and stop trying.
    if (err instanceof Error && err.name === 'AbortError') {
      report_delivery.push('share: cancelled');
      return true;
    }
    report_delivery.push('share: ' + (err instanceof Error ? err.name : 'failed'));
    return false;
  }
}

async function deliverFile(
  blob: Blob, filename: string, mime: string, described: string,
) {
  report_delivery = describeEnvironment();
  const file = new File([blob], filename, { type: mime });

  // 1. Share sheet, where platform has one. Route that actually works on.
  //    phone, and only one that does not care whether this frame may download. Both
  //    callers run inside click, so transient activation it needs is present -- see
  //    `captureFrameIfAsked` on what it cost to make that true of image too.
  if (await shareFile(file, filename)) {
    if (report_delivery[report_delivery.length - 1] === 'share: opened') {
      toast('Shared `' + filename + '`.');
    }
    return;
  }

  const url = URL.createObjectURL(blob);
  // 2. Real anchor, in document.
  //    Appending is whole of original fix; click on element that is not in page is what
  //    browsers were discarding.
  //    Measured in frame granted `allow-downloads`: this fires real download, and so
  //    does reader's own tap on route 4; neither does in frame without it, in silence.
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  report_delivery.push('download: no signal');

  // 3. Tab of its own, which frame that refuses download may still permit. Expected to.
  //    fail from sandbox, since `blob:` URL minted in opaque origin resolves nowhere
  //    else -- but `null` return says "blocked" out loud, which is one more thing
  //    reader's report can rule out rather than leave open.
  if (window.self !== window.top) {
    const opened = window.open(url, '_blank');
    report_delivery.push('new tab: ' + (opened === null ? 'blocked' : 'opened'));
  }

  // 4. Link to tap, always. There is no event for `the download was refused` -- framed.
  //    page whose host withholds `allow-downloads` gets silence -- so rather than guess
  //    which happened, leave reader route they drive themselves. Framed is case
  //    that needs it and case this page ships in; unframed it is harmless second way.
  //    Image goes on screen with it, which refused frame cannot take away.
  if (window.self !== window.top) {
    report_delivery.push('link: offered');
    toastWithLink(
      described + ' is ready.', url, filename, 'save ' + filename,
      mime.startsWith('image/') ? url : undefined,
    );
  } else {
    toast('Handed `' + filename + '` to the browser to download.');
    // Long enough for navigation to have started, and for tap on link above.
    setTimeout(() => URL.revokeObjectURL(url), 60000);
    return;
  }
  // Held far longer than old four seconds, since link is reader's to use.
  setTimeout(() => URL.revokeObjectURL(url), 600000);
}
