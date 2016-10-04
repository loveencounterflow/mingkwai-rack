


############################################################################################################
# PATH                      = require 'path'
#...........................................................................................................
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
TC                        = require './main'
LTSORT                    = require 'ltsort'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 3000

# #-----------------------------------------------------------------------------------------------------------
# f = ->

# f.apply TC = {}

#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "demo" ] = ( T, done ) ->
  # chart = TC.new_graph loners: no
  # #.........................................................................................................
  # TC.add chart, 'db-empty',       'db-complete'
  # TC.add chart, 'formulas',       'xxx'
  # TC.add chart, 'sims',           'xxx'
  # TC.add chart, 'variantusage',   'xxx'

  #.........................................................................................................
  cache       = {}
  [ t0s, _, ] = process.hrtime()

  #.........................................................................................................
  now = ->
    [ t1s, t1n, ] = process.hrtime()
    return ( t1s - t0s ) * 1e5 + t1n // 1e4

  #.........................................................................................................
  write = ( name, value ) ->
    t = now()
    cache[ name ] = { t, value, }
    return value

  #.........................................................................................................
  read = ( name ) ->
    return undefined unless ( R = cache[ name ] )?
    return R.value

  #.........................................................................................................
  cmp = ( name_a, name_b ) ->
    throw new Error "unknown name #{rpr name_a}" unless ( entry_a = cache[ name_a ] )?
    throw new Error "unknown name #{rpr name_b}" unless ( entry_b = cache[ name_b ] )?
    return -1 if entry_a.t < entry_b.t
    return +1 if entry_a.t > entry_b.t
    return  0

  #.........................................................................................................
  test_cromulence = ( reference, comparators... ) ->
    throw new Error "need at least one comparator, got none" unless comparators.length > 0
    for comparator in comparators
      return false if ( cmp reference, comparator ) < 0
    return true

  #.........................................................................................................
  get_trend = ->
    R         = []
    collector = {}
    ( collector[ entry.t ] ?= [] ).push name for name, entry of cache
    R.push collector[ t ] for t in ( Object.keys collector ).sort()
    return R

  #.........................................................................................................
  indexed_from_boxed_series = ( time_series ) ->
    R     = {}
    for box, idx in time_series
      R[ name ] = idx for name in box
    return R

  #.........................................................................................................
  find_faults = ( indexed_chart, indexed_trend ) ->
    #.......................................................................................................
    messages = {}
    warn_missing = ( name ) ->
      ### TAINT warn or fail? ###
      message = "not in trend: #{rpr ref_name}"
      warn message unless message of messages
      messages[ message ] = 1
      return null
    #.......................................................................................................
    for ref_name, ref_charting_idx of indexed_chart
      unless ( ref_trending_idx = indexed_trend[ ref_name ] )?
        warn_missing ref_name
        continue
      #.....................................................................................................
      for cmp_name, cmp_charting_idx of indexed_chart
        ### skip entry for reference item in comparisons: ###
        continue if ref_name          is cmp_name
        ### skip entries that have the same charting index: ###
        continue if ref_charting_idx  <= cmp_charting_idx
        unless ( cmp_trending_idx = indexed_trend[ cmp_name ] )?
          warn_missing cmp_name
          continue
        debug '33421', ref_name, ref_charting_idx, ref_trending_idx, cmp_name, cmp_charting_idx, cmp_trending_idx
        unless ref_trending_idx > cmp_trending_idx
          warn ref_name, cmp_name
    #.......................................................................................................
    return null

  #.........................................................................................................
  read_source   = ( name        ) -> debug name, read name; JSON.parse read name
  write_source  = ( name, value ) -> write name, JSON.stringify value

  #.........................................................................................................
  register = ( me, precedent, consequent, remedy ) ->
    key             = "#{consequent} -> #{precedent}"
    remedies        = me[ 'remedies' ] ?= {}
    remedies[ key ] = remedy
    return LTSORT.add me, precedent, consequent

  #.........................................................................................................
  fc  = -> read  'f'
  fp  = -> write 'f', ( read_source 'a.json' )[ 'x' ] + 3
  f   = ->
    return R if ( R = fc() )?
    return fp()

  #.........................................................................................................
  chart = LTSORT.new_graph loners: no
  ###

  In the dependency chart we enter nodes in the chronological order that is needed for correct computation
  with cached intermediate artefacts.

  If function `f` depends on some input file `a.json` (which may have changed on disk since the last output
  of `f` was written to cache), then we enter the **temporal constraint** `( t 'a.json' ) < ( t 'f' )`
  (read: the modification time of the object identified as `'a.json'` must be less than that of `'f'`) as
  `L.add g, 'a.json', 'f'`.
  ###
  # register chart, 'a.json',   'f',        '???'
  # register chart, 'f',        'f.js',     '???'
  register chart, 'f.coffee', 'f.js',     "coffee -o lib -c src"
  register chart, 'f.js',     'a.json',   '???'
  # register chart, 'f.cache', 'a.json', '???'
  # debug '78777-1', LTSORT.find_root_nodes chart, true
  # debug '78777-2', LTSORT.find_root_nodes chart, false
  # debug '78777-3', LTSORT.is_lone_node    chart, 'f'
  # debug '78777-3', LTSORT.is_lone_node    chart, 'f.cache'
  # debug '78777-3', LTSORT.is_lone_node    chart, 'a.json'
  debug '78777-5', LTSORT.linearize       chart
  ### TAINT `group` not an obvious verb ###
  ### TAINT `group` sometimes returns empty list elements; intentional? ###
  debug '78777-4', LTSORT.group           chart
  help chart
  #.........................................................................................................
  write 'f.coffee', "### some CS here ###"
  write 'f.js',     "/* some JS here */"
  warn '################# @1 #############################'
  write_source 'a.json', { x: 42, }
  # urge 'cache before:\n' + rpr cache
  info f()
  # urge 'cache after:\n' + rpr cache
  # help ( cmp 'f', 'a.json' )
  help ( test_cromulence 'f', 'a.json' )
  help "boxed chart:", LTSORT.group chart
  help "boxed trend:", get_trend()
  help indexed_trend = indexed_from_boxed_series get_trend()
  help indexed_chart = indexed_from_boxed_series LTSORT.group chart
  urge find_faults indexed_chart, indexed_trend
  #.........................................................................................................
  warn '################# @2 #############################'
  write 'f.coffee', "### some modified CS here ###"
  write_source 'a.json', { x: 108, }
  # urge 'cache before:\n' + rpr cache
  info f()
  # urge 'cache after:\n' + rpr cache
  # help ( cmp 'f', 'a.json' )
  help ( test_cromulence 'f', 'a.json' )
  help "boxed chart:", LTSORT.group chart
  help "boxed trend:", get_trend()
  help indexed_trend = indexed_from_boxed_series get_trend()
  help indexed_chart = indexed_from_boxed_series LTSORT.group chart
  urge find_faults indexed_chart, indexed_trend
  #.........................................................................................................
  done()


############################################################################################################
unless module.parent?
  include = [
    "demo"
    ]
  @_prune()
  # @_main()

  # debug '5562', JSON.stringify key for key in Object.keys @

  # CND.run =>
  @[ "demo" ] null, -> warn "not tested"

###

## Artefacts

* (local, physical, reified) Data Sources (a.k.a. 'flat files', 'text files')

* Program Sources

* Cache Files

* In-Memory Caches

To use cache:

* cache must be present
* cache must be newer than its dependency artefacts


The list of (cache, raw and program) artefacts arranged by their modification dates
must be a proper (monotonic?) sublist of the list of their logical dependencies.

In other words, if task A (modified at A.t) depends on artefact B (modified at B.t), then
that gives us the dependency list [ A, B, ]

'trending', 'the trend'
'drifting', 'the drift'
'the course'
'the chart'

dependency list vs timeline
chart vs trend
?chart vs drift

series
boxed series
indexed series

fault: a mismatch between the ordering relations between a reference entry and a comparison entry as
  displayed in the chart on the one hand and in the trend on the other hand.
###

