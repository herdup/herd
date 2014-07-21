# for more details see: http://emberjs.com/guides/models/defining-models/

class Herd.Asset extends DS.Model
  createdAt: DS.attr 'date'
  fileName: DS.attr 'string'
  fileSize: DS.attr 'number'
  contentType: DS.attr 'string'
  type: DS.attr 'string'
  url: DS.attr 'string'
  position: DS.attr 'number'

  width: DS.attr 'number'
  height: DS.attr 'number'

  parentAsset: DS.belongsTo 'asset', { inverse: 'childAssets' }
  childAssets: DS.hasMany 'asset', { inverse: 'parentAsset' }

  transform: DS.belongsTo 'transform'
  childTransforms: DS.hasMany 'transform'

  t: (trans) ->
    @childAssets.find (item, ix) ->
      item.transform == trans || item.transform?.options.match trans


class Herd.AssetSerializer extends DS.ActiveModelSerializer with DS.EmbeddedRecordsMixin
  attrs:
    transform: {serialize: 'records'}
