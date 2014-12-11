#= require jquery.ui.sortable
#= require handlebars
#= require ember
#= require ember-data
#= require ember-uploader
#= require ember-image-loader
#= require ember-img-view
#= require ember-background-image-view
#= require js-yaml

class DS.RawTransform extends DS.Transform
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized

class DS.YamlTransform extends DS.Transform
  deserialize: (serialized) ->
    jsyaml.load(serialized)

  serialize: (deserialized) ->
    jsyaml.safeDump(deserialized)
