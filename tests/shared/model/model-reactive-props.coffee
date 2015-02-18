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

    it 'is reactive on read operation (by default)', (done) ->
      stub = new MyModel()

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
      stub = new MyModel()
      expect(stub.value.dependency).to.equal undefined
      stub.value()
      expect(stub.value.dependency).to.be.an.instanceOf Tracker.Dependency


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


  describe 'Reactive updates via Mongo', (done) ->
    beforeEach -> TestModel.deleteAll()

    it 'updates a model when the data-source changes', ->
      model1 = new MyModel().insertNew()
      model2 = MyModel.find({_id:model1.id})[0]
      expect(model1.value()).to.equal model2.value()

      model1.value('new value', save:true)
      Util.delay =>
        expect(model1.value()).to.equal model2.value()


    it 'disposes of the model when removed from DB', ->
      model = new MyModel().insertNew()
      expect(model.isDisposed).not.to.equal true
      TestModels.remove(_id:model.id)
      Util.delay =>
        expect(model.isDisposed).to.equal true


