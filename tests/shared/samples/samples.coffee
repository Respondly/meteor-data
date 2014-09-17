describe 'Model', ->
  class MySchema extends Data.Schema
    constructor: -> super
      text: 'My Default'
  # MySchema.init()


  class MyModel extends Data.Model
    constructor: (doc) ->
      super doc, MySchema




  it 'Schema', ->
    console.log 'MySchema', MySchema
    console.log 'MySchema.fields', MySchema.fields
    console.log ''


  it 'Simple Model', ->
    instance = new MyModel()
    console.log 'instance', instance
    console.log ''


  it 'Reading Properties', ->
    instance = new MyModel()
    console.log 'instance.text (default):', instance.text()

    instance = new MyModel({ text:'foo' })
    console.log 'instance.text:', instance.text()
    console.log ''


  it 'Writing Properties', ->
    instance = new MyModel()
    instance.text('My new value')
    console.log 'instance.text:', instance.text()
    console.log ''


  it 'Changes', ->
    instance = new MyModel()
    instance.changes() # Null - No changes yet.
    console.log 'changes:', instance.changes()

    instance.text('Foo')
    console.log 'changes:', instance.changes()
    console.log ''

    changes =
      text:
        from: 'My Default'
        to: 'Foo'

  it 'Map Fields: Change Name', ->

    class FooSchema extends Data.Schema
      constructor: -> super
        text:
          field: 'jellyBeans'
          default: 'My Title'

    class Foo extends Data.Model
      constructor: (doc) ->
        super doc, FooSchema

    instance = new Foo({ jellyBeans:'Hello' })
    console.log 'text:', instance.text() # Returns: 'Hello'


  it 'Map Fields: Deep', ->

    class FooSchema extends Data.Schema
      constructor: -> super
        name:
          field: 'profile.name'
          default: 'Unnamed'

    class Foo extends Data.Model
      constructor: (doc) ->
        super doc, FooSchema

    instance = new Foo({ profile:{ name:'Jane' }})
    console.log 'name:', instance.name() # Returns: 'Jane'





describe 'DocumentModel', ->
  MyCollection = new Meteor.Collection('my-collection')


  class MySchema extends Data.Schema
    constructor: -> super
      text: 'My Default'


  class MyModel extends Data.DocumentModel
    constructor: (doc) ->
      super doc, MySchema, MyCollection

  it 'insertNew', ->
    instance = new MyModel()
    instance.text('Hello doc')
    instance.insertNew()
    console.log 'instance', instance


  it 'save', ->
    instance = new MyModel().insertNew()
    instance.text('Hello doc')
    instance.saveChanges()







