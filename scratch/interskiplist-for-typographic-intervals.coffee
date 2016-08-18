


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
tex_command_by_rsgs       = mkts_opions[ 'tex' ][ 'tex-command-by-rsgs' ]
glyph_styles              = mkts_opions[ 'tex' ][ 'glyph-styles'        ]


#-----------------------------------------------------------------------------------------------------------
@new_jizura_xncr = ->
  NCR = require 'ncr'
  #.........................................................................................................
  reducers =
    '*':          'assign'
    unicode_isl:  ( values ) -> NCR._ISL.copy NCR.unicode_isl
  #.........................................................................................................
  mix = ( require 'multimix' ).mix.use reducers
  return mix NCR, { _input_default: 'xncr', }

#-----------------------------------------------------------------------------------------------------------
@populate_isl = ( JZRXNCR, handler ) ->
  ### `isl`: Inter(val)SkipList; `JZRXNCR`: Jizura version of NCR module ###
  ISL = JZRXNCR._ISL
  #.........................................................................................................
  for rsg, block_command of tex_command_by_rsgs
    for entry in ISL.find_entries JZRXNCR.unicode_isl, 'rsg', rsg
      target            = entry[ 'tex' ] ?= {}
      target[ 'block' ] = block_style_as_tex block_command
  #.........................................................................................................
  for glyph, glyph_style of glyph_styles
    ### TAINT must resolve (X)NCRs ###
    cid             = JZRXNCR.as_cid glyph
    glyph_style_tex = glyph_style_as_tex glyph, glyph_style
    ISL.add JZRXNCR.unicode_isl, { lo: cid, hi: cid, tex: { codepoint: glyph_style_tex, }, }
  #.........................................................................................................
  @populate_isl_with_sims JZRXNCR, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@populate_isl_with_sims = ( JZRXNCR, handler ) ->
  ISL = JZRXNCR._ISL
  u   = JZRXNCR.unicode_isl
  #.........................................................................................................
  $filter_gaiji = =>
    return $ ( record, send ) =>
      { source_glyph_realm
        target_glyph_realm  } = record
      send record if ( source_glyph_realm is 'inner' ) and ( target_glyph_realm is 'inner' )
  #.........................................................................................................
  $add_intervals = =>
    return $ ( record, send ) =>
      { source_glyph
        target_glyph  } = record
      source_cid        = JZRXNCR.as_cid record[ 'source_glyph' ]
      target_cid        = JZRXNCR.as_cid record[ 'target_glyph' ]
      tag               = record[ 'tag' ]
      sim               = { tag, target_glyph, }
      ISL.add u, { lo: source_cid, hi: source_cid, sim, }
      sim               = { tag, source_glyph, }
      ISL.add u, { lo: target_cid, hi: target_cid, sim, }
  #.........................................................................................................
  $finalize = => $ 'finish', handler
  #.........................................................................................................
  step ( resume ) =>
    SIMS          = require '../../jizura-db-feeder/lib/feed-sims'
    ### TAINT should use `jizura-db-feeder` method ###
    S             = {}
    S.db          = null
    S.raw_output  = D.new_stream pipeline: [ $filter_gaiji(), $add_intervals(), $finalize() ]
    S.source_home = PATH.resolve __dirname, '../..',  'jizura-datasources/data/flat-files/'
    yield SIMS.feed S, resume
    handler()
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
block_style_as_tex = ( block_style ) -> "\\#{block_style}"

#-----------------------------------------------------------------------------------------------------------
glyph_style_as_tex = ( glyph, glyph_style ) ->
  ### NOTE this code replaces parts of `tex-writer-typofix._style_chr` ###
  #.........................................................................................................
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

#-----------------------------------------------------------------------------------------------------------
@demo = ( handler ) ->
  step ( resume ) =>
    JZRXNCR = @new_jizura_xncr()
    yield @populate_isl JZRXNCR, resume
    text  = '([Xqf]) ([里䊷䊷里]) ([Xqf])'
    # text  = 'q里䊷f'
    reducers  = { '*': 'skip', 'tag': 'tag', 'rsg': 'assign', }
    #.......................................................................................................
    reducers =
      '*':  'skip'
      tag:  'tag'
      rsg:  'assign'
      sim:  ( values, context ) ->
        ### TAINT should be a standard reducer ###
        R = {}
        for value in values
          for name, sub_value of value
            R[ name ] = sub_value
        return R
      tex:  ( values, context ) ->
        ### TAINT should be a standard reducer ###
        R = {}
        for value in values
          for name, sub_value of value
            R[ name ] = sub_value
        return R
    #.......................................................................................................
    aggregate = @_get_aggregate JZRXNCR, reducers
    #.......................................................................................................
    for glyph in Array.from '龵⿸釒𤴔'
      description = aggregate JZRXNCR.unicode_isl, glyph, reducers
      info glyph
      urge ' ', description[ 'tag' ].join ', '
      urge ' ', description[ 'rsg' ]
      urge ' ', description[ 'sim' ]                ? '-/-'
      urge ' ', description[ 'tex' ][ 'block'     ] ? '-/-'
      urge ' ', description[ 'tex' ][ 'codepoint' ] ? '-/-'
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@_get_aggregate = ( NCR, reducers ) ->
  cache = {}
  return ( glyph ) ->
    return R if ( R = cache[ glyph ] )?
    return cache[ glyph ] = NCR._ISL.aggregate NCR.unicode_isl, glyph, reducers


############################################################################################################
unless module.parent?
  @demo()

