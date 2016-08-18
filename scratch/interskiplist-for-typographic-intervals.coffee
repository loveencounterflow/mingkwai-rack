


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
      target            = entry[ 'tex' ] ?= {}
      target[ 'block' ] = tex_command
  #.........................................................................................................
  for glyph, glyph_style of glyph_styles
    ### TAINT must resolve (X)NCRs ###
    cid             = R.as_cid glyph
    glyph_style_tex = glyph_style_as_tex glyph, glyph_style
    ISL.add R.unicode_isl, { lo: cid, hi: cid, tex: { codepoint: glyph_style_tex, }, }
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

#-----------------------------------------------------------------------------------------------------------
glyph_style_as_tex = ( glyph, glyph_style ) ->
  ### TAINT using `prPushRaise` here in place of `tfPushRaise` because it gives better
  results ###
  use_cxltx_pushraise = no
  #.........................................................................................................
  R         = []
  R.push "{"
  # R.push "\\cn" if is_cjk
  rpl_push  = glyph_style[ 'push'   ] ? null
  rpl_raise = glyph_style[ 'raise'  ] ? null
  rpl_chr   = glyph_style[ 'glyph'  ] ? glyph
  rpl_cmd   = glyph_style[ 'cmd'    ] ? null
  # rpl_cmd   = glyph_style[ 'cmd'    ] ? rsg_command
  # rpl_cmd   = null if rpl_cmd is 'cn'
  #.........................................................................................................
  if use_cxltx_pushraise
    if      rpl_push? and rpl_raise?  then R.push "\\prPushRaise{#{rpl_push}}{#{rpl_raise}}{"
    else if rpl_push?                 then R.push "\\prPush{#{rpl_push}}{"
    else if               rpl_raise?  then R.push "\\prRaise{#{rpl_raise}}{"
  #.........................................................................................................
  else
    if      rpl_push? and rpl_raise?  then R.push "\\tfPushRaise{#{rpl_push}}{#{rpl_raise}}"
    else if rpl_push?                 then R.push "\\tfPush{#{rpl_push}}"
    else if               rpl_raise?  then R.push "\\tfRaise{#{rpl_raise}}"
  #.........................................................................................................
  if rpl_cmd?                       then R.push "\\#{rpl_cmd}{}"
  R.push rpl_chr
  R.push "}" if use_cxltx_pushraise and ( rpl_push? or rpl_raise? )
  R.push "}"
  R = R.join ''
  return R


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
    tex:  ( values, context ) ->
      ### TAINT should be a standard reducer ###
      R = {}
      for value in values
        for name, sub_value of value
          R[ name ] = sub_value
      return R
  for glyph in Array.from '龵⿸釒𤴔'
    description = XNCR._ISL.aggregate XNCR.unicode_isl, glyph, reducers
    info glyph
    urge ' ', description[ 'tag' ].join ', '
    urge ' ', description[ 'rsg' ]
    urge ' ', description[ 'tex' ][ 'block' ] ? './.'
    urge ' ', description[ 'tex' ][ 'codepoint' ] ? './.'
  # f()
  # debug u




