


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
MKNCR                     = require '../mingkwai-ncr'
ISL                       = MKNCR._ISL
u                         = MKNCR.unicode_isl

#-----------------------------------------------------------------------------------------------------------
@entries_from_tag = ( tag ) -> ISL.find_entries u, 'tag', tag

#-----------------------------------------------------------------------------------------------------------
@descriptions_from_tag = ( tag ) ->
  R = []
  for entry in ISL.find_entries u, 'tag', tag
    { lo, hi, } = entry
    for cid in [ lo .. hi ]
      R.push MKNCR.describe cid
  return R

    # #.......................................................................................................
    # # text  = '([Xqf]) ([里䊷䊷里]) ([Xqf])'
    # # # text  = 'q里䊷f'
    # for glyph in Array.from '龵⿸釒金𤴔丨亅㐅乂'
    #   description = aggregate glyph
    #   info glyph
    #   urge '  tag:', ( description[ 'tag' ] ? [ '-/-' ] ).join ', '
    #   urge '  rsg:', description[ 'rsg' ]
    #   # if ( sim = description[ 'sim' ] )?
    #   #   for sim_tag, value of sim
    #   #     urge "  sim:#{sim_tag}: #{rpr value}"
    #   # else
    #   #   urge '  sim:', '-/-'
    #   for sim_tag in sim_tags
    #     continue unless ( value = description[ sim_tag ] )?
    #     urge "  #{sim_tag}:", value
    #   urge '  blk:', description[ 'tex' ][ 'block'     ] ? '-/-'
    #   urge '  cp: ', description[ 'tex' ][ 'codepoint' ] ? '-/-'
    # #.......................................................................................................
    # # tag = 'sim/is-target/global'
    # tags = [
    #   'global'
    #   'components'
    #   'components/search'
    #   'false-identity'
    #   ]
    # for tag in tags
    #   echo tag
    #   search_tag  = "sim/is-target/#{tag}"
    #   entry_tag   = "sim/source/#{tag}"
    #   for entry in JZRXNCR._ISL.find_entries JZRXNCR.unicode_isl, 'tag', search_tag
    #     ### Silently assuming that all relevant entries represent single-character intervals ###
    #     target_glyph_info = JZRXNCR.analyze ( cid = entry[ 'lo' ] )
    #     target_glyph      = target_glyph_info[ 'uchr' ]
    #     target_fncr       = target_glyph_info[ 'fncr' ]
    #     source_glyph      = entry[ entry_tag ]
    #     source_glyph_info = JZRXNCR.analyze source_glyph
    #     source_fncr       = source_glyph_info[ 'fncr' ]
    #     echo target_fncr, target_glyph, '<-', source_fncr, source_glyph

#-----------------------------------------------------------------------------------------------------------
show_rsgs = ->
  rsgs = new Set()
  for nfo in @descriptions_from_tag 'sim/is-source/global'
    { rsg, } = nfo
    rsgs.add rsg
  debug rsgs

############################################################################################################
unless module.parent?
  skip_rsgs   = [
    'u-cjk-cmpi1'
    'u-cjk-cmpi2'
    'u-cjk-rad1'
    'u-cjk-rad2'
    'u-cjk-strk'
    'u-pua'
    ]
  skip_rsgs   = new Set skip_rsgs
  count_all   = 0
  count_shown = 0
  for nfo in @descriptions_from_tag 'sim/is-source/global'
    count_all        += +1
    { rsg, fncr, }    = nfo
    glyph             = nfo[ 'uchr' ]
    continue if skip_rsgs.has rsg
    count_shown      += +1
    target_glyphs     = nfo[ 'sim/target/global' ]
    throw new Error '### !!! ###' unless target_glyphs.length is 1
    [ target_glyph, ] = target_glyphs
    target_nfo        = MKNCR.describe target_glyph
    target_fncr       = target_nfo[ 'fncr' ]
    # help JSON.stringify nfo
    help "#{fncr} #{glyph} => #{target_fncr} #{target_glyph}"
  info count_all, count_shown

