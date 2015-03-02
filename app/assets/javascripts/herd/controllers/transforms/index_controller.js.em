class Herd.TransformsIndexController extends Ember.ArrayController
  actions:
    destroy: (transform) ->
      transform.destroyRecord()
