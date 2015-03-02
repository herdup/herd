class Herd.AssetManager extends Ember.Object
  taskQueue: []
  currentTask: null

  pushRequest: (asset, transform, done) ->
    @taskQueue.pushObject Ember.Object.create
      asset: asset
      transform: transform
      callback: done

    unless @currentTask
      Ember.run.scheduleOnce 'afterRender', @, 'work'

  work: ->
    return unless @taskQueue.length

    @currentTask = @taskQueue.shiftObject()

    @child = @store.createRecord 'asset',
      parentAsset: @currentTask.asset
      transform: @store.createRecord 'transform', @currentTask.transform

    @child.save().then(
      (a) =>
        @currentTask.callback(a)
        @work()
      (e) =>
        console.log e
    ).finally =>
      @currentTask = null
