# Data: Models
The `Data` namespace contains a system for wrapping business
logic around Mongo documents. These are called "Models".

A Model is a logical representation of the system, typically data.
For our purposes, the model is a logical wrapper around a Mongo
document, providing the following benefits:

- Provides an abstraction around the document, providing a singular
  read/write point to the DB making it possible to intercept updates,
  manipulate values before reading or writing, and ensure the logical
  integrity of the document.

- A place to associate logic that corresponds to the document ("methods").


Once model's are in place, it is good practice to perform all operations on the data via these models. Dropping back to using raw Collections results in a "leaky abstraction" and much of the advantages above are lost.

If you feel you need to use a collection directly, look at what you are doing, and see if you can make it a feature of the model via a method.



### MVC - Model/View/Controller
Models are the "M" in traditional "MVC". In our case, the `Ctrl` system
provides the "V" (or View).  The Ctrl also acts more along the lines of a
"view-model" when considering the MVVM variant of MVC.

"Controllers" also show up in the system, but it's important to call out that
controllers here operate more like traditional controllers from MVC, and not
like the concept of a controller in Rails, which can cause all manner of
confusion if you try to think in those terms (ie. page-redraw).


## Models and Schemas
There are three main classes within the `Data` system:

- `Data.Schema`
- `Data.Model`
- `Data.DocumentModel`



## Models and Schemas
Mongo is a schema-less document store. Schemas in the `Data` system
define the structure of a document, and form the basis of a model.

A basic schema looks like this:

    class MySchema extends Data.Schema
      constructor: -> super
        text: 'My Default'

    MySchema.init()

Initializing the schema with `.init()` locks in the fields.  Leave the
schema uninitialized if the schema will be derived from (see below).

You can specify specific data types for fields, for example a date:

    class MySchema extends Data.Schema
      constructor: -> super
        createdAt:
          default:  undefined
          type:     date



### Models
A `Model` is an object that exposes read/write property functions to a document object. The document that the model represents is passed into the constructor.


      class MyModel extends Data.Model
        constructor: (doc) ->
          super doc, MySchema

      instance = new MyModel()
      myText = instance.text()


The model's primary function is to map property functions to the underlying document, and to track changes.

#### Model vs DocumentModel
The Model is a simple starting point.  Later on, we extend the Model to be a `DocumentModel` which **"is a"** Model but also contains functionality for saving to the DB.  That will be what you're typically working.  You will most often see a Model being used, instead of a DocumentModel, when it maps to a sub-document.  But more on that later.


#### Reading Properties
By way of the `MySchema` definition, a function named `text` is automatically added to the model.

This function conforms to the "Property Function" pattern in that
invoking it with no parameters is considered a **read** operation, and passing a value to it is considered a **write**.

Reading from the property is reactive.

Reading will return the corresponding field from the document, or the default value defined in the schema if the field is `undefined` within the document.

#### Writing Properties
Write to the model by passing a value to the property function:

      instance = new MyModel()
      instance.text('My new value')


#### Writing Null
You cannot write `undefined` to a property, as that is the equivalent of a read operation:

      # Equivalent:
      instance = new MyModel()
      instance.text()
      instance.text(undefined)

Typically, you would clear a value by setting it to `null`:

      instance.text(null)

Alternatively, to reset the field to `undefined` use the delete method on the field:

      instance.text.delete()





#### Changes ("Dirty Models")
A model will track changes after being written to.  This is sometimes referred to as the model being "dirty".  To determine if a model is diry, check the `changes` property:

      instance = new MyModel()
      instance.changes() # Null - no changes yet.

Once a change has been made an object will be returned containing the before/after values of the changed fields:

      instance.text('Foo')
      instance.changes() # Object - the change set.

      {
        text: {
          from: 'My Default'
          to: 'Foo'
        }
      }

#### Reverting Changes
If you want to restore the model to it's unchanged state use the `revertChanges` method.

      instance = new MyModel()
      instance.text('Foo')
      instance.revertChanges()
      instance.text()    # Original value.
      instance.changes() # Null - no changes.



### Mapped Fields
Sometimes you want a model to map different field names on a document.  This might be because you want to improve the less than desirable names that has been used in the DB historically.

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



Or, you may need to path into a deeper object within the document. A classic example of this is the Meteor `User` document, which stores use details on a child `profile` object:


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





## DocumentModel
Everything up to this point has been about operating on a document, but there has been no explicit knowledge about how that document relates to Mongo.  This is useful when dealing with "sub-models" (see below), but mostly you'll be wanting to deal with a Model that store data in the DB.

For that we derive the `Data.DocumentModel` and tell it what collection it pertains to.


      MyCollection = new Meteor.Collection('my-collection')


      class MySchema extends Data.Schema
        constructor: -> super
          text: 'My Default'


      class MyModel extends Data.DocumentModel
        constructor: (doc) ->
          super doc, MySchema, MyCollection


The model now knows what collection to store values within, and so changes can be persisted to the database.


### Inserting a New Model
You can create a new document that does not yet exist in the DB by instantiating an instance of the model without passing it a document.

At this time it will not yet have an `id`. You can put the model into it's initial state for saving by writing it's property values. If you do not write explicity to a property, it's default value will be stored upon first save.

To save the new model to the database, use the `insertNew` method.

        instance = new MyModel()
        instance.text('Hello doc')
        instance.insertNew()

If you want to create a new model and have it immediately put into the database prior to starting work with it, you can achieve this with one line using the return value from `insertNew`:

        instance = new MyModel().insertNew()


Once inserted, the `id` property will be set.  This maps to the `_id` value of the Mongo document.  The existence of this value tells you whether a model exists within the database.


### Saving Changes
Once you have made changes to the model's property functions, it will be in a dirty state, and the `changes()` method will contain a set of values to be persisted.

The simplest way to commit these changes to the database is to use the `saveChanges` method:

        instance = new MyModel().insertNew()
        instance.text('Charles Eames')
        instance.saveChanges()

For finer grained control of which fields are changed see the `updateFields` method.


#### Saving from a Property Function
If you only have a single property change to make, and you want to commit that immediately to the database, you can pass the `save` option to the property method.

      instance.text('Charles Eames', save:true)



## Dervied Schemas
In some cases you want to extend an existing schema.  An example might be extending the `Auth.UserSchema`.  In the following example the "language" field has been added to the standard User:


      class MyUserSchema extends Auth.UserSchema
        constructor: -> super
          language: 'en'


To write an extendable schema, pass fields through the constructor:

      class MyBaseSchema extends Data.Schema
        constructor: (fields...) -> super fields,
          text: 'My Text'

      class MyChildSchema extends MyBaseSchema
        constructor: -> super
          number: 1234



## Commonly Used Fields (Mixins)
Rather than inheriting from a Schema you may want to just mixin commonly used fields.  A typical example of this is using standard date fields (`createdAt` and `updatedAt`).  You can do this by passing the fields to the base class.

      class ServerMetricsSchema extends Data.Schema
        constructor: (fields...) -> super fields, Data.Schema.dateFields,
          metrics:  undefined
          server:   undefined
          hostname: undefined


The reusable field mixins can be any object that conforms can be interpreted by the schema, for example:

      ###
      The common date fields applied to objects.
      ###
      Schema.dateFields =
        createdAt:  # The date the model was created.
          default:  undefined
          type:     Date

        updatedAt:  # The date the model was last updated in the DB.
          default:  undefined
          type:     Date




## Sub-models (ModelRef)
One of the strengths of Mongo is that it allows sub-documents.
We map these to sub-models using the `modelRef` declaration within a schema:


    class PersonSchema extends Data.Schema
      constructor: -> super
        name:
          modelRef: (doc) -> new Name(doc)

    class NameSchema extends Data.Schema
      constructor: -> super
        first: 'Unnamed'
        last:  undefined


    class Person extends Data.DocumentModel
      constructor: (doc) -> super doc, PersonSchema, MyCollection

    class Name extends Data.Model
      constructor: (doc) -> super doc, NameSchema


This constructs a sub-model on the parent model and allows us to directly dot (.) into it.  For example:

      doc =
        name:
          first: 'Phil'
          last:  'Foo'

      person = new Person(doc)

      person.name.first()       # <== 'Phil'
      person.name.last()        # <== 'Foo'

      person.isSubModel()       # <== false
      person.name.isSubModel()  # <== true


Modifications to the sub-model's properties show up on the parent model's `changes` object.


## Joins (HasOne)
When a model is logically related to another model in a different collection, you can "lazily" join these models using the `hasOne` schema declaration.

      class PersonSchema extends Data.Schema
        constructor: -> super
          shrink: ->
            default: null
            hasOne:
              key: 'shrink'
              modelRef: (id) -> Person.findOne(id)

      class Person extends Data.DocumentModel
        constructor: (doc) -> super doc, PersonSchema, MyCollection

      Person.findOne = (id) ->
        if doc = MyCollection.findOne(id)
          return new Person(doc)

The person's "shrink" is setup as a `hasOne` join with a key of "shrink".  By convention, this maps to a field on the document of `shrinkRef` being the ID of the `Person` that is the person's shrink.

The example above makes a join to the same `type` of model (`Person`) however that is not a limitation, and you can return any kind of model type from the `hasOne` join.

Note that this does not create the joined model at time of construction (like the `modelRef` declaration does) rather it requires an explicit call to the method.  In this way, we "lazily" load the joined model only when and if it is needed.




## Methods
Associate logic with the model wherever it makes conceptual sense.  For instance, if there is a question you are asking of the model in calling code that requires a few lines to interpret the values, but that question could reasonably asked in other parts of the system, consider making that a feature of the model by adding it as a method.

For example:

      class Foo extends Data.Model
        constructor: (doc) ->
          super doc, MySchema

        ###
        Puts the model into an archived state, and
        cleans up all related models.
        ###
        archive: -> # ...



## Common Class Methods
Lookup methods are generally added as class methods to the models.  These symatically match the way Mongo treads the `find` and `findOne` methods.


### Find
The `find` method retrieves an array of models.  Here is a typical implementation with the stanard `as` option defaulting to "model".

      ###
      Finds the specified people.
      @param selector: The mongo selector.
      @param options:
                as:  Optional. Flag indicating if models should be returned.
                      Values:
                        - 'cursor'
                        - 'models' (default)
                sort: Mongo sort order.
      ###
      Person.find = (selector = {}, options = {}) ->
        cursor = MyCollection.find(selector, options)
        switch (options.as ?= 'models')
          when 'cursor' then cursor
          when 'models' then cursor.map (doc) -> new Person(doc)

The option to return a cursor allows for flexibility when:

1. You specifically need a cursor for things like publishing the data (`Meteor.publish`).

2. The result would be large, and converting it to an array models would be needlessly expensive.  For instance, if you only needed the `count`.

Once the standard `find` method has be implemented, you may consider adding additional lookup methods if they are commonly used for the model.  For instance:


    User.findByTwitterName()
    Organization.findByHostName()


### FindOne
The `findOne` method returns a single model, or nothing if not found.  Here is a typical implementation:


      Person.findOne = (id) ->
        id = Util.toId(id)
        if doc = MyCollection.findOne(id)
          return new Person(doc)

Notice that:

1. The ID is formatted using the `Util.toId` method that corrects for whether a string, or object `{id:123}`, `{_id:123}` is passed.

2. The model is only created if a document was actually found within from the collection.







