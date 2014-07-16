Herd.TransformsNewController = Ember.ObjectController.extend
  actions:
    update: ->
      @model.save().then(
        (transform)=>
          @transitionTo('transforms.show',transform)
          console.log('success',data)
        (error)->
          console.log('error ',error)
      )
