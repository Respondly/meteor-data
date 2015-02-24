Schema        = Data.Schema
Model         = Data.Model
DocumentModel = Data.DocumentModel

FooSchema     = null
BarSchema     = null
Foo = null
Bar = null
doc1 = null
doc2 = null

fnFactory = (id) ->
  doc = TestModels.findOne(id)
  new Bar(doc) if doc


init = ->
  class Foo extends DocumentModel
    constructor: (doc) -> super doc, FooSchema, TestModels

  class Bar extends DocumentModel
    constructor: (doc) -> super doc, BarSchema, TestModels

  class FooSchema extends Schema
    constructor: -> super
      fooRef:
        hasOne:
          key:        'foo'
          modelRef:   fnFactory

  class BarSchema extends Schema
    constructor: -> super
      text: undefined


  # Reset the collection.
  TestModel.deleteAll()
  TestModels.insert {text:'one'}
  TestModels.insert {text:'two'}

  doc1 = TestModels.find().fetch()[0]
  doc2 = TestModels.find().fetch()[1]



describe 'Model reference function', ->
  beforeEach -> init()

  it 'has a reference function', ->
    stub = new Foo()
    expect(stub.foo).to.exist

  it 'has the [hasOne] definition attached', ->
    stub = new Foo()
    expect(stub.foo.hasOne).to.exist


# ----------------------------------------------------------------------


describe 'Reading HasOne reference', ->
  beforeEach -> init()

  it 'retrieves nothing when reference property is not set', ->
    foo = new Foo()
    expect(foo.foo()).to.equal undefined

  it 'retreives the referenced model', ->
    stub = new Foo()
    stub.fooRef doc1._id
    expect(stub.foo()).to.be.an.instanceOf Bar
    expect(stub.foo()._doc).to.eql doc1

  it 'returns nothing if the reference is not found', ->
    stub = new Foo()
    stub.fooRef 99
    expect(stub.foo()).to.equal undefined

  it 'caches the referenced model', ->
    stub = new Foo()
    stub.fooRef doc1._id
    foo1 = stub.foo()
    foo2 = stub.foo()
    expect(foo1).to.equal foo2

  it 'refreshes the cached model', ->
    stub = new Foo()
    bar = new Bar(doc1)
    stub.foo(bar)
    stub.foo() # Model is now cached.

    bar.text 'new-value', save:true
    stub.foo().refresh()
    expect(stub.foo().text()).to.equal 'new-value'


  it 'retrieves new model when ref-property is changed.', ->
    stub = new Foo()
    stub.fooRef doc1._id
    stub.foo()
    stub.foo()

    stub.fooRef doc2._id
    expect(stub.foo()._doc).to.eql doc2

  it 'writes to the ref-property', ->
    stub  = new Foo()
    stub.foo( new Bar(doc2) )
    expect(stub.foo()._doc).to.eql doc2


# ----------------------------------------------------------------------


describe 'errors', ->
  beforeEach -> init()

  it 'throws if field already exists', ->
    class FooExists extends Model
      constructor: -> super null, FooSchema
      foo: 'hello'
    fn = -> new FooExists()
    expect(fn).to.throw /The field 'foo' already exists./


  it 'throws if the hasOne reference does not have a [key]', ->
    class FailSchema extends Schema
      constructor: -> super
        fooRef:
          hasOne:
            type: ->
            collection: ->
    fn = -> new FailSchema()
    expect(fn).to.throw /HasOne ref for 'fooRef' does not have a key./


  it 'throws if the hasOne reference does not have a [modelRef]', ->
    class FailSchema extends Schema
      constructor: -> super
        fooRef:
          hasOne:
            key: 'foo'
    fn = -> new FailSchema()
    expect(fn).to.throw /HasOne ref for 'fooRef' does not have a modelRef./


# ----------------------------------------------------------------------



describe 'Write filters', ->
  beforeEach -> init()

  it 'calls the [beforeWrite] filter (via ID ref property)', ->
    stub = new Foo()
    count = 0
    value = null
    stub.fooRef.beforeWrite = (v) ->
        count += 1
        value = v

    stub.fooRef doc2._id
    expect(count).to.equal 1
    expect(value).to.equal doc2._id

  it 'calls the [beforeWrite] filter (via modelRef property)', ->
    stub = new Foo()
    count = 0
    value = null
    stub.fooRef.beforeWrite = (v) ->
          count += 1
          value = v

    stub.foo( new Bar(doc2) )
    expect(value).to.equal doc2._id
    expect(count).to.equal 1

  it 'calls the [afterWrite] filter (via ID ref property)', ->
    stub = new Foo()
    count = 0
    value = null
    stub.fooRef.afterWrite = (v) ->
        count += 1
        value = v
    stub.fooRef doc2._id
    expect(count).to.equal 1
    expect(value).to.equal doc2._id

  it 'calls the [afterWrite] filter (via modelRef property)', ->
    stub = new Foo()
    count = 0
    value = null
    stub.fooRef.afterWrite = (v) ->
          count += 1
          value = v

    stub.foo( new Bar(doc2) )
    expect(value).to.equal doc2._id
    expect(count).to.equal 1



