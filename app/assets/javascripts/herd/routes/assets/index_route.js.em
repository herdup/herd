Herd.AssetsIndexRoute = Ember.Route.extend
  model: (params) ->
    @store.find('asset', window.assetable)
