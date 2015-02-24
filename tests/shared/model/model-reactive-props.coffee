class MySchema extends Data.Schema
  constructor: -> super
    value: 0


class MyModel extends Data.DocumentModel
  constructor: (doc) ->
    super doc, MySchema, TestModels


MyModel.find = (selector = {}, options = {}) -> TestModels.find(selector, options).map (doc) -> new MyModel(doc)



# ----------------------------------------------------------------------

describe 'Reactivity', ->
  describe 'Reactive property-functions', ->
    beforeEach -> TestModel.deleteAll()

    it 'is not reactive by default', ->
      stub = new MyModel()
      expect(stub.db.isReactive).to.equal false

    it 'turns reactivity on via the `reactive` method', ->
      stub = new MyModel()
      expect(stub.db.isReactive).to.equal false
      stub.reactive()
      expect(stub.db.isReactive).to.equal true

    it 'turns reactivity off via the `reactive` method', ->
      stub = new MyModel()
      stub.reactive(true)
      expect(stub.db.isReactive).to.equal true
      stub.reactive(false)
      expect(stub.db.isReactive).to.equal false


    it 'is does not cause autorun to fire when not reactive', (done) ->
      stub = new MyModel()

      count = 0
      Deps.autorun ->
          stub.value(undefined)
          count += 1

      count = 0
      stub.value(1)

      Util.delay ->
        expect(count).to.equal 0
        done()


    it 'is reactive on read operation (default)', (done) ->
      stub = new MyModel().reactive()

      count = 0
      Deps.autorun ->
          stub.value(undefined)
          count += 1

      count = 0
      stub.value(1)

      Util.delay ->
        expect(count).to.equal 1
        done()


    it 'has a `dependency` on the field when read', ->
      stub = new MyModel().reactive()
      expect(stub.value.dependency).to.equal undefined
      stub.value()
      expect(stub.value.dependency).to.be.an.instanceOf Tracker.Dependency

    it 'does not have a `dependency` on the field when read', ->
      stub = new MyModel()
      expect(stub.value.dependency).to.equal undefined
      stub.value()
      expect(stub.value.dependency).to.equal undefined


    it 'is optionally non-reactive', (done) ->
      stub = new MyModel()
      count = 0
      Deps.autorun ->
          stub.value(undefined, isReactive:false)
          count += 1

      count = 0
      stub.value(1)

      Util.delay ->
          expect(count).to.equal 0
          done()



    it 'is not reactive for write operations', (done) ->
      stub = new MyModel()
      count = 0
      Deps.autorun ->
          stub.value(1234)
          count += 1

      count = 0
      stub.value(1)

      Util.delay ->
          expect(count).to.equal 0
          done()


  # ----------------------------------------------------------------------


  describe 'Reactive updates via Mongo', ->
    beforeEach -> TestModel.deleteAll()

    it 'updates a model when the data-source changes', ->
      model1 = new MyModel().insertNew().reactive()
      model2 = MyModel.find({_id:model1.id})[0].reactive()
      expect(model1.value()).to.equal model2.value()

      model1.value('new value', save:true)
      Util.delay =>
        expect(model1.value()).to.equal model2.value()


    it 'does not update when not set as reactive', ->
      model1 = new MyModel().insertNew()
      model2 = MyModel.find({_id:model1.id})[0]
      expect(model1.value()).to.equal model2.value()

      model1.value('new value', save:true)
      Util.delay =>
        expect(model1.value()).to.equal 'new value'
        expect(model2.value()).to.equal 0


    it 'disposes of the model when removed from DB', ->
      model = new MyModel().insertNew()
      expect(model.isDisposed).not.to.equal true
      TestModels.remove(_id:model.id)
      Util.delay =>
        expect(model.isDisposed).to.equal true


    describe.skip 'changes when syncing from DB', ->
      model1 = null
      model2 = null
      beforeEach ->
        TestModel.deleteAll()
        model1 = new MyModel().insertNew().reactive()
        model2 = MyModel.find({_id:model1.id})[0].reactive()

      it 'has not changes when DB is altered and there is not dirty value', (done) ->
        model1.value('Yo', save:true)
        Util.delay =>
          expect(model2.value()).to.equal 'Yo'
          console.log 'model1.changes()', model1.changes()
          console.log 'model2.changes()', model2.changes()
          done()

