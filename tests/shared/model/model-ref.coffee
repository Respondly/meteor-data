# describe 'core.Model (model-refs)', ->
RootSchema = null
RefSchema = null
RootModel = null
RefModel = null

class RootSchema extends Data.Schema
  constructor: -> super
    foo:            123
    refByType:
      modelRef:     RefModel
    refByFactory:
      modelRef: (doc) -> new RefModel(doc)
    refByTypeFunc:
      modelRef: -> RefModel

class RefSchema extends Data.Schema
  constructor: -> super
    bar: 'abc'
    baz: undefined


class RootModel extends Data.DocumentModel
  constructor: (doc) -> super doc, RootSchema, TestModels

class RefModel extends Data.Model
  constructor: (doc) -> super doc, RefSchema



describe 'Model-refs', ->
  it 'has a referenced model instance, from direct Type reference', ->
    root = new RootModel()
    expect(root.refByType).to.be.an.instanceOf RefModel
    expect(root.refByType.bar()).to.equal 'abc'

  it 'has a referenced model instance, from factory function reference', ->
    root = new RootModel()
    expect(root.refByFactory).to.be.an.instanceOf RefModel
    expect(root.refByFactory.bar()).to.equal 'abc'

  it 'has a referenced model instance, from function that returns the model Type', ->
    root = new RootModel()
    expect(root.refByTypeFunc).to.be.an.instanceOf RefModel
    expect(root.refByTypeFunc.bar()).to.equal 'abc'

  it 'has a referenced model instance with current (not default) values', ->
    doc =
      refByFactory:
        bar: 'my-value'
    root = new RootModel(doc)
    expect(root.refByFactory.bar()).to.equal 'my-value'

  it 'updates to parent document when reference model is changed', ->
    root = new RootModel()
    root.refByFactory.bar 'new value'
    expect(root._doc.refByFactory.bar).to.equal 'new value'


describe 'Model-refs: [changes] method', ->
  it 'stores changes on the child model', ->
    stub = new RootModel()
    expect(stub.refByType.bar()).to.equal 'abc'
    stub.refByType.bar 'new-value'
    changes = stub.refByType.changes()
    expect(changes.bar.to).to.equal 'new-value'
    expect(changes.bar.from).to.equal 'abc'

  it 'stores changes to a model-ref on the parent model', ->
    stub = new RootModel()
    stub.refByTypeFunc.bar 'new-value'
    stub.refByTypeFunc.baz 123

    changes = stub.changes()
    expect(changes.refByTypeFunc.bar.to).to.equal 'new-value'
    expect(changes.refByTypeFunc.baz.to).to.equal 123

  it.client 'stores changes in session object', ->
    stub = new RootModel().insertNew()
    stub.refByType.bar 'new-value'
    changes = stub.session().get('changes')
    expect(changes.refByType.bar.to).to.equal 'new-value'
    expect(changes.refByType.bar.from).to.equal 'abc'

  it 'overwrites existing values', ->
    stub = new RootModel().insertNew()
    stub.refByType.bar 'new-value'
    stub.refByType.baz 123
    stub.refByType.bar 'harry'
    changes = stub.changes()
    expect(changes.refByType.bar.to).to.equal 'harry'
    expect(changes.refByType.baz.to).to.equal 123

  # NOTE: This only works on the client using Session.
  it.client 'stores changes between instances', ->
    stub1 = new RootModel().insertNew()
    stub2 = new RootModel(stub1._doc)
    stub3 = new RootModel(stub1._doc)
    stub1.refByType.bar 'new-value'
    stub2.refByType.baz 123
    changes = stub3.changes()
    expect(changes.refByType.bar.to).to.equal 'new-value'
    expect(changes.refByType.baz.to).to.equal 123

  it 'does not store change when the written value is the same', ->
    stub = new RootModel()
    stub.refByType.bar 'abc' # No change.
    expect(stub.refByType.changes()).to.equal null
    expect(stub.changes()).to.equal null

  it 'clears changes when saved', ->
    stub = new RootModel().insertNew()
    stub.refByType.bar 'new-value'
    stub.foo(9876)

    changes = stub.changes()
    expect(changes.refByType.bar.to).to.equal 'new-value'
    expect(changes.foo.to).to.equal 9876

    stub.saveChanges()
    expect(stub.changes()).to.equal null


describe 'Model-refs: [revertChanges] method', ->
  stub = null
  beforeEach -> stub = new RootModel()

  it 'reverts a root property (not a referenced model)', ->
    stub.foo('abc')
    stub.revertChanges()
    expect(stub.foo()).to.equal 123

  it 'reverts changes from a referenced model on the root', ->
    stub.refByType.bar 'new-value'
    expect(stub.changes().refByType.bar.to).to.equal 'new-value'
    expect(stub.refByType.changes().bar.to).to.equal 'new-value'
    stub.revertChanges()
    expect(stub.refByType.bar()).to.equal 'abc'

  it 'reverts changes from a referenced model on the referenced model', ->
    stub.refByType.bar 'new-value'
    stub.refByType.revertChanges()
    expect(stub.refByType.bar()).to.equal 'abc'

  it 'removes empty sub-model change object (undefined within wider change-set)', ->
    stub.foo('abc')
    stub.refByType.bar 'new-value'
    stub.refByType.revertChanges()
    expect(stub.changes().refByType).to.equal undefined

  it 'removes empty sub-model change object (no change-set)', ->
    stub.refByType.bar 'new-value'
    stub.revertChanges()
    expect(stub.changes()).to.equal null



describe 'Model-refs: [syncChanges] method (Update|Save)', ->
  stub1 = null
  stub2 = null
  beforeEach ->
    stub1 = new RootModel()
    stub2 = new RootModel()

  it 'changes values', ->
    stub1.refByType.bar 'my-value1'
    stub1.refByType.baz 'my-value2'

    Data.Model.syncChanges(stub2, stub1.changes())

    expect(stub2.refByType.bar()).to.equal 'my-value1'
    expect(stub2.refByType.baz()).to.equal 'my-value2'

  it 'returns the changed field definitions', ->
    stub1.refByType.bar 'my-value1'
    stub1.refByType.baz 'my-value2'

    fields = Data.Model.syncChanges(stub2, stub1.changes())
    expect(fields.length).to.equal 1
    expect(fields[0].key).to.equal 'refByType'

