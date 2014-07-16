Herd.AssetContainerComponent = Ember.Component.extend
  asset: null
  options: null

  +computed options
  optionsHash: ->
    return unless @options
    yaml = @options.split('|').join("\n")
    hash = jsyaml.load yaml
    sorted = {}
    for k in Object.keys(hash).sort()
      sorted[k] = hash[k]

    sorted

  +computed options
  sortedOptionsSegment: ->
    yaml = jsyaml.dump @optionsHash
    encodeURIComponent yaml.split("\n").join('|')

  +computed asset.id, options
  assetUrl: ->
    if @options
      return "/herd/assets/#{@asset.id}/t/#{encodeURIComponent @options}"
    else
      return @asset.url
