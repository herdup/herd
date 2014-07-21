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

    uploadFinished: (resp) ->
      @store.pushPayload resp
      @model.pushObject @store.getById('asset', resp.assets[0]?.id)

    uploadProgressed: (e) ->
      console.log('prog ', e)
