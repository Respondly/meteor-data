Package.describe({
  summary: 'Schema/model system for wrapping logic around documents.'
});



Package.on_use(function (api) {
  api.use(['coffeescript']);
  api.use(['css-stylus', 'ctrl', 'util']);
  api.export('Data');

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.add_files('shared/api.coffee', ['client', 'server']);
  api.add_files('shared/model/model.coffee', ['client', 'server']);
  api.add_files('shared/model/document-model.coffee', ['client', 'server']);
  api.add_files('shared/model/field-definition.coffee', ['client', 'server']);
  api.add_files('shared/model/model-factory.coffee', ['client', 'server']);
  api.add_files('shared/model/model-refs-collection.coffee', ['client', 'server']);
  api.add_files('shared/model/sub-model.coffee', ['client', 'server']);
  api.add_files('shared/schema/schema.coffee', ['client', 'server']);
  api.add_files('shared/schema/schema.date-fields.coffee', ['client', 'server']);

});



Package.on_test(function (api) {
  api.use(['munit', 'coffeescript', 'chai', 'insecure']);
  api.use(['data', 'util']);

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.add_files('tests/shared/_init.coffee', ['client', 'server']);
  // api.add_files('tests/shared/model/document-model.coffee', ['client', 'server']);
  // api.add_files('tests/shared/model/model-factory.coffee', ['client', 'server']);
  // api.add_files('tests/shared/model/model-ref.coffee', ['client', 'server']);
  // api.add_files('tests/shared/model/model-refs-collection.coffee', ['client', 'server']);
  // api.add_files('tests/shared/model/model.coffee', ['client', 'server']);
  api.add_files('tests/shared/samples/samples.coffee', ['client', 'server']);
  // api.add_files('tests/shared/schema/schema-hasOne.coffee', ['client', 'server']);
  // api.add_files('tests/shared/schema/schema-model-ref.coffee', ['client', 'server']);
  // api.add_files('tests/shared/schema/schema-types.coffee', ['client', 'server']);
  // api.add_files('tests/shared/schema/schema.coffee', ['client', 'server']);

});
