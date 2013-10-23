#This is actually ToffeeScript
passwordHash = require 'password-hash'
randpass = require 'randpass'
fs = require 'fs'
nodemailer = require 'nodemailer'
Mongolian = require 'mongolian'
und = require 'underscore'
mustache = require 'mustache'

server = null
db = null
users = null

opts =
  mail:
    from: 'root'
    subjectadd: 'User account created'
    bodyadd: "Username: {{name}} password: {{pass}"
    bodyreset: "Username: {{name}} password: {{pass}}"

smtp = nodemailer.createTransport "Sendmail", "/usr/sbin/sendmail"

config = (options) ->
  und.extend opts, options
  if options.connect?
    db = new Mongolian options.connect
  else
    db = new Mongolian 'mongo://localhost:27017/users'
  if options.collection?
    users = db.collection options.collection
  else
    users = db.collection 'users'
    
config {}

checkExists = (email, cb) ->
  e, existing = users.findOne! { email: email }
  cb existing?


addNoEmail = (email, name, pass, cb) ->
  if not checkExists! email
    users.insert { email, name, passhash: passwordHash.generate pass } 
    cb?()
  else
    cb?()

add = (email, name, cb) =>
  existing = checkExists! email
  if not checkExists! email
    pass = randpass()
    newuser = { email, name, passhash: passwordHash.generate pass }
    users.insert! newuser    
    rendered = mustache.render opts.bodyadd, newuser
    try
      options =
        from: opts.from
        to: email
        subject: opts.subjectadd
        text: rendered
      smtp.sendMail options, (err, res) ->
        if err?
          console.log err
        else
          console.log 'Message sent: ' + res.message
    catch e
      console.log 'Error sending user mail' + e.message
      console.log e
    cb?()
  else
    cb?()


resetPassword = (name) =>
  e, user = users.findOne! { name: name }
  if user?
    pass = randpass()
    user.passhash = passwordHash.generate pass
    users.update { name: name }, user
    rendered = mustache.render opts.bodyreset, user
    try
      options =
        from: opts.from
        to: users[name].email
        subject: 'User password reset'
        text: rendered
      smtp.sendMail options, (err, res) ->
        if err?
          console.log err
        else
          console.log 'Message sent: ' + res.message
    catch e
      console.log 'Error sending user mail' + e.message
      console.log e


updatePassword = (username, oldpass, newpass) =>
  if not checkPassword(username, oldpass)
    return false
  else
    users[username].passhash = passwordHash.generate newpass
    save()
    return true

checkPassword = (username, pass, cb) =>
  e, user = users.findOne! { name: username }
  if user?
    return passwordHash.verify pass, user.passhash
  else
    return false

exports.config = config
exports.add = add
exports.checkExists = checkExists
exports.resetPassword = resetPassword
exports.updatePassword = updatePassword
exports.checkPassword = checkPassword
exports.addNoEmail = addNoEmail
exports.users = users



