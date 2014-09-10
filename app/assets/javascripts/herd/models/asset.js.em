class Herd.Asset extends DS.Model
  createdAt: DS.attr 'date'
  updatedAt: DS.attr 'date'
  fileName: DS.attr 'string'
  fileSize: DS.attr 'number'
  contentType: DS.attr 'string'
  type: DS.attr 'string'
  url: DS.attr 'string'
  position: DS.attr 'number'
  metadata: DS.attr 'raw'

  width: DS.attr 'number'
  height: DS.attr 'number'

  assetableId: DS.attr 'number'
  assetableType: DS.attr 'string'

  parentAsset: DS.belongsTo 'asset', { inverse: 'childAssets' }
  childAssets: DS.hasMany 'asset', { inverse: null }

  transform: DS.belongsTo 'transform'

  +computed metadata
  permalink: (key, permalinkString)->
    if arguments.length == 1
      @metadata.permalink
    else
      @metadata.permalink = permalinkString

  t: (trans) ->
    @childAssets.find (item, ix) ->
      item.transform == trans || item.transform?.options == trans

  n: (name) ->
    @childAssets.find (item, ix) ->
      item.transform.name == name

class Herd.AssetSerializer extends DS.ActiveModelSerializer with DS.EmbeddedRecordsMixin
  attrs:
    transform: {serialize: 'records'}
