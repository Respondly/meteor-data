MyRootSchema    = null
MySubSchema     = null
MyModel         = null
MySubModel      = null
model           = null
subModel        = null


initModels = ->
  TestModel.deleteAll()

  class MyRootSchema extends Data.Schema
    constructor: -> super
      text: undefined
      subModel:
        modelRef: (doc) -> new MySubModel(doc)

  class MySubSchema extends Data.Schema
    constructor: -> super
      name: 'My Name'



  class MyRoot extends Data.DocumentModel
    constructor: (doc) ->
      super doc, MyRootSchema, TestModels

  class MySubModel extends Data.SubModel
    constructor: (doc) ->
      super doc, MySubSchema

  model = new MyRoot().insertNew()
  subModel = model.subModel


# ----------------------------------------------------------------------



describe 'SubModel', ->
  beforeEach -> initModels()

  it 'is [isSubModel]', ->
    expect(subModel.isSubModel()).to.equal true


  it 'is not [isSubModel]', ->
    expect(model.isSubModel()).to.equal false


  it 'has [parentModel]', ->
    expect(subModel.parentModel).to.equal model


  it 'has [parentField]', ->
    expect(subModel.parentField.key).to.equal 'subModel'


# ----------------------------------------------------------------------


describe 'SubModel.toValues', ->
  beforeEach -> initModels()

  it 'reports sub-model on [toValues] output', ->
    model.text('Hello')
    model.subModel.name('I am sub-model')
    values = model.toValues()
    expect(values.text).to.equal 'Hello'
    expect(values.subModel.name).to.equal 'I am sub-model'


# ----------------------------------------------------------------------


describe 'SubModel: Changes', ->
  beforeEach -> initModels()

  it 'does not have changes', ->
    expect(subModel.name()).to.equal 'My Name'

  it 'has changes on sub-model', ->
    subModel.name('Phil')
    expect(subModel.changes().name.from).to.equal 'My Name'
    expect(subModel.changes().name.to).to.equal 'Phil'

  it 'has changes on parent-model', ->
    subModel.name('Phil')
    expect(model.changes().subModel.name.from).to.equal 'My Name'
    expect(model.changes().subModel.name.to).to.equal 'Phil'


# ----------------------------------------------------------------------


describe.client 'SubModel: Changes (Reactive)', ->
  beforeEach -> initModels()

  it 'reactively changes sub-model', (done) ->
    changes = undefined
    Tracker.autorun -> changes = subModel.changes()
    subModel.name('Phil')
    Util.delay =>
      expect(changes.name.from).to.equal 'My Name'
      expect(changes.name.to).to.equal 'Phil'
      done()

  it 'reactively reverts changes sub-model', (done) ->
    changes = undefined
    Tracker.autorun -> changes = subModel.changes()
    subModel.name('Phil')
    Util.delay =>
      Util.delay =>
        expect(changes.name.to).to.equal 'Phil'
        subModel.revertChanges()
        Util.delay =>
          expect(changes).to.equal null
          done()


# ----------------------------------------------------------------------


describe.client 'SubModel: Parent Model Changes (Reactive)', ->
  beforeEach -> initModels()

  it 'reactively changes parent-model', (done) ->
    changes = undefined
    Tracker.autorun -> changes = model.changes()
    subModel.name('Phil')
    Util.delay =>
      expect(changes.subModel.name.from).to.equal 'My Name'
      expect(changes.subModel.name.to).to.equal 'Phil'
      done()


  it 'reactively reverts changes parent-model', (done) ->
    changes = undefined
    Tracker.autorun -> changes = model.changes()
    subModel.name('Phil')
    Util.delay =>
      Util.delay =>
        subModel.revertChanges()
        Util.delay =>
          expect(changes).to.equal null
          done()
