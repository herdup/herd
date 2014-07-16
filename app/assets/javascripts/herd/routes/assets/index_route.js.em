Herd.AssetsIndexRoute = Ember.Route.extend
  model: (params) ->
    @store.findAll('asset')
