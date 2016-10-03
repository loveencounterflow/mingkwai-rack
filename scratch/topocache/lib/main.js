// Generated by CoffeeScript 1.10.0
(function() {
  var CND, LTSORT, badge, debug, echo, help, info, log, rpr, test, urge, warn, whisper;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'TOPOCACHE/TESTS';

  log = CND.get_logger('plain', badge);

  debug = CND.get_logger('debug', badge);

  info = CND.get_logger('info', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  test = require('guy-test');

  LTSORT = require('ltsort');

  this.new_graph = function() {
    return LTSORT.new_graph({
      loners: false
    });
  };

  this.add = function(me, precedent, consequent) {
    if (consequent == null) {
      consequent = null;
    }
    return LTSORT.add(me, precedent, consequent);
  };

}).call(this);

//# sourceMappingURL=main.js.map
