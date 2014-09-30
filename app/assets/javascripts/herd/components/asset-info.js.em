class Herd.AssetInfoComponent extends Herd.AssetContainerComponent
  actions:
    destroyChild: (asset) ->
      asset.destroyRecord()
