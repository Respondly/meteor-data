Package.describe({
  name: 'respondly:data',
  summary: 'Schema/model system for wrapping logic around documents.',
  version: '1.0.1',
  git: 'https://github.com/Respondly/meteor-data.git'
});




Package.onUse(function (api) {
  // api.versionsFrom('1.0');
  api.use('coffeescript');
  api.use('check');
  api.use('respondly:util@1.0.1');
  api.export('Data');

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.addFiles('shared/ns.js', ['client', 'server']);
  api.addFiles('shared/model/model.coffee', ['client', 'server']);
  api.addFiles('shared/model/document-model.coffee', ['client', 'server']);
  api.addFiles('shared/model/document-model.client.coffee', ['client', 'server']);
  api.addFiles('shared/model/field-definition.coffee', ['client', 'server']);
  api.addFiles('shared/model/model-factory.coffee', ['client', 'server']);
  api.addFiles('shared/model/model-refs-collection.coffee', ['client', 'server']);
  api.addFiles('shared/model/sub-model.coffee', ['client', 'server']);
  api.addFiles('shared/schema/schema.coffee', ['client', 'server']);
  api.addFiles('shared/schema/schema.date-fields.coffee', ['client', 'server']);
  api.addFiles('shared/check.coffee', ['client', 'server']);

});




Package.onTest(function (api) {
  api.use(['mike:mocha-package@0.4.7', 'coffeescript']);
  api.use("insecure");
  api.use(['respondly:data', 'respondly:util']);

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.addFiles('tests/shared/_init.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/document-model.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-changes.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-factory.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-reactive-props.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-ref.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-refs-collection.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model-revert.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/model.coffee', ['client', 'server']);
  api.addFiles('tests/shared/model/sub-model.coffee', ['client', 'server']);
  api.addFiles('tests/shared/samples/samples.coffee', ['client', 'server']);
  api.addFiles('tests/shared/schema/schema-hasOne.coffee', ['client', 'server']);
  api.addFiles('tests/shared/schema/schema-model-ref.coffee', ['client', 'server']);
  api.addFiles('tests/shared/schema/schema-types.coffee', ['client', 'server']);
  api.addFiles('tests/shared/schema/schema.coffee', ['client', 'server']);
  api.addFiles('tests/shared/check.coffee', ['client', 'server']);

});
