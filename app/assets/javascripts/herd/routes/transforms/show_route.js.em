Herd.TransformsShowRoute = Ember.Route.extend
  model: (params) ->
    @store.find 'transform', params.id
