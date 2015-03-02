Herd.TransformsNewRoute = Ember.Route.extend
  model: ->
    @store.createRecord('transform',{})
