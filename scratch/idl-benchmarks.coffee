



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
test                      = require 'guy-test'
{ step, }                 = require 'coffeenode-suspend'
#...........................................................................................................
D                         = require 'pipedreams'
{ $
  $async }                = D
#...........................................................................................................
require 'pipedreams/lib/plugin-tsv'
require 'pipedreams/lib/plugin-tabulate'
#...........................................................................................................
FLOWMATIC_IDL             = require '../../idlx'
{ IDL, IDLX, }            = require '../mojikura-idl'


#-----------------------------------------------------------------------------------------------------------
fetch_probes = ( handler ) ->
  path  = PATH.resolve __dirname, '../jizura-datasources/data/flat-files/shape/shape-breakdown-formula.txt'
  input = D.new_stream 'lines', { path, }
  D.tap input, 1 / 10, seed: 11, ( error, lines ) ->
    return handler error if error?
    for line, idx in lines
      fields        = line.split '\t'
      lines[ idx ]  = fields[ fields.length - 1 ]
    handler null, lines

#-----------------------------------------------------------------------------------------------------------
run = ( L, formulas ) ->
  count = formulas.length
  help "parsing #{count} formulas"
  t0 = +new Date()
  for formula in formulas
    try
      result = L.parse formula
      # help result
    catch error
      null
      # warn "#{formula}: #{error[ 'message' ]}"
  t1  = +new Date()
  dts = ( t1 - t0 ) / 1000
  help dts, count / dts

#-----------------------------------------------------------------------------------------------------------
main = ->
  step ( resume ) ->
    formulas = yield fetch_probes resume
    run IDLX, formulas
    run FLOWMATIC_IDL, formulas
    run IDL, formulas


############################################################################################################
unless module.parent?
  main()





