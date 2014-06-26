# for more details see: http://emberjs.com/guides/models/defining-models/

Herd.Asset = DS.Model.extend
  createdAt: DS.attr 'date'
  fileName: DS.attr 'string'
