# http://emberjs.com/guides/models/#toc_store
# http://emberjs.com/guides/models/pushing-records-into-the-store/

Herd.ApplicationStore = DS.Store.extend({

})

Herd.ApplicationSerializer = DS.ActiveModelSerializer.extend({

})

# Override the default adapter with the `DS.ActiveModelAdapter` which
# is built to work nicely with the ActiveModel::Serializers gem.
Herd.ApplicationAdapter = DS.ActiveModelAdapter.extend
  namespace: 'herd'
  headers:
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
