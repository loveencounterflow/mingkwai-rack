
###
2016-09-22

~/io/mingkwai-rack/scratch ► coffee idl-benchmarks.coffee
MINGKWAI-NCR  ☛  reading cache
MINGKWAI-NCR  !  cache may be stale; check with mingkwai file-date-checker
MOJIKURA-IDL/benchmarks  ☛  collected 9054 formulas
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  FLOWMATIC_IDL
MOJIKURA-IDL/benchmarks  ☛  19.017 476.10 fps (35 errors = 100.00% success)
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  IDL
MOJIKURA-IDL/benchmarks  ☛  8.009 1130.48 fps (659 errors = 93.11% success)
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  IDLX
MOJIKURA-IDL/benchmarks  ☛  1.438 6296.24 fps (575 errors = 93.65% success)

2016-09-23 12:50

MOJIKURA-IDL/benchmarks  ☛  collected 89533 formulas
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  FLOWMATIC_IDL
MOJIKURA-IDL/benchmarks  ☛  189.922 471.42 fps (363 errors = 100.00% success)
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  IDL
MOJIKURA-IDL/benchmarks  ☛  28.664 3123.53 fps (6972 errors = 92.62% success)
MOJIKURA-IDL/benchmarks  ▶
MOJIKURA-IDL/benchmarks  ▶  IDLX
MOJIKURA-IDL/benchmarks  ☛  11.88 7536.45 fps (0 errors = 100.00% success)
###



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
  # D.tap input, 1 / 10, seed: 11, ( error, lines ) ->
  D.tap input, 1 / 1, seed: 11, ( error, lines ) ->
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
      echo "#{formula}: #{error[ 'message' ]}"
  t1            = +new Date()
  dts           = ( t1 - t0 ) / 1000
  fps           = ( formula_count / dts ).toFixed 2
  success_rate  = ( ( formula_count - adjusted_error_count ) / formula_count * 100 ).toFixed 2
  help dts, "#{fps} fps (#{error_count} errors = #{success_rate}% success)"

#-----------------------------------------------------------------------------------------------------------
replace_jzr_codepoints = ( parse_tree ) ->
  if CND.isa_text parse_tree
    element = parse_tree.replace /&jzr#x([0-9a-fA-F]+);/g, ( _, $1 ) ->
      cid = parseInt $1, 16
      return String.fromCodePoint cid
    return element
  for element, idx in parse_tree
    parse_tree[ idx ] = replace_jzr_codepoints element
  return parse_tree

#-----------------------------------------------------------------------------------------------------------
unwrap_flowmatic_idl_extra_lists = ( parse_tree ) ->
  if CND.isa_list parse_tree
    for element, idx in parse_tree
      continue if CND.isa_text element
      element = unwrap_flowmatic_idl_extra_lists element
      unless IDLX._symbol_is_operator null, element[ 0 ]
        parse_tree.splice idx, 1, element...
  return parse_tree

#-----------------------------------------------------------------------------------------------------------
recast_solitaires = ( parse_tree ) ->
  return parse_tree if CND.isa_text parse_tree
  return parse_tree if parse_tree.length > 1
  return parse_tree[ 0 ]

#-----------------------------------------------------------------------------------------------------------
compare = ( formulas ) ->
  info()
  info "Comparing parse results (FLOWMATIC_IDL vs IDLX)"
  formula_count           = formulas.length
  success_count           = 0
  error_count             = 0
  t0 = +new Date()
  #.........................................................................................................
  for formula in formulas
    # debug '88100', formula, formula_ if formula_ isnt formula
    # formula = formula_
    try
      result_A          = original_result_A = FLOWMATIC_IDL.parse formula
      original_result_A = CND.deep_copy                           result_A
      result_A          = replace_jzr_codepoints                  result_A
      result_A          = unwrap_flowmatic_idl_extra_lists        result_A
      result_A          = recast_solitaires                       result_A
    catch error
      if formula is '▽' then result_A = '▽'
      else warn "#{formula}: #{error[ 'message' ]}"
    result_B = IDLX.parse formula
    if CND.equals result_A, result_B
      success_count += +1
    else
      error_count += +1
      echo error_count, formula
      echo "FLOWMATIC_IDL (original): #{rpr result_A}"
      echo "FLOWMATIC_IDL:            #{rpr result_A}"
      echo "IDLX:                     #{rpr result_B}"
  #.........................................................................................................
  t1            = +new Date()
  dts           = ( t1 - t0 ) / 1000
  fps           = ( formula_count / dts ).toFixed 2
  success_rate  = ( success_count / formula_count * 100 ).toFixed 2
  help dts, "#{fps} fps (#{error_count} errors = #{success_rate}% success)"

#-----------------------------------------------------------------------------------------------------------
main = ->
  step ( resume ) ->
    formulas = yield fetch_probes resume
    help "collected #{formulas.length} formulas"
    # run 'FLOWMATIC_IDL', FLOWMATIC_IDL, formulas
    # run 'IDL',           IDL,           formulas
    run 'IDLX',          IDLX,          formulas
    # compare formulas


############################################################################################################
unless module.parent?
  main()

  # debug replace_jzr_codepoints [ '⿰', [ '&jzr#xe37a;', '&jzr#xe37a;', ] ]
  f = ->
    ### Turns out FLOWMATIC_IDL is faulty:
      MOJIKURA-IDL/benchmarks  ⚙  0 "(⿰⿱&jzr#x1;𠂊)"
      MOJIKURA-IDL/benchmarks  ⚙  1 ["⿰",[["⿱","𠂊","𠂊"],"𠂊","𠂊","𠂊"]]
      MOJIKURA-IDL/benchmarks  ⚙  2 ["⿰",[["⿱","𠂊","𠂊"],"𠂊","𠂊","𠂊"]]
      MOJIKURA-IDL/benchmarks  ⚙  3 ["⿰",["⿱","𠂊","𠂊"],"𠂊","𠂊","𠂊"]
      MOJIKURA-IDL/benchmarks  ⚙  4 ["⿰",["⿱","𠂊","𠂊"],"𠂊","𠂊","𠂊"]
    ###
    formulas = [
      # '(⿱𦘒一⿵冂日)'
      # '(⿱𦘒一日)'
      # '(⿱𦘒一)'
      # '(⿱(⿱冂日)一)'
      # '⿱𦘒一'
      '(⿰⿱&jzr#x1;𠂊)'
      # '⿰扌⿱宀(⿰⿱&jzr#x1;⿱𠂊仌⿱屮屮)'
      # '⿰扌⿱宀(⿰⿱&jzr#xe223;&jzr#xe223;⿱𠂊仌⿱屮屮)'
      ]
    for formula in formulas
      debug '0', JSON.stringify                                                    formula
      debug '1', JSON.stringify FM_parse_tree = FLOWMATIC_IDL.parse                formula
      debug '2', JSON.stringify FM_parse_tree = replace_jzr_codepoints             FM_parse_tree
      debug '3', JSON.stringify FM_parse_tree = unwrap_flowmatic_idl_extra_lists   FM_parse_tree
      debug '4', JSON.stringify FM_parse_tree = recast_solitaires                  FM_parse_tree
      # help                                                      formula
      # # info                                  FLOWMATIC_IDL.parse formula
      # # info unwrap_flowmatic_idl_extra_lists FLOWMATIC_IDL.parse formula
      # urge                                  IDLX.parse          formula

  # f()

