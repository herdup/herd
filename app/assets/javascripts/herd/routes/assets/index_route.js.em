Herd.AssetsIndexRoute = Ember.Route.extend
  model: (params) ->
    if window.assetable
      @store.find('asset', window.assetable)
    else
      @store.find('asset')
