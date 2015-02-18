ParentSchema  = null
ChildSchema   = null
Stub          = null


class ParentSchema extends Data.Schema
  constructor: (fields...) -> super fields,
    parent: 123
    base:   'base'
    noDefault: undefined
    nullDefault: null

    foo:
      default: 123
      field: 'custom.path'

    mappedShallow: { field: 'shallow', default:123 }
    mappedDeep:    { field: 'deep.path', default:123 }


class ChildSchema extends ParentSchema
  constructor: -> super
    child: 'abc'
    base:  'overridden'


class Stub extends Data.DocumentModel
  constructor: (doc) ->
    super doc, ChildSchema, TestModels


# Tests --------------------------------------------------------

describe 'DocumentModel constructor', ->
  beforeEach -> TestModel.deleteAll()

  it 'stores the collection', ->
    stub = new Stub()
    expect(stub.db.collection).to.equal TestModels

  it 'stores the id', ->
    stub = new Stub({ _id:123 })
    expect(stub.id).to.equal 123

  it 'has a defaultSelector', ->
    stub = new Stub({ _id:123 })
    expect(stub.defaultSelector()).to.equal 123


# ----------------------------------------------------------------------


describe 'Storing reference to model on `DocumentModel.models`', ->
  it 'stores a reference when constructed with an ID', ->
    stub = new Stub({ _id:'abc' })
    instanceId = stub.__internal__.instance
    expect(Data.DocumentModel.models.abc[instanceId]).to.equal stub

  it 'stores a reference when the model is inserted into DB', ->
    stub = new Stub().insertNew()
    instanceId = stub.__internal__.instance
    expect(stub.id).not.to.equal undefined
    expect(Data.DocumentModel.models[stub.id][instanceId]).to.equal stub

  it 'removes reference when model is disposed', ->
    stub1 = new Stub().insertNew()
    stub2 = new Stub(stub1._doc)
    instanceId = stub1.__internal__.instance
    expect(Data.DocumentModel.models[stub1.id][instanceId]).to.equal stub1
    stub1.dispose()
    expect(Data.DocumentModel.models[stub1.id][instanceId]).to.equal undefined

  it 'removes entire reference entry for all instances when last instance disposed', ->
    stub1 = new Stub().insertNew()
    stub2 = new Stub(stub1._doc)
    stub1.dispose()
    stub2.dispose()
    expect(Data.DocumentModel.models[stub1.id]).to.equal undefined


# ----------------------------------------------------------------------


describe 'DocumentModel.toValues', ->
  beforeEach -> TestModel.deleteAll()

  it 'includes the ID', ->
    stub = new Stub().insertNew()
    values = stub.toValues()
    expect(stub.id).not.to.equal undefined
    expect(values.id).to.equal stub.id



# ----------------------------------------------------------------------


describe 'DocumentModel.isModelType (class property)', ->
  ParentDoc = null
  ChildDoc  = null
  beforeEach ->
    class ParentDoc extends Data.DocumentModel
    class ChildDoc extends ParentDoc

  it 'is a document and a model (parent)', ->
    expect(ParentDoc.isModelType).to.equal true
    expect(ParentDoc.isDocumentModelType).to.equal true

  it 'is a model (child)', ->
    expect(ChildDoc.isModelType).to.equal true
    expect(ParentDoc.isDocumentModelType).to.equal true



describe 'DocumentModel: [insertNew] method', ->
  MySchema  = null
  Foo       = null

  beforeEach ->
    class MySchema extends Data.Schema
      constructor: -> super Data.Schema.dateFields,
        foo: 'foo'
        myDate:
          type: Date
        deep1:
          default: 'deep-1-default'
          field:   'path.to.deep1'

        deep2:
          default: 'deep-2-default'
          field:   'path.to.deep2'

        deep3:
          field:   'path.to.deep3'

        bar: undefined

    class Foo extends Data.DocumentModel
      constructor: (doc) -> super doc, MySchema, TestModels


  it 'throws if the doc already exists', ->
    fn = -> new Foo({ _id:123 }).insertNew()
    expect(fn).to.throw /Already exists./

  it 'returns the model', ->
    stub = new Foo()
    expect(stub.insertNew()).to.equal stub

  it 'inserts the doc into the DB collection', ->
    stub = new Foo().insertNew()
    doc = TestModels.findOne(stub.id)
    expect(doc._id).to.equal stub.id

  it 'updates the id', ->
    stub = new Foo()
    expect(stub.id).to.equal undefined

    stub.insertNew()
    expect(stub.id).not.to.equal undefined
    expect(stub.id).to.equal stub._doc._id

  it 'constructs default values on the inserted doc', ->
    stub = new Foo().insertNew()
    expect(stub._doc.foo).to.equal 'foo'
    expect(stub._doc.path.to.deep1).to.equal 'deep-1-default'
    expect(stub._doc.path.to.deep2).to.equal 'deep-2-default'
    expect(stub._doc.path.to.deep3).not.to.exist
    expect(stub._doc.bar).not.to.exist

  it 'respects written values on the doc', ->
    stub = new Foo()
    stub.foo   'my-value-1'
    stub.deep1 'my-value-2'
    stub.deep3 'foo'
    stub.bar   'my-value-3'

    doc = stub._doc

    stub.insertNew()
    expect(stub._doc.foo).to.equal 'my-value-1'
    expect(stub._doc.path.to.deep1).to.equal 'my-value-2'
    expect(stub._doc.path.to.deep3).to.equal 'foo'
    expect(stub._doc.bar).to.equal 'my-value-3'

  it 'respects existing values on the doc', ->
    doc =
      foo: 'my-value-1'
    stub = new Foo(doc).insertNew()
    expect(stub._doc.foo).to.equal 'my-value-1'
    expect(stub._doc.path.to.deep2).to.equal 'deep-2-default'

  it 'stores the [createdAt] date', ->
    stub = new Foo()
    expect(stub.createdAt()).to.equal undefined
    stub.insertNew()
    expect(stub.createdAt().millisecondsAgo()).to.be.below(10)

  it 'stores the [updateAt] date', ->
    stub = new Foo()
    expect(stub.updatedAt()).to.equal undefined
    stub.insertNew()
    expect(stub.updatedAt().millisecondsAgo()).to.be.below(10)

  it 'the [createdAt] is the same at [updatedAt]', ->
    stub = new Foo()
    stub.insertNew()
    expect(stub.createdAt()).to.eql stub.updatedAt()

  it 'stores [createdAt] and [updatedAt] as integers', ->
    stub = new Foo().insertNew()
    expect(Object.isNumber(stub._doc.createdAt)).to.equal true
    expect(Object.isNumber(stub._doc.updatedAt)).to.equal true

  it 'returns [createdAt] and [updatedAt] as dates from the property functions', ->
    stub = new Foo().insertNew()
    expect(Object.isDate(stub.createdAt())).to.equal true
    expect(Object.isDate(stub.updatedAt())).to.equal true

  it 'inserts dates as integers', ->
    now = new Date()
    stub = new Foo()
    stub.myDate(now)
    stub.insertNew()
    expect(Object.isNumber(stub._doc.myDate)).to.equal true
    expect(Object.isDate(stub.myDate())).to.equal true


# ----------------------------------------------------------------------


describe 'DocumentModel: [changes] method', ->
  stub = null
  beforeEach -> stub = new Stub().insertNew()

  it 'has no changes by default', ->
    expect(stub.changes()).to.equal null

  it 'stores changes for unsaved models (in memory, not session)', ->
    stub = new Stub()
    stub.foo 'abc'
    expect(stub.__internal__.changeStore.get('changes')).to.eql { foo:{to:'abc', from:123} }

  it.client 'stores changes in session object', ->
    stub = new Stub().insertNew()
    stub.foo 'abc'
    expect(stub.session().get('changes')).to.eql { foo:{to:'abc', from:123} }

  it 'clears change-set on [insertNew]', ->
    stub = new Stub()
    stub.foo 'abc'
    expect(stub.__internal__.changeStore.get('changes').foo.to).to.eql 'abc'
    stub.insertNew()
    stub.changes()
    expect(stub.__internal__.changeStore.get('changes')).to.equal undefined

  it 'stores changed values', ->
    stub.foo 'my-foo'
    stub.child 'my-child'
    expect(stub.changes().foo.to).to.equal 'my-foo'
    expect(stub.changes().child.to).to.equal 'my-child'

  it 'stores last value', ->
    stub.foo 1
    stub.foo 2
    expect(stub.changes().foo.to).to.equal 2

  it 'stores null (as the changed value)', ->
    stub.foo 1
    stub.foo null
    expect(stub.changes().foo.to).to.equal null

  it 'returns the "changes" value from a write operation', ->
    result = stub.changes(key:'foo', value:456)
    expect(result.foo.from).to.equal 123
    expect(result.foo.to).to.equal 456

  it 'returns the null "changes" value from a write operation', ->
    result = stub.changes(key:'foo', value:123)
    expect(result).to.equal null

  it 'clears changes via the [changes] method', ->
    stub.foo 1
    stub.changes(clear:true)
    expect(stub.changes()).to.equal null

  it 'removes the change when property is saved', ->
    stub.foo 'my-foo'
    stub.child 'my-child', save:true
    expect(stub.changes().foo.to).to.equal 'my-foo'
    expect(stub.changes().child).to.equal undefined

  it 'removes the change when field is updated', ->
    stub.foo 'my-foo'
    stub.child 'my-child'
    stub.updateFields( stub.child )
    expect(stub.changes().foo.to).to.equal 'my-foo'
    expect(stub.changes().child).to.equal undefined

  it 'removes the [changes] object when all properties have been saved', ->
    stub.foo   1
    stub.child 1
    stub.foo   2, save:true
    stub.child 2, save:true
    expect(stub.changes()).to.equal null

  it 'removes the [changes] object when all fields have been updated', ->
    stub.foo   1
    stub.child 1
    stub.updateFields( stub.foo, stub.child )
    expect(stub.changes()).to.equal null


# ----------------------------------------------------------------------


describe 'DocumentModel: [saveChanges] method', ->
  stub = null
  beforeEach ->
    TestModel.deleteAll()
    stub = new Stub().insertNew()

  it 'updates fields in the DB', ->
    stub.child('def')
    expect(TestModels.findOne().child).to.equal 'abc' # Not updated yet.
    stub.saveChanges()
    expect(TestModels.findOne().child).to.equal 'def'

  it 'returns the updated fields', ->
    stub.child('def')
    result = stub.saveChanges()
    expect(result.length).to.equal 1
    expect(result[0].field).to.equal 'child'

  it 'does nothing when there are no changes', ->
    result = stub.saveChanges()
    expect(result.length).to.equal 0


# ----------------------------------------------------------------------


describe 'DocumentModel: [updateFields] method', ->
  stub = null
  beforeEach ->
    TestModel.deleteAll()
    stub = new Stub().insertNew()

  it 'updates the field in the DB', ->
    stub.child 'new-value'
    expect(TestModels.findOne().child).to.equal 'abc' # Not updated in DB yet.
    stub.updateFields( stub.child )
    expect(TestModels.findOne().child).to.equal 'new-value'


# ----------------------------------------------------------------------


describe 'DocumentModel: [beforeSave]', ->
  describe 'filter - on [updateFields]', ->
    stub = null
    beforeEach ->
      TestModel.deleteAll()
      stub = new Stub().insertNew()

    it 'invokes the before save filter', ->
      count = 0
      value = null
      stub.foo.beforeSave = (v) ->
        count += 1
        value = v

      stub.foo 'foo!'
      stub.updateFields( stub.foo )
      expect(count).to.equal 1
      expect(value).to.equal 'foo!'

    it 'throws an error from within the filter', ->
      stub.foo.beforeSave = (v) -> throw new Error('My error.')
      fn = -> stub.updateFields( stub.foo )
      expect(fn).to.throw /My error./


  # ----------------------------------------------------------------------


  describe 'filter - on [updateFields] - mutating the saved value', ->
    stub = null
    beforeEach ->
      TestModel.deleteAll()
      stub = new Stub().insertNew()
      stub.child.beforeSave = (v) -> 'mutated'
      stub.child 'foo!'
      stub.updateFields( stub.child )

    it 'mutates the saved value (immediately in the doc)', ->
      expect(stub._doc.child).to.equal 'mutated'

    it 'mutates the saved value (immediately on the model)', ->
      expect(stub.child()).to.equal 'mutated'

    it 'mutates the saved value (in the DB)', ->
      expect(TestModels.findOne().child).to.equal 'mutated'


  describe 'filter - on [insertNew]', ->
    stub = null
    beforeEach ->
      TestModel.deleteAll()
      stub = new Stub()

    it 'invokes the before save filter', ->
      stub.foo 'value-1'

      callbackResult = { count:0 }
      stub.foo.beforeSave = (value) ->
        callbackResult.count += 1
        callbackResult.value = value

      stub.insertNew()
      expect(callbackResult.count).to.equal 1
      expect(callbackResult.value.to).to.equal 'value-1'


  describe 'DocumentModel: [beforeSave] filter - mutating the saved value', ->
    stub = null
    beforeEach ->
      TestModel.deleteAll()
      stub = new Stub()
      stub.child.beforeSave = (v) -> 'mutated'
      stub.child 'foo!'
      stub.insertNew()

    it 'mutates the saved value (immediately in the doc)', ->
      expect(stub._doc.child).to.equal 'mutated'

    it 'mutates the saved value (immediately on the model)', ->
      expect(stub.child()).to.equal 'mutated'

    it 'mutates the saved value (in the DB)', ->
      expect(TestModels.findOne().child).to.equal 'mutated'



  describe 'DocumentModel: [beforeSave] filter - on [setDefaultValues]', ->
    stub = null
    beforeEach ->
      TestModel.deleteAll()
      stub = new Stub().insertNew()

    it 'invokes the before save filter', ->
      stub.foo 'value-1'

      callbackResult = { count:0 }
      stub.foo.beforeSave = (value) ->
        callbackResult.count += 1
        callbackResult.value = value

      stub.setDefaultValues()
      expect(callbackResult.count).to.equal 1
      expect(callbackResult.value.to).to.equal 'value-1'


# ----------------------------------------------------------------------


describe 'DocumentModel.singleton', ->


