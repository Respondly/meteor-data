#= base
@expect = chai.expect


if Meteor.isClient
  Meteor.startup -> $('title').html('Tests: data (model/schema)')


# ----------------------------------------------------------------------


@TestModels = new Meteor.Collection('test-models')


@TestModelSchema = class TestModelSchema extends Data.Schema
  constructor: -> super
    text: null
    number: -1
    flag: false


@TestModel = class TestModel extends Data.DocumentModel
  toString: -> "text:#{@text()}; flag:#{@flag()};"
  constructor: (doc) ->
    super doc, TestModelSchema, TestModels


TestModel.deleteAll = ->
  TestModels.remove(doc._id) for doc in TestModels.find({}).fetch()


TestModel.find = (selector = {}) ->
  TestModels.find({}).map (doc) -> new @TestModel(doc)
