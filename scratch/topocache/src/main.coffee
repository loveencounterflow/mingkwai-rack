




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'TOPOCACHE/TESTS'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
LTSORT                    = require 'ltsort'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@new_graph = -> LTSORT.new_graph loners: no

#-----------------------------------------------------------------------------------------------------------
@add = ( me, precedent, consequent = null ) ->
  LTSORT.add me, precedent, consequent

