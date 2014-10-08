MySchema    = null
MySubSchema = null
MyModel     = null
MySubModel  = null
model       = null


initModels = ->
  TestModel.deleteAll()

  class MySchema extends Data.Schema
    constructor: -> super
      number: 5
      text: 'DefaultText'
      foo: undefined
      subModel:
        modelRef: (doc) -> new MySubModel(doc)

  class MySubSchema extends Data.Schema
    constructor: -> super
      name: undefined

  class MyModel extends Data.DocumentModel
    constructor: (doc) ->
      super doc, MySchema, TestModels

  class MySubModel extends Data.SubModel
    constructor: (doc) ->
      super doc, MySubSchema

  model = new MyModel()


# ----------------------------------------------------------------------



describe 'Check: simple checks (calibrate tests)', ->
  it 'is a String', ->
    expect(Match.test("Foo", Match.OneOf(null, String))).to.equal true

  it 'is not a String', ->
    expect(Match.test(true, Match.OneOf(null, String))).to.equal false


  it 'calibrate model (not using helper method)', ->
    initModels()
    model.foo('Hello')
    changes = model.changes()
    changeMatch = foo:{ from:Match.OneOf(undefined, String), to:Match.OneOf(undefined, String) }
    expect(Match.test(changes, changeMatch)).to.equal true



# ----------------------------------------------------------------------



describe 'Match: root model changes', ->
  beforeEach -> initModels()

  it 'pass: from <undefined> to String', ->
    model.foo('Hello')
    changes = model.changes()

    changeMatch = Data.match.changes(foo:String)
    expect(Match.test(changes, changeMatch)).to.equal true

  it 'pass: from <undefined> to String or Boolean', ->
    model.foo(true)
    changes = model.changes()
    changeMatch = Data.match.changes(foo:Match.OneOf(String, Boolean))
    expect(Match.test(changes, changeMatch)).to.equal true


  it 'fail: from <undefined> to String', ->
    model.foo(true)
    changes = model.changes()
    changeMatch = Data.match.changes(foo:String)
    expect(Match.test(changes, changeMatch)).to.equal false

  it 'fail: from <undefined> to String or Boolean', ->
    model.foo(123)
    changes = model.changes()
    changeMatch = Data.match.changes(foo:Match.OneOf(String, Boolean))
    expect(Match.test(changes, changeMatch)).to.equal false


# ----------------------------------------------------------------------


describe 'Match: sub-model', ->
  beforeEach -> initModels()

  it 'pass: from <undefined> to String or Boolean on sub-model', ->
    model.subModel.name('Foo')
    changes = model.changes()
    def =
      subModel:
        name: Match.OneOf(String, Boolean)
    changeMatch = Data.match.changes(def)
    expect(Match.test(changes, changeMatch)).to.equal true

  it 'fail: from <undefined> to String or Boolean on sub-model', ->
    model.subModel.name(123)
    changes = model.changes()
    def =
      subModel:
        name: Match.OneOf(String, Boolean)
    changeMatch = Data.match.changes(def)
    expect(Match.test(changes, changeMatch)).to.equal false



# ----------------------------------------------------------------------



describe 'Data.check.changes', ->
  beforeEach -> initModels()

  it 'passes', ->
    model.foo(true)
    model.subModel.name('Foo')
    changes = model.changes()

    Data.check.changes changes,
      foo: Boolean
      subModel:
        name: String


  it 'fails on on root model', ->
    model.foo('String')
    model.subModel.name('Foo')
    changes = model.changes()
    fn = ->
        Data.check.changes changes,
          foo: Boolean
          subModel:
            name: String
    expect(fn).to.throw(/Failed Match/)


  it 'fails on on sub model', ->
    model.foo(true)
    model.subModel.name(123)
    changes = model.changes()
    fn = ->
        Data.check.changes changes,
          foo: Boolean
          subModel:
            name: String
    expect(fn).to.throw(/Failed Match/)







