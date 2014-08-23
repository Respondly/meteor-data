# describe 'core.Schema (modelRef)', ->
#   Schema        = null
#   ParentSchema  = null
#   RootModel     = null
#   RefModel      = null
#   RootSchema    = null
#   RefSchema     = null
#   fnFactory = (doc) -> new RefModel(doc)


#   beforeEach ->
#     Schema = APP.core.Schema
#     class ParentSchema extends Schema
#       constructor: (fields) ->
#         super fields,
#           parent: 123
#           base:   'base'


#   beforeEach ->
#     class RootSchema extends APP.core.Schema
#       constructor: -> super
#         foo:        123
#         myObjRef:
#           modelRef: fnFactory
#           default: 'should-not-store'

#     class RefSchema extends APP.core.Schema
#       constructor: -> super
#         bar: 'abc'

#     class RootModel extends APP.core.Model
#       constructor: -> super null, RootSchema

#     class RefModel extends APP.core.Model
#       constructor: -> super null, RefSchema


#   it 'references a model (from object)', ->
#     root   = new RootModel()
#     field  = root.fields.myObjRef
#     expect(field.modelRef).to.equal fnFactory



