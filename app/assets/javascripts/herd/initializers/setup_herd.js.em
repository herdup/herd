Ember.Application.initializer
  name: 'setup-herd'

  initialize: (container, application) ->
    application.register "transform:raw", DS.RawTransform
    application.register "transform:yaml", DS.YamlTransform
  
