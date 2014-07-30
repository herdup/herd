mixin Herd.Assetable
  assets: DS.hasMany 'asset'

  +computed assets.@each
  masterAssets: ->
    @assets.filterBy('parentAsset', null) || []

  +computed masterAssets.@each
  asset: ->
    @masterAssets.firstObject
