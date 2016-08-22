


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
  @_populate_isl_with_sims JZRXNCR, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@_populate_isl_with_sims = ( JZRXNCR, handler ) ->
  ISL = JZRXNCR._ISL
  u   = JZRXNCR.unicode_isl
  #.........................................................................................................
  $add_intervals = ( S ) =>
    return $ ( record ) =>
      { source_glyph
        target_glyph  } = record
      # debug '3334', record
      source_cid        = JZRXNCR.as_cid record[ 'source_glyph' ]
      target_cid        = JZRXNCR.as_cid record[ 'target_glyph' ]
      otag              = record[ 'tag' ]
      mtag              = "sim/target/#{otag}"
      ctag              = "sim sim/has-target sim/is-source sim/has-target/#{otag} sim/is-source/#{otag} sim/#{otag}"
      # sim               = { "#{otag}": { target: target_glyph, }, }
      ISL.add u, { lo: source_cid, hi: source_cid, "#{mtag}": target_glyph, tag: ctag, }
      mtag              = "sim/source/#{otag}"
      ctag              = "sim sim/has-source sim/is-target sim/has-source/#{otag} sim/is-target/#{otag} sim/#{otag}"
      # sim               = { "#{otag}": { source: source_glyph, }, }
      ISL.add u, { lo: target_cid, hi: target_cid, "#{mtag}": source_glyph, tag: ctag, }
      return null
  #.........................................................................................................
  $collect_tags = ( S ) =>
    tags = new Set
    return $ 'null', ( record ) =>
      if record? then tags.add record[ 'tag' ]
      else debug '3334', tags
      return null
  #.........................................................................................................
  SIMS          = require '../jizura-db-feeder/lib/feed-sims'
  ### TAINT should use `jizura-db-feeder` method ###
  S             = {}
  S.db          = null
  S.source_home = PATH.resolve __dirname, '../..',  'jizura-datasources/data/flat-files/'
  input         = SIMS.new_sim_readstream S, filter: yes
  #.........................................................................................................
  input
    .pipe $add_intervals S
    .pipe $ 'finish', handler
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
    ### TAINT tags should be collected during SIM reading ###
    sim_tags = [
      'sim/source/global'
      'sim/source/components'
      'sim/source/components/search'
      'sim/source/false-identity'
      'sim/target/global'
      'sim/target/components'
      'sim/target/components/search'
      'sim/target/false-identity'
      ]
    #.......................................................................................................
    reducers =
      '*':  'skip'
      tag:  'tag'
      rsg:  'assign'
      # sim:  ( values, context ) ->
      #   ### TAINT should be a standard reducer ###
      #   debug '7701', values
      #   R = {}
      #   for value in values
      #     for name, sub_value of value
      #       R[ name ] = sub_value
      #   return R
      tex:  ( values, context ) ->
        ### TAINT should be a standard reducer ###
        R = {}
        for value in values
          for name, sub_value of value
            R[ name ] = sub_value
        return R
    #.......................................................................................................
    reducers[ sim_tag ] = 'list' for sim_tag in sim_tags
    aggregate           = @_get_aggregate JZRXNCR, reducers
    #.......................................................................................................
    # text  = '([Xqf]) ([里䊷䊷里]) ([Xqf])'
    # # text  = 'q里䊷f'
    for glyph in Array.from '龵⿸釒金𤴔丨亅㐅乂'
      description = aggregate glyph
      info glyph
      urge '  tag:', ( description[ 'tag' ] ? [ '-/-' ] ).join ', '
      urge '  rsg:', description[ 'rsg' ]
      # if ( sim = description[ 'sim' ] )?
      #   for sim_tag, value of sim
      #     urge "  sim:#{sim_tag}: #{rpr value}"
      # else
      #   urge '  sim:', '-/-'
      for sim_tag in sim_tags
        continue unless ( value = description[ sim_tag ] )?
        urge "  #{sim_tag}:", value
      urge '  blk:', description[ 'tex' ][ 'block'     ] ? '-/-'
      urge '  cp: ', description[ 'tex' ][ 'codepoint' ] ? '-/-'
    #.......................................................................................................
    # tag = 'sim/is-target/global'
    tags = [
      'global'
      'components'
      'components/search'
      'false-identity'
      ]
    for tag in tags
      echo tag
      search_tag  = "sim/is-target/#{tag}"
      entry_tag   = "sim/source/#{tag}"
      for entry in JZRXNCR._ISL.find_entries JZRXNCR.unicode_isl, 'tag', search_tag
        ### Silently assuming that all relevant entries represent single-character intervals ###
        target_glyph_info = JZRXNCR.analyze ( cid = entry[ 'lo' ] )
        target_glyph      = target_glyph_info[ 'uchr' ]
        target_fncr       = target_glyph_info[ 'fncr' ]
        source_glyph      = entry[ entry_tag ]
        source_glyph_info = JZRXNCR.analyze source_glyph
        source_fncr       = source_glyph_info[ 'fncr' ]
        echo target_fncr, target_glyph, '<-', source_fncr, source_glyph
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@_get_aggregate = ( ncr, reducers ) ->
  cache = {}
  return ( glyph ) =>
    return R if ( R = cache[ glyph ] )?
    return cache[ glyph ] = ncr._ISL.aggregate ncr.unicode_isl, glyph, reducers


############################################################################################################
unless module.parent?
  # @demo()
  NCR = require 'ncr'
  isl = NCR._ISL.new()
  NCR._ISL.add_index isl, 'tag'
  NCR._ISL.add isl, { lo: 'a', hi: 'c', }
  urge isl
  help {
    'index-keys': ( key for key of isl[ 'indexes' ] )
    'entries':    ( entry for _, entry of isl[ 'entry-by-ids' ] )
    }




