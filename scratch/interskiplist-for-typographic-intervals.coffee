


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
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
mkts_opions               = require '../mingkwai-typesetter/options'
tex_command_by_rsgs       = mkts_opions[ 'tex' ][ 'tex-command-by-rsgs' ]
glyph_styles              = mkts_opions[ 'tex' ][ 'glyph-styles'        ]


#-----------------------------------------------------------------------------------------------------------
new_jizura_xncr = ->
  NCR = require 'ncr'
  #.........................................................................................................
  reducers =
    '*':          'assign'
    unicode_isl:  ( values ) -> NCR._ISL.copy NCR.unicode_isl
  #.........................................................................................................
  mix   = ( require 'multimix' ).mix.use reducers
  R     = mix NCR, { _input_default: 'xncr', }
  ISL   = R._ISL
  #.........................................................................................................
  for rsg, tex_command of tex_command_by_rsgs
    for entry in ISL.find_entries R.unicode_isl, 'rsg', rsg
      ( entry[ 'tex' ] ?= {} )[ 'block' ] = tex_command
  #.........................................................................................................
  for glyph, glyph_style of glyph_styles
    ### TAINT must resolve (X)NCRs ###
    cid = R.as_cid glyph
    ISL.add R.unicode_isl, { lo: cid, hi: cid, tex: { codepoint: glyph_style, }, }
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
f = ->
  cache = {}
  aggregate = ( glyph ) ->
    return R if ( R = cache[ glyph ] )?
    return cache[ glyph ] = ISL.aggregate u, glyph, reducers

  for glyph in Array.from text
    urge glyph, aggregate glyph


############################################################################################################
unless module.parent?
  text  = '([Xqf]) ([里䊷䊷里]) ([Xqf])'
  # text  = 'q里䊷f'
  reducers  = { '*': 'skip', 'tag': 'tag', 'rsg': 'assign', }
  XNCR = new_jizura_xncr()
  reducers =
    '*':  'skip'
    tag:  'tag'
    rsg:  'assign'
    tex:  ( ids_and_values ) ->
      ### TAINT should be a standard reducer ###
      R = {}
      for [ id, value, ] in ids_and_values
        for name, sub_value of value
          R[ name ] = sub_value
      return R
  help '8830', XNCR._ISL.aggregate XNCR.unicode_isl, '龵', reducers
  help '8830', XNCR._ISL.aggregate XNCR.unicode_isl, '⿸', reducers
  urge '8830', XNCR._ISL.aggregate XNCR.unicode_isl, '龵', reducers
  urge '8830', XNCR._ISL.aggregate XNCR.unicode_isl, '⿸', reducers
  # f()
  # debug u

