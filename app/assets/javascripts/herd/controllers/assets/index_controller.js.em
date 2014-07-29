class Herd.AssetsIndexController extends Ember.ArrayController
  sortProperties: ['position']

  +computed arrangedContent.@each.position #, arrangedContent.@each.parentAsset,
  filteredContent: ->
    @arrangedContent.filterBy('parentAsset', null)

  updateSortOrder: (indexes) ->
    @forEach (asset) ->
      asset.position = indexes[asset.id]
    @model.invoke 'save'

  actions:
    destroy: (asset) ->
      asset.destroyRecord()
      @model.removeObject(asset)

    uploadFinished: (resp) ->
      @store.pushPayload resp
      @model.pushObject @store.getById('asset', resp.asset?.id)

    uploadProgressed: (e) ->
      console.log('prog ', e)
