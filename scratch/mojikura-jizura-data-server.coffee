


############################################################################################################
PATH                      = require 'path'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MOJIKURA'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
ƒ                         = CND.format_number.bind CND
#...........................................................................................................
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
#...........................................................................................................
D                         = require 'pipedreams'
{ $
  $async }                = D
#...........................................................................................................
require 'pipedreams/lib/plugin-tsv'
require 'pipedreams/lib/plugin-tabulate'
#...........................................................................................................
# HOLLERITH                 = require 'hollerith'
# MKNCR                     = require '../../mingkwai-ncr'
NCR                       = require 'ncr'


#-----------------------------------------------------------------------------------------------------------
@new_sim_readstream = ( S, settings ) ->
  R         = D.$pass()
  settings ?= {}
  #.........................................................................................................
  ### TAINT experimental ###
  if false # settings[ 'filter' ] is true
    $filter_gaiji = ( S ) =>
      return $ ( record, send ) =>
        return unless record[ 'source_glyph_realm' ] is 'inner'
        return unless record[ 'target_glyph_realm' ] is 'inner'
        # debug '9071', record[ 'source_glyph' ], record[ 'target_glyph' ]
        send record
  else
    $filter_gaiji = ( S ) => D.$pass()
  #.........................................................................................................
  input = D.new_stream { path: S.sim.source_path, }
  input
  #.........................................................................................................
    .pipe D.$split_tsv { names: [ 'target_fncr', 'target_glyph', 'source_fncr', 'source_glyph', ], }
    .pipe D.$benchmark "JIZURA-DB-FEEDER/feed-sims/input"
    .pipe D.$show()
    # .pipe @$split_tag                       S
    # .pipe @$mark_glyph_realms               S
    # .pipe $filter_gaiji                     S
    # .pipe U.$cast_source_and_target_glyphs  S
    # .pipe @$show_statistics                 S
    # .pipe D.$benchmark "JIZURA-DB-FEEDER/feed-sims/output"
    .pipe R
  #.........................................................................................................
  # return D.new_stream { pipeline, }
  return R


############################################################################################################
unless module.parent?
  ### TAINT paths should come from common configuration source (?) ###
  S =
    sim:
      source_path: PATH.resolve __dirname, '../jizura-datasources/data/flat-files/shape/shape-similarity-identity.txt'
  reader = @new_sim_readstream S
  reader
    .pipe D.$show()




