


############################################################################################################
FS                        = require 'fs'
PATH                      = require 'path'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'INTERSKIPLIST/BENCHMARK'
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
σ_version                 = Symbol.for 'version'
NEW_ISL                   = require 'interskiplist'
NEW_ISL[ σ_version ]      = ( require 'interskiplist/package.json' )[ 'version' ]
#...........................................................................................................
text_path                 = PATH.resolve __dirname, './text.txt'
text                      = FS.readFileSync text_path, encoding: 'utf-8'
chrs                      = CND.shuffle Array.from text
#...........................................................................................................
isl_path                  = PATH.resolve __dirname, '../../node_modules/ncr/data/unicode-9.0.0-intervals.json'
debug isl_path
#...........................................................................................................
now                       = -> +new Date()


#-----------------------------------------------------------------------------------------------------------
@get_unicode_isl = ( ISL ) ->
  # key = "read Unicode data for ISL v#{ISL[ σ_version ]}"
  # console.time key
  R = ISL.new()
  ISL.add_index R, 'rsg'
  ISL.add_index R, 'tag'
  ISL.add R, interval for interval in require isl_path
  # console.timeEnd key
  return R

#-----------------------------------------------------------------------------------------------------------
@get_memoizing_aggregate = ( ISL, isl ) ->
  cache = {}
  R = ( chr ) ->
    return R if ( R = cache[ chr ] )?
    return cache[ chr ] = ISL.aggregate isl, chr
  get_cache_size = -> ( Object.keys cache ).length
  return [ R, get_cache_size, ]


#===========================================================================================================
# BENCHMARK
#-----------------------------------------------------------------------------------------------------------
@benchmark = ( ISL, mode ) ->
  isl = @get_unicode_isl ISL
  switch mode
    when 'plain'
      sub_key     = 'unmemoized'
      µ_aggregate = null
    when 'memoized'
      sub_key             = '  memoized'
      [ µ_aggregate
        get_cache_size  ] = @get_memoizing_aggregate ISL, isl
    else throw new Error "unknown mode #{rpr mode}"
  #.........................................................................................................
  key = "ISL v#{ISL[ σ_version ]} #{sub_key}"
  t0  = now()
  #.........................................................................................................
  switch mode
    when 'plain'
      for chr in chrs
        x = ISL.aggregate isl, chr
    when 'memoized'
      for chr in chrs
        x = µ_aggregate chr
      help "cache size:", CND.format_number get_cache_size()
  #.........................................................................................................
  t1            = now()
  dt            = ( t1 - t0 ) / 1000
  chr_count     = chrs.length
  chr_count_txt = CND.format_number chr_count
  cps           = chr_count / dt
  cps_txt       = CND.format_number Math.floor cps + 0.5
  help "#{key} aggregated #{chr_count_txt} chrs in #{dt} s (#{cps_txt} cps)"
  #.........................................................................................................
  return null

############################################################################################################
unless module.parent?
  @benchmark NEW_ISL, 'plain'
  @benchmark NEW_ISL, 'memoized'

