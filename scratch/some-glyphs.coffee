


############################################################################################################
PATH                      = require 'path'
# FS                        = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MK/TS/JIZURA/main'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
D                         = require 'pipedreams'
{ $
  $async }                = D
{ step }                  = require 'coffeenode-suspend'
#...........................................................................................................
mkts_opions               = require '../mingkwai-typesetter/options'
MKNCR                     = require '../mingkwai-ncr'

###
http://blogs.adobe.com/CCJKType/2014/01/gb-18030-oddity-or-design-flaw.html
###

text = """
  䏓 (U+43D3)  朊 (U+670A)
  䑃 (U+4443)  朦 (U+6726)
  肦 (U+80A6)  朌 (U+670C)
  胊 (U+80CA)  朐 (U+6710)
  胐 (U+80D0)  朏 (U+670F)
  脁 (U+8101)  朓 (U+6713)
  脧 (U+8127)  朘 (U+6718)
  膧 (U+81A7)  朣 (U+6723)
  """

input = D.new_stream { text, }
input
  .pipe D.$split()
  .pipe $ ( line, send ) ->
    match = line.match /// ^ \s* (\S+) \s+ \( ( [^)]+ ) \) \s+ (\S+) \s+ \( ( [^)]+ ) \) $///
    [ _, glyph_1, _, glyph_2, ] = match
    send [ glyph_1, glyph_2, ]
  .pipe $ ( [ glyph_1, glyph_2, ], send ) ->
    description_1 = MKNCR.describe glyph_1
    description_2 = MKNCR.describe glyph_2
    fncr_1        = description_1[ 'fncr' ]
    fncr_2        = description_2[ 'fncr' ]
    send [ glyph_1, fncr_1, glyph_2, fncr_2, ]
  .pipe D.$show()

input.resume()
debug '33200', MKNCR.describe '？'

###
(䏓|朊|䑃|朦|肦|朌|胊|朐|胐|朏|脁|朓|脧|朘|膧|朣)\t
###



