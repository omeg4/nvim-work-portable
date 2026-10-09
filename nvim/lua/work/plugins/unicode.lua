return {
  -- NOTE: on first use, unicode.vim downloads UnicodeData.txt from https://www.unicode.org
  -- (via curl). Nothing is uploaded. The file is cached under stdpath('data').
  'chrisbra/unicode.vim',
  cmd = { "UnicodeSearch", "UnicodeName", "UnicodeTable", "Digraphs" },
  keys = { { "<F4>" } },
}
