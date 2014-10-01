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
    console.log 'about to save asset', @currentAsset._data

    @currentAsset?.save().then(
      (a) =>
        console.log 'saved asset ', a
        @work()
      (e) =>
        console.log e
    ).finally =>
      @currentAsset = null
