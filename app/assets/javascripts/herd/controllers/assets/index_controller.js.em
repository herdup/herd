class Herd.AssetsIndexController extends Ember.ArrayController
  +computed model.@each.parentAsset
  filteredAssets: ->
    @model.filterBy('parentAsset', null)

  actions:
    destroy: (asset) ->
      asset.destroyRecord()

    uploadFinished: (resp) ->
      @store.pushPayload resp

    uploadProgressed: (e) ->
      console.log('prog ', e)
