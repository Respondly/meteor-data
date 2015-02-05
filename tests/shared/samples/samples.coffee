MyCollection = new Meteor.Collection('test-my-collection')


class MySchema extends Data.Schema
  constructor: -> super
    text: 'My Default'


class MyModel extends Data.DocumentModel
  constructor: (doc) ->
    super doc, MySchema, MyCollection



# MyCollection = new Meteor.Collection('my-collection')

# # describe 'My Suite', ->
# #   it 'does something cool', ->
# #     result = 1 + 1
# #     expect(result).to.equal 2



# describe 'Model', ->
#   class MySchema extends Data.Schema
#     constructor: -> super
#       text: 'My Default'
#   # MySchema.init()


#   class MyModel extends Data.Model
#     constructor: (doc) ->
#       super doc, MySchema




#   # it 'Schema', ->
#   #   console.log 'MySchema', MySchema
#   #   console.log 'MySchema.fields', MySchema.fields
#   #   console.log ''


#   it 'Simple Model', ->
#     instance = new MyModel()
#     console.log 'instance', instance
#     console.log ''


#   it 'Methods', ->










#   it 'Reading Properties', ->
#     instance = new MyModel()
#     console.log 'instance.text (default):', instance.text()

#     instance = new MyModel({ text:'foo' })
#     console.log 'instance.text:', instance.text()
#     console.log ''


#   it 'Writing Properties', ->
#     instance = new MyModel()
#     console.log 'instance', instance
#     instance.text('My new value')
#     console.log 'instance.text:', instance.text()
#     console.log ''


#   it 'Changes', ->
#     instance = new MyModel()
#     instance.changes() # Null - No changes yet.
#     console.log 'changes:', instance.changes()

#     instance.text('Foo')
#     console.log 'changes:', instance.changes()
#     console.log ''

#     changes =
#       text:
#         from: 'My Default'
#         to: 'Foo'


#   it 'Map Fields: Change Name', ->

#     class FooSchema extends Data.Schema
#       constructor: -> super
#         text:
#           field: 'jellyBeans'
#           default: 'My Title'

#     class Foo extends Data.Model
#       constructor: (doc) ->
#         super doc, FooSchema

#     instance = new Foo({ jellyBeans:'Hello' })
#     console.log 'text:', instance.text() # Returns: 'Hello'


#   it 'Map Fields: Deep', ->

#     class FooSchema extends Data.Schema
#       constructor: -> super
#         name:
#           field: 'profile.name'
#           default: 'Unnamed'

#     class Foo extends Data.Model
#       constructor: (doc) ->
#         super doc, FooSchema

#     instance = new Foo({ profile:{ name:'Jane' }})
#     console.log 'name:', instance.name() # Returns: 'Jane'





# describe 'DocumentModel', ->


#   class MySchema extends Data.Schema
#     constructor: -> super
#       text: 'My Default'
#       isEnabled: false
#       value: undefined


#   class MyModel extends Data.DocumentModel
#     constructor: (doc) ->
#       super doc, MySchema, MyCollection

#   it 'insertNew', ->
#     instance = new MyModel()
#     instance.text('Hello doc')
#     instance.insertNew()
#     console.log 'instance', instance


#   it 'save', ->
#     instance = new MyModel().insertNew()
#     instance.text('Hello doc')
#     instance.saveChanges()


#   it 'save default', ->
#     console.log ''

#     instance = new MyModel().insertNew()
#     id = instance.id

#     console.log 'id', id
#     doc = MyCollection.findOne(id)
#     console.log 'doc', doc
#     console.log ''


#   it 'delete field', ->


#     instance = new MyModel()
#     instance.text('Foo')
#     instance.insertNew()

#     console.log 'instance._doc', instance._doc

#     instance.text.delete()
#     console.log 'instance._doc', instance._doc

#     console.log 'instance.changes()', instance.changes()



# describe 'Sub Models', ->



#   class PersonSchema extends Data.Schema
#     constructor: -> super
#       name:
#         modelRef: (doc) -> new Name(doc)

#   class NameSchema extends Data.Schema
#     constructor: -> super
#       first: 'Unnamed'
#       last:  undefined


#   class Person extends Data.DocumentModel
#     constructor: (doc) -> super doc, PersonSchema, MyCollection

#   class Name extends Data.Model
#     constructor: (doc) -> super doc, NameSchema



#   it 'ref', ->
#     doc =
#       name:
#         first: 'Phil'
#         last:  'Foo'

#     person = new Person(doc)

#     console.log 'person', person

#     console.log person.name.first() # <== 'Phil'
#     console.log person.name.last()  # <== 'Foo'

#     console.log person.isSubModel()      # <== false
#     console.log person.name.isSubModel() # <== true

# describe 'Joins', ->


#   class PersonSchema extends Data.Schema
#     constructor: -> super
#       shrink: ->
#         default: null
#         hasOne:
#           key: 'shrink'
#           modelRef: (id) -> Person.findOne(id)


#   class Person extends Data.DocumentModel
#     constructor: (doc) -> super doc, PersonSchema, MyCollection

#   Person.findOne = (id) ->
#     id = Util.toId(id)
#     if doc = MyCollection.findOne(id)
#       return new Person(doc)



#   ###
#   Finds the specified people.
#   @param selector: The mongo selector.
#   @param options:
#             as:  Optional. Flag indicating if models should be returned.
#                   Values:
#                     - 'cursor'
#                     - 'models' (default)
#             sort: Mongo sort order.
#   ###
#   Person.find = (selector = {}, options = {}) ->
#     cursor = MyCollection.find(selector, options)
#     switch (options.as ?= 'models')
#       when 'cursor' then cursor
#       when 'models' then cursor.map (doc) -> new Person(doc)






#   it 'Joins', ->









