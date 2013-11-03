assert = require 'assert'
users = require '../lib/users.js'
Mongolian = require 'mongolian'
mongoConnection = "mongo://localhost:27017/test_login"
db = new Mongolian mongoConnection
t = require 'timed'
fs = require 'fs'
sinon = require 'sinon'

col = db.collection 'users'

users.config { connect: mongoConnection }

col.remove()

describe 'login-mongo', ->
  describe 'config', ->
    it 'should extend the config object and create a connection', ->
      col.remove()
      assert.equal users.opts.mail.mailer, 'sendmail'
      users.config { mail: { bodyadd: 'test' } }
      assert.ok users.opts.mail?
      assert.equal users.opts.mail.bodyadd, 'test'
      assert.equal users.opts.mail.mailer, 'sendmail'

  describe 'checkExists', ->
    it 'should return true if user with that email exists or false if not', (done) ->
      col.remove()
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

  makeFakeSender = ->
    fakeSender = { sendMail: -> }
    sendMail = sinon.stub fakeSender, 'sendMail'
    sendMail.returns { message: '..' }
    fakeSender 

  describe 'add', ->
    it 'should add a user and send a welcome email based on the config', (done) ->
      col.remove()
      fakeSender = makeFakeSender()
      conf =
        mail:
          bodyadd: "{{name}}"
          mailer: fakeSender
      users.config conf
      e, ret = users.add! 'eddie@home.com', 'eddie', 'pass'
      e, user = col.findOne! { name: 'eddie' }
      assert.ok user?
      sendMailArgs = fakeSender.sendMail.getCall(0).args[0]

      assert.equal sendMailArgs.text, 'eddie'
      done()
  
  describe 'resetPassword', ->
    it 'resets a users password to a random password and sends an email', (done) ->
      fakeSender = makeFakeSender()
      conf = { mail: { bodyreset: "{{name}}" } }
      users.config conf
      tempPass = users.resetPassword! 'eddie'
      done()


