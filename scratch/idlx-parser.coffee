


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SHUNTING-YARD'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
NCR                       = require 'ncr'
#...........................................................................................................
D                         = require 'pipedreams'
{ $
  $async }                = D
{ step }                  = require 'coffeenode-suspend'
#...........................................................................................................
mkts_opions               = require '../mingkwai-typesetter/lib/options'
# MD_READER                 = require '../mingkwai-typesetter/lib/md-reader'
# hide                      = MD_READER.hide.bind        MD_READER
# copy                      = MD_READER.copy.bind        MD_READER
# stamp                     = MD_READER.stamp.bind       MD_READER
# select                    = MD_READER.select.bind      MD_READER
# is_hidden                 = MD_READER.is_hidden.bind   MD_READER
# is_stamped                = MD_READER.is_stamped.bind  MD_READER
#...........................................................................................................
MKNCR                     = require '../../mingkwai-ncr'
Σ_glyph_description       = Symbol 'glyph-description'




#===========================================================================================================
# SPLITTING, WRAPPING, UNWRAPPING
#-----------------------------------------------------------------------------------------------------------
@$split = ( S ) ->
  return $ ( event, send ) =>
    return send event unless select event, '.', 'text'
    [ type, name, text, meta, ] = event
    for glyph in MKNCR.chrs_from_text text
      send [ '.', Σ_glyph_description, glyph, meta, ]
    return null

#-----------------------------------------------------------------------------------------------------------
@$wrap_as_glyph_description = ( S ) ->
  return $ ( event, send ) =>
    return send event unless select event, '.', Σ_glyph_description
    [ type, name, glyph, meta, ] = event
    description = MKNCR.describe glyph
    { csg, }    = description
    if csg in [ 'u', 'jzr', ]
      send [ type, name, description, meta, ]
    else
      ### NOTE In case the CSG is not an 'inner' one (either Unicode or Jizura), the glyph can only
      have been represented as an extended NCR (a string like `&morohashi#x12ab;`). In that case,
      we send all the constituent US-ASCII glyphs separately so the NCR will be rendered literally. ###
      for sub_glyph in Array.from glyph
        send [ type, name, ( MKNCR.describe sub_glyph ), meta, ]
    return null

#-----------------------------------------------------------------------------------------------------------
@$unwrap_glyph_description = ( S ) ->
  return $ ( event, send ) =>
    return send event unless select event, '.', Σ_glyph_description
    [ type, name, description, meta, ] = event
    # debug '70333', description
    glyph = description[ 'uchr' ]
    ### TAINT send `tex` or `text` event? ###
    send [ 'tex', glyph, ]
    return null



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$fix_typography_for_tex = ( S ) ->
  pipeline = [
    @$split                     S
    @$wrap_as_glyph_description S
    # @$format_cjk                S
    # @$format_tex_specials       S
    @$unwrap_glyph_description  S
    D.$show()
    ]
  return D.new_stream { pipeline, }




