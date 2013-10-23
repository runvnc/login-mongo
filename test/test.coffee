assert = require 'assert'
users = require '../lib/users.js'
Mongolian = require 'mongolian'
mongoConnection = "mongo://localhost:27017/test_login"
db = new Mongolian mongoConnection
t = require 'timed'
fs = require 'fs'

col = db.collection 'users'

col.remove()

users.config { connect: mongoConnection }

describe 'login-mocha', ->
  describe 'checkExists', ->
    it 'should return true if user with that email exists or false if not', (done) ->
      found = users.checkExists! 'bob@home.com'
      assert.equal found, false
      t.reset()
      col.insert! { name: 'bob', email: 'bob@home.com' }
      console.log "insert elapsed: #{t.rounded()} ms"
      foundnow = users.checkExists! 'bob@home.com'
      assert.equal foundnow, true
      col.remove()
      done()

  describe 'addNoEmail', ->
    it 'should add a user to the configured db and collection with password hash', (done) ->
      users.addNoEmail! 'bob@home.com', 'bob', '123'
      e, user = col.findOne! { name: 'bob', email: 'bob@home.com' }
      assert.ok user?
      assert.equal user.email, 'bob@home.com'
      done()




