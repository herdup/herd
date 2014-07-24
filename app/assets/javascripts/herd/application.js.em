# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https:#github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery.ui.sortable
#= require handlebars
#= require ember
#= require ember-data
#= require ember-uploader
#= require js-yaml
#= require_self
#= require ./herd

# for more details see: http://emberjs.com/guides/application/
window.Herd = Ember.Application.create
  LOG_TRANSITIONS: true
  LOG_TRANSITIONS_INTERNAL: true
  LOG_VIEW_LOOKUPS: true
  LOG_ACTIVE_GENERATION: true
  rootElement: '#herd-uploader'
  Resolver: Ember.DefaultResolver.extend
    resolveTemplate: (parsedName) ->
      parsedName.fullNameWithoutType = "herd/" + parsedName.fullNameWithoutType
      @_super parsedName

DS.YamlTransform = DS.Transform.extend
  deserialize: (serialized) ->
    jsyaml.load(serialized)

  serialize: (deserialized) ->
    jsyaml.safeDump(deserialized)

Herd.register "transform:yaml", DS.YamlTransform

DS.RawTransform = DS.Transform.extend
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized

Herd.register "transform:raw", DS.RawTransform
