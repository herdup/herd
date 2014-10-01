Ember.Application.initializer
  name: 'setup-herd'

  initialize: (container, application) ->
    application.register "transform:raw", DS.RawTransform
    application.register "transform:yaml", DS.YamlTransform

    application.register 'asset-manager:main', Herd.AssetManager, instantiate: true, singleton: true
    application.inject 'component', 'assetManager', 'asset-manager:main'
