class Herd.AssetManager extends Ember.Object
  assetQueue: []
  currentAsset: null

  pushRequest: (asset) ->
    @assetQueue.pushObject asset

    unless @currentAsset
      Ember.run.scheduleOnce 'afterRender', @, 'work'

    asset

  work: ->
    @currentAsset = @assetQueue.popObject()

    @currentAsset?.save().then(
      (a) =>
        @work()
      (e) =>
        console.log e
    ).finally =>
      @currentAsset = null
