describe 'core.Schema (modelRef)', ->
  Schema        = null
  ParentSchema  = null
  RootModel     = null
  RefModel      = null
  RootSchema    = null
  RefSchema     = null
  fnFactory = (doc) -> new RefModel(doc)


  beforeEach ->
    Schema = Data.Schema
    class ParentSchema extends Schema
      constructor: (fields) ->
        super fields,
          parent: 123
          base:   'base'


  beforeEach ->
    class RootSchema extends Data.Schema
      constructor: -> super
        foo:        123
        myObjRef:
          modelRef: fnFactory
          default: 'should-not-store'

    class RefSchema extends Data.Schema
      constructor: -> super
        bar: 'abc'

    class RootModel extends Data.Model
      constructor: -> super null, RootSchema

    class RefModel extends Data.Model
      constructor: -> super null, RefSchema


  it 'references a model (from object)', ->
    root   = new RootModel()
    field  = root.db.fields.myObjRef
    expect(field.modelRef).to.equal fnFactory



