Herd.TransformsIndexRoute = Ember.Route.extend
  model: (params) ->
    @store.findAll 'transform'
