Herd.TransformsShowController = Ember.ObjectController.extend
  actions:
    update: ->
      @model.save().then(
        (data)->
          console.log('success'+data)
        (data)->
          console.log('error '+data)
      )
