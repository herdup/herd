# For more information see: http://emberjs.com/guides/routing/

Herd.AssetsRoute = Ember.Route.extend
  model: (params) ->
    @store.findAll 'asset'
