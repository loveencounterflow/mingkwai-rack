


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
  # graph = TC.new_graph loners: no
  # #.........................................................................................................
  # TC.add graph, 'db-empty',       'db-complete'
  # TC.add graph, 'formulas',       'xxx'
  # TC.add graph, 'sims',           'xxx'
  # TC.add graph, 'variantusage',   'xxx'

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
    debug '44535', name_a, name_b
    return -1 if cache[ name_a ].t < cache[ name_b ].t
    return +1 if cache[ name_a ].t > cache[ name_b ].t
    return  0

  #.........................................................................................................
  sorted_names = ->
    R = Object.keys cache
    R.sort cmp
    return R

  #.........................................................................................................
  read_source   = ( name        ) -> debug name, read name; JSON.parse read name
  write_source  = ( name, value ) -> write name, JSON.stringify value

  #.........................................................................................................
  fc  = -> read  'f'
  fp  = -> write 'f', ( read_source 'a.json' )[ 'x' ] + 3
  f   = ->
    return R if ( R = fc() )?
    return fp()

  #.........................................................................................................
  warn '################# @1 #############################'
  write_source 'a.json', { x: 42, }
  urge 'cache before:\n' + rpr cache
  info f()
  urge 'cache after:\n' + rpr cache
  help ( cmp 'f', 'a.json' ), sorted_names().join ' ... '
  #.........................................................................................................
  warn '################# @2 #############################'
  write_source 'a.json', { x: 108, }
  urge 'cache before:\n' + rpr cache
  info f()
  urge 'cache after:\n' + rpr cache
  help ( cmp 'f', 'a.json' ), sorted_names().join ' ... '
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



###

