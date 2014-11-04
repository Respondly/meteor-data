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
      name: undefined



  class MyRoot extends Data.DocumentModel
    constructor: (doc) ->
      super doc, MyRootSchema, TestModels

  class MySubModel extends Data.SubModel
    constructor: (doc) ->
      super doc, MySubSchema

  model = new MyRoot().insertNew()
  subModel = model.subModel


# ----------------------------------------------------------------------



describe 'SubModel: Changes', ->
  beforeEach -> initModels()

  it 'does not have changes', ->
    expect(subModel.name()).to.equal undefined

  it 'has changes on sub-model', ->
    subModel.name('Phil')
    expect(subModel.changes().name.from).to.equal undefined
    expect(subModel.changes().name.to).to.equal 'Phil'

  it 'has changes on parent model', ->
    subModel.name('Phil')
    expect(model.changes().subModel.name.from).to.equal undefined
    expect(model.changes().subModel.name.to).to.equal 'Phil'

  # it 'reactively changes parent model', (done) ->
  #   changes = undefined
  #   Deps.autorun ->
  #       console.log '|| run'
  #       changes = model.changes()

  #   model.text('Foo')
  #   subModel.name('Phil')

  #   console.log 'model.changes()', model.changes()


  #   Util.delay 500, =>
  #     @try =>

  #       console.log 'changes', changes

  #       # console.log 'model.changes()', model.changes()
  #       console.log '||changes', changes
  #       console.log 'changes.subModel', changes.subModel
  #       console.log 'changes.subModel.name', changes.subModel.name
  #       console.log 'changes.subModel.from', changes.subModel.name.from
  #       console.log 'changes.subModel.to', changes.subModel.name.to
  #       console.log ''

  #       # expect(changes.subModel.name.from).to.equal undefined
  #       # expect(changes.subModel.name.to).to.equal 'Phil'




  #     done()








