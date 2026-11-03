import { common, createLowlight } from 'lowlight'

export const lowlight = createLowlight(common)

const LABELS: Record<string, string> = {
  plaintext: 'Plain text',
  javascript: 'JavaScript',
  typescript: 'TypeScript',
  python: 'Python',
  bash: 'Bash',
  shell: 'Shell',
  json: 'JSON',
  xml: 'HTML / XML',
  css: 'CSS',
  scss: 'SCSS',
  sql: 'SQL',
  go: 'Go',
  rust: 'Rust',
  java: 'Java',
  kotlin: 'Kotlin',
  swift: 'Swift',
  c: 'C',
  cpp: 'C++',
  csharp: 'C#',
  php: 'PHP',
  ruby: 'Ruby',
  yaml: 'YAML',
  markdown: 'Markdown',
  diff: 'Diff',
  graphql: 'GraphQL',
  ini: 'INI / TOML',
  makefile: 'Makefile',
  lua: 'Lua',
  perl: 'Perl',
  r: 'R',
  objectivec: 'Objective-C',
  vbnet: 'VB.NET',
  wasm: 'WebAssembly',
  less: 'Less',
  'python-repl': 'Python REPL',
}

export const CODE_LANGUAGES = lowlight
  .listLanguages()
  .map((id) => ({ id, label: LABELS[id] ?? id }))
  .sort((a, b) => a.label.localeCompare(b.label))
