/** Base URL for assets — works in Vite dev/build and raw GitHub Pages source deploy. */
export function getBaseUrl() {
  const env = import.meta.env;
  if (env && env.BASE_URL) {
    return env.BASE_URL;
  }
  const path = new URL(import.meta.url).pathname;
  const marker = '/src/';
  const idx = path.indexOf(marker);
  if (idx >= 0) {
    return path.slice(0, idx + 1);
  }
  return '/';
}

export function assetUrl(relativePath) {
  const base = getBaseUrl();
  const clean = relativePath.replace(/^\//, '');
  const env = import.meta.env;
  const isViteBuild = Boolean(env && env.PROD);
  if (isViteBuild) {
    return `${base}${clean}`;
  }
  if (clean.startsWith('assets/')) {
    return `${base}public/${clean}`;
  }
  return `${base}${clean}`;
}
