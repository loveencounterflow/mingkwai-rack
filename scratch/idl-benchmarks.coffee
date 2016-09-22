



############################################################################################################
PATH                      = require 'path'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MOJIKURA-IDL/benchmarks'
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
FLOWMATIC_IDL             = require '../../idlx'
debug FLOWMATIC_IDL.parse '⿰言(⿱⿰大大一日)'
# test                      = require 'guy-test'
# { IDL, IDLX, }            = require '../mojikura-idl'
# #...........................................................................................................
# D                         = require 'pipedreams'
# { $
#   $async }                = D
# #...........................................................................................................
# require 'pipedreams/lib/plugin-tsv'
# require 'pipedreams/lib/plugin-tabulate'


path  = PATH.resolve __dirname, '../jizura-datasources/data/flat-files/shape/shape-breakdown-formula.txt'
input = D.new_stream 'lines', { path, }
D.tap input, 1 / 10000, seed: 11, ( error, lines ) ->
  for line, idx in lines
    fields        = line.split '\t'
    lines[ idx ]  = fields[ fields.length - 1 ]
  for formula in lines
    try
      help IDLX.parse formula
    catch error
      warn "#{formula}: #{error[ 'message' ]}"


