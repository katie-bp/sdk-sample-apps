/**
 * fix-import-meta-url.loader.js
 *
 * Custom webpack loader for @keyless/sdk-web-components index.js, wasm.js,
 * and pthreads/wasm.js.
 *
 * Problem 1 — dynamic import.meta access:
 *   The SDK uses obfuscated dynamic property access on import.meta:
 *     import.meta[someObfuscatedExpression]   // always resolves to 'url'
 *   webpack 5 can only statically replace import.meta.url (direct access).
 *   Dynamic access import.meta[expr] causes webpack to replace the entire
 *   import.meta object with ({}) — making import.meta.url === undefined.
 *   The SDK then calls new URL('./wasm.js', undefined) which throws TypeError.
 *   The SDK's anti-tamper layer catches that TypeError and fires RUNTIME_VIOLATION.
 *
 * Problem 2 — file:// base URL in CJS bundles:
 *   Even after rewriting import.meta[expr] -> import.meta.url, webpack replaces
 *   import.meta.url with "file://" + the absolute path of the source file in
 *   node_modules (e.g. "file:///Users/.../node_modules/@keyless/...wasm.js").
 *   This is webpack 5's correct behaviour for non-ESM output: import.meta.url
 *   is set to the source file's on-disk URL, not the served HTTP URL.
 *   The SDK uses this as a base to construct fetch URLs for wasm.wasm and
 *   wasm.data, producing file:// fetch requests that browsers block.
 *
 * Fix:
 *   Replace import.meta[expr] with a runtime expression that resolves to the
 *   HTTPS URL of the currently-loaded page (self.location.href). webpack never
 *   sees "import.meta" at all, so it cannot substitute file://.
 *
 *   At runtime: self.location.href = "https://localhost:8443/"
 *   SDK then computes: new URL('./', "https://localhost:8443/") = "https://localhost:8443/"
 *   And fetches: "https://localhost:8443/wasm.wasm" and "https://localhost:8443/wasm.data"
 *
 *   For this to work, wasm.wasm and wasm.data must be served at those paths.
 *   CopyWebpackPlugin in webpack.config.js copies them from node_modules to public/.
 */
module.exports = function fixImportMetaUrlLoader(source) {
  // Replace every import.meta[expr] with a runtime self.location.href expression.
  // Using self (rather than window) makes this safe in both window and Worker contexts.
  // The fallback to import.meta.url covers SSR/Node environments where self.location
  // is unavailable.
  return source.replace(
    /import\.meta\[[^\]]+\]/g,
    "(typeof self !== 'undefined' && self.location ? self.location.href : import.meta.url)",
  );
};
