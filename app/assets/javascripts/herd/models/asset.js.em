# for more details see: http://emberjs.com/guides/models/defining-models/

class Herd.Asset extends DS.Model
  createdAt: DS.attr 'date'
  fileName: DS.attr 'string'
  fileSize: DS.attr 'number'
  contentType: DS.attr 'string'
  type: DS.attr 'string'
  url: DS.attr 'string'

  width: DS.attr 'number'
  height: DS.attr 'number'

  parentAsset: DS.belongsTo 'asset', { async: true, inverse: 'childAssets' }
  childAssets: DS.hasMany 'asset', { async:true, inverse: 'parentAsset' }

  transform: DS.belongsTo 'transform'
