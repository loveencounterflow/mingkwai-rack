


############################################################################################################
# PATH                      = require 'path'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'TOPOCACHE/DEMO'
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
{ step, }                 = require 'coffeenode-suspend'


#===========================================================================================================
# FILE SYSTEM SIMULATOR
#-----------------------------------------------------------------------------------------------------------
FS        = {}
FS._t     = 1000
FS.cache  = {}

#-----------------------------------------------------------------------------------------------------------
FS._now = ->
  return @_t += +1

#-----------------------------------------------------------------------------------------------------------
FS.write = ( name, value ) ->
  t = @_now()
  @cache[ name ] = { t, value, }
  return value

#-----------------------------------------------------------------------------------------------------------
FS.read = ( name ) ->
  return undefined unless ( R = FS.cache[ name ] )?
  return R.value

#-----------------------------------------------------------------------------------------------------------
FS.read_json  = ( name        ) -> JSON.parse @read name
FS.write_json = ( name, value ) -> @write name, JSON.stringify value

#-----------------------------------------------------------------------------------------------------------
FS.fetch_cache = ( handler ) ->
  setImmediate => handler null, @cache
  return null

XXX = {}

#-----------------------------------------------------------------------------------------------------------
XXX.cmp = ( name_a, name_b ) ->
  throw new Error "unknown name #{rpr name_a}" unless ( entry_a = FS.cache[ name_a ] )?
  throw new Error "unknown name #{rpr name_b}" unless ( entry_b = FS.cache[ name_b ] )?
  return -1 if entry_a.t < entry_b.t
  return +1 if entry_a.t > entry_b.t
  return  0

#-----------------------------------------------------------------------------------------------------------
XXX.test_cromulence = ( reference, comparators... ) ->
  throw new Error "need at least one comparator, got none" unless comparators.length > 0
  for comparator in comparators
    return false if ( @cmp reference, comparator ) < 0
  return true


#===========================================================================================================
# TOPOCACHE MODEL IMPLEMENTATION
#-----------------------------------------------------------------------------------------------------------
@new_cache = ->
  R =
    '~isa':       'TOPOCACHE/cache'
    'graph':      LTSORT.new_graph loners: no
    'fixes':      {}
  return @_reset_chart @_reset_trend R

#-----------------------------------------------------------------------------------------------------------
@_reset_chart = ( me ) ->
  me[ 'boxed-chart'   ] = null
  me[ 'indexed-chart' ] = null
  return me

#-----------------------------------------------------------------------------------------------------------
@_reset_trend = ( me ) ->
  me[ 'boxed-trend'   ] = null
  me[ 'indexed-trend' ] = null
  return me


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@register = ( me, precedent, consequent, fix ) ->
  rc_key                  = @_get_rc_key me, precedent, consequent
  me[ 'fixes' ][ rc_key ] = fix
  LTSORT.add me[ 'graph' ], precedent, consequent
  return @_reset_chart me

#-----------------------------------------------------------------------------------------------------------
@_get_rc_key = ( me, precedent, consequent ) -> "#{consequent} -> #{precedent}"

#-----------------------------------------------------------------------------------------------------------
@get_fix = ( me, precedent, consequent, fallback ) ->
  rc_key = @_get_rc_key me, precedent, consequent
  unless ( R = me[ 'fixes' ][ rc_key ] )?
    throw new Error "no fix for #{rpr rc_key}" if fallback is undefined
    R = fallback
  return R


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@get_boxed_chart = ( me ) ->
  return R if ( R = me[ 'boxed-chart' ] )?
  return me[ 'boxed-chart' ] = LTSORT.group me[ 'graph' ]

#-----------------------------------------------------------------------------------------------------------
@get_indexed_chart = ( me ) ->
  return R if ( R = me[ 'indexed-chart' ] )?
  return me[ 'indexed-chart' ] = @_indexed_from_boxed_series me, @get_boxed_chart me

#-----------------------------------------------------------------------------------------------------------
@fetch_boxed_trend = ( me, handler ) ->
  ### TAINT relies on FS ###
  if ( Z = me[ 'boxed-trend' ] )?
    setImmediate -> handler null, Z
    return null
  #.........................................................................................................
  step ( resume ) =>
    Z         = []
    collector = {}
    cache_entries = yield FS.fetch_cache resume
    ( collector[ entry.t ] ?= [] ).push name for name, entry of cache_entries
    Z.push collector[ t ] for t in ( Object.keys collector ).sort()
    handler null, me[ 'boxed-trend' ] = Z
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@fetch_indexed_trend = ( me, handler ) ->
  if ( Z = me[ 'indexed-trend' ] )?
    setImmediate -> handler null, Z
    return null
  #.........................................................................................................
  step ( resume ) =>
    boxed_trend = yield @fetch_boxed_trend me, resume
    Z           = me[ 'indexed-trend' ] = @_indexed_from_boxed_series me, boxed_trend
    handler null, Z
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@_indexed_from_boxed_series = ( me, boxed_series ) ->
  R = {}
  for box, box_idx in boxed_series
    R[ name ] = box_idx for name in box
  return R


#===========================================================================================================
# FAULT-FINDING
#-----------------------------------------------------------------------------------------------------------
@find_first_fault = ( me, handler ) -> @_find_faults me, yes, handler
@find_faults      = ( me, handler ) -> @_find_faults me, no,  handler

#-----------------------------------------------------------------------------------------------------------
@_find_faults = ( me, first_only, handler ) ->
  step ( resume ) =>
    @_reset_trend me
    indexed_chart = @get_indexed_chart me
    indexed_trend = yield @fetch_indexed_trend me, resume
    R             = if first_only then null else []
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
        ### Skip entries that have the same or smaller charting index (that are not depenedent on
        reference): ###
        continue if ref_charting_idx <= cmp_charting_idx
        unless ( cmp_trending_idx = indexed_trend[ cmp_name ] )?
          warn_missing cmp_name
          continue
        #...................................................................................................
        ### A fault is indicated by the trending index being in violation of the dependency relation
        as expressed by the charting index: ###
        unless ref_trending_idx > cmp_trending_idx
          entry =
            reference:  ref_name
            comparison: cmp_name
            fix:        TC.get_fix me, cmp_name, ref_name, null
          #.................................................................................................
          if first_only
            handler null, entry
            return null
          #.................................................................................................
          R.push entry
    #.......................................................................................................
    handler null, R
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TC = @
main = ->
  step ( resume ) ->
    fc  = -> FS.read  'f'
    fp  = -> FS.write 'f', ( FS.read_json 'a.json' )[ 'x' ] + 3
    f   = ->
      return R if ( R = fc() )?
      return fp()

    #.......................................................................................................
    g = TC.new_cache()
    TC.register g, 'f.coffee', 'f.js',    "coffee -o lib -c src"
    TC.register g, 'f.js',     'a.json',  '???'
    TC.register g, 'foo',      'bar',     'frobulate'
    TC.register g, 'baz',      null,      'bazify'
    # urge 'cache:\n' + rpr FS.cache
    # debug '78777-5', LTSORT.linearize g[ 'graph' ]
    #.......................................................................................................
    FS.write 'f.coffee',  "### some CS here ###"
    FS.write 'f.js',      "/* some JS here */"
    FS.write 'foo',       "BLAH"
    FS.write 'baz',       "BLAH"
    warn '################# @1 #############################'
    FS.write_json 'a.json', { x: 42, }
    info f()
    urge 'cache:\n' + rpr FS.cache
    help "boxed trend:", yield TC.fetch_boxed_trend g, resume
    warn yield TC.find_first_fault  g, resume
    #.......................................................................................................
    warn '################# @2 #############################'
    FS.write 'f.coffee', "### some modified CS here ###"
    FS.write_json 'a.json', { x: 108, }
    info f()
    urge 'cache:\n' + rpr FS.cache
    # help "boxed trend:", yield TC.fetch_boxed_trend g, resume
    # urge yield TC.find_faults       g, resume
    warn yield TC.find_first_fault  g, resume
    urge yield TC.find_faults       g, resume
    #.......................................................................................................
    return null


############################################################################################################
unless module.parent?
  main()

  ###
  URL = require 'url'
  debug URL.parse 'https://nodejs.org/api/url.html#url_url_format_urlobject'
  nfo =
    protocol: 'file:',
    slashes: true,
    pathname: '/home/url.json',

  help URL.format nfo
  help URL.format protocol: 'cache', slashes: no, pathname: 'foo'
  help URL.format protocol: 'file', slashes: yes, pathname: 'foo'
  ###

