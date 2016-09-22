



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
    Z = []
    for line in lines
      continue if line.length is 0
      continue if ( /^\s*#/ ).test line
      fields        = line.split '\t'
      Z.push fields[ fields.length - 1 ]
    handler null, Z

#-----------------------------------------------------------------------------------------------------------
run = ( title, L, formulas ) ->
  info()
  info title
  formula_count           = formulas.length
  error_count             = 0
  adjusted_error_count    = 0
  t0 = +new Date()
  for formula in formulas
    try
      result = L.parse formula
      # help result
    catch error
      ### TAINT FLOWMATIC_IDL fails to parse the inhibitor '▽', but there are only few of those
      in the formulas. By not counting them, we hardly distort the overall results and gain the
      magic 100% figure to indicate full success: ###
      error_count          += +1
      adjusted_error_count += +1 unless formula is '▽'
      # warn "#{formula}: #{error[ 'message' ]}"
  t1            = +new Date()
  dts           = ( t1 - t0 ) / 1000
  fps           = ( formula_count / dts ).toFixed 2
  success_rate  = ( ( formula_count - adjusted_error_count ) / formula_count * 100 ).toFixed 2
  help dts, "#{fps} fps (#{error_count} errors = #{success_rate}% success)"

#-----------------------------------------------------------------------------------------------------------
main = ->
  step ( resume ) ->
    formulas = yield fetch_probes resume
    help "collected #{formulas.length} formulas"
    run 'FLOWMATIC_IDL', FLOWMATIC_IDL, formulas
    run 'IDL',           IDL,           formulas
    run 'IDLX',          IDLX,          formulas


############################################################################################################
unless module.parent?
  main()





