class Herd.AssetsShowController extends Ember.ObjectController
  actions:
    destroy: (asset) ->
      asset.destroyRecord()
      @model.childAssets.removeObject(asset)

    transform: (transform) ->
      asset = @store.createRecord 'asset',
        parentAsset: @model
        transform: transform

      asset.save().then(
        (data) =>
          @model.childAssets.pushObject(data)
        (error) ->
          console.log 'error', error
      )
