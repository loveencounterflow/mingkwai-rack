


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
  key = "read Unicode data for ISL v#{ISL[ σ_version ]}"
  console.time key
  R = ISL.new()
  ISL.add_index R, 'rsg'
  ISL.add_index R, 'tag'
  ISL.add R, interval for interval in require isl_path
  console.timeEnd key
  return R

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@benchmark = ( ISL ) ->
  key = "ISL v#{ISL[ σ_version ]}"
  @get_unicode_isl ISL
  t0 = now()
  #.........................................................................................................
  for chr in chrs
    ISL.aggregate chr
  #.........................................................................................................
  t1        = now()
  dt        = ( t1 - t0 ) / 1000
  tpc       = chrs.length / dt
  chr_count = chrs.length
  help "#{key} aggregated #{chr_count} chrs in #{dt}ms (#{tpc.toFixed 3}cps)"
  #.........................................................................................................
  return null

############################################################################################################
unless module.parent?
  @benchmark NEW_ISL

