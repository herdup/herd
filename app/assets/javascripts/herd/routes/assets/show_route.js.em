Herd.AssetsShowRoute = Ember.Route.extend
  model: (params) ->
    @store.find('asset', params.id)
  setupController: (controller, model) ->
    controller.content = model
    controller.transforms = @store.find('transform')
