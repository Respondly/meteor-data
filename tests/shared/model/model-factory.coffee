class FooSchema extends Data.Schema
  constructor: -> super
    text: 'hello'


class Foo extends Data.DocumentModel
  constructor: (doc) -> super doc, FooSchema, TestModels


class MyFactory extends Data.ModelFactory
  constructor: ->
    super TestModels, Foo
    @_onInsertNewCount = 0
    @_onCreateCount = 0

  onInsertNew: (model, options) ->
    @_onInsertNewCount += 1
    super

  onCreate: (doc) ->
    @_onCreateCount += 1
    super



myFactory = null




# ----------------------------------------------------------------------


describe 'ModelFactory', ->
  beforeEach ->
    TestModel.deleteAll()
    myFactory = new MyFactory()

  it 'creates a new instance of the model (auto ID)', ->
    expect(TestModels.find().count()).to.equal 0
    myFactory.insertNew()
    expect(TestModels.find().count()).to.equal 1

  it 'creates a new instance of the model (specified ID)', ->
    myFactory.insertNew({id:'yo'})
    expect(TestModels.findOne()._id).to.equal 'yo'

  it 'creates a new instance of the model (specified property)', ->
    myFactory.insertNew({text:'yo'})
    expect(TestModels.findOne().text).to.equal 'yo'

  it 'call [onInsertNew]', ->
    myFactory._onInsertNewCount = 0
    myFactory.insertNew()
    expect(myFactory._onInsertNewCount).to.equal 1

  it 'invokes [beforeInsert]', ->
    count = 0
    myFactory.beforeInsert -> count += 1
    myFactory.insertNew()
    expect(count).to.equal 1

  it 'invokes [onCreate]', ->
    myFactory._onCreateCount = 0
    myFactory.insertNew()
    expect(myFactory._onCreateCount).to.equal 1

  it 'invokes [afterCreate]', ->
    count = 0
    myFactory.afterCreate -> count += 1
    myFactory.insertNew()
    expect(count).to.equal 1


describe 'ModelFactory: getOrCreate', ->
  beforeEach ->
    TestModel.deleteAll()
    myFactory = new MyFactory()

  it 'creates a new object', ->
    expect(TestModels.find().count()).to.equal 0
    model = myFactory.insertNew()
    expect(TestModels.find().count()).to.equal 1
    expect(TestModels.findOne()._id).to.equal model.id

  it 'retrieves an existing object', ->
    model = myFactory.insertNew()
    expect(model.id).not.to.equal undefined
    expect(myFactory.getOrCreate(model.id).id).to.equal model.id
    expect(TestModels.find().count()).to.equal 1


describe 'ModelFactory: retrieval', ->
  beforeEach ->
    TestModel.deleteAll()
    myFactory = new MyFactory()

  it '.exists', ->
    model = myFactory.insertNew()
    expect(myFactory.exists(model.id)).to.equal true
    expect(myFactory.exists({_id:model.id})).to.equal true

  it '.findOne', ->
    model = myFactory.insertNew()
    expect(myFactory.findOne(model.id).id).to.equal model.id

  it '.find (as model)', ->
    model = myFactory.insertNew()
    expect(myFactory.find(model.id)[0].id).to.equal model.id

  it '.find (as cursor)', ->
    model = myFactory.insertNew()
    expect(myFactory.find(model.id, as:'cursor').fetch()[0]._id).to.equal model.id










