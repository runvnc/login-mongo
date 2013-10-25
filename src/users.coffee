#This is actually ToffeeScript
passwordHash = require 'password-hash'
randpass = require 'randpass'
fs = require 'fs'
nodemailer = require 'nodemailer'
Mongolian = require 'mongolian'
dash = require 'lodash'
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
    subjectreset: 'Password reset'
    mailer: 'sendmail'
  collection: 'users'
  sendEmails: true

smtp = nodemailer.createTransport "Sendmail", "/usr/sbin/sendmail"

getMailer = ->
  if opts.mail?.mailer? isnt 'sendmail'
    opts.mail.mailer
  else
    smtp

config = (options) ->
  dash.merge opts, options
  if opts.connect?
    db = new Mongolian opts.connect
  else
    db = new Mongolian 'mongo://localhost:27017/users'
  if opts.collection?
    users = db.collection opts.collection
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

add = (email, name, pass, cb) =>
  existing = checkExists! email
  if not checkExists! email
    try
      newuser = { email, name, passhash: passwordHash.generate pass }
    catch e
      return cb new Error("Error creating user: #{e.message}"), false
    users.insert! newuser    
    newuser.password = pass
    try
      rendered = mustache.render opts.mail.bodyadd, newuser
    catch e1
      return cb new Error("Error rendering email body for new user mail: #{e1.message}"), false
    if opts.sendEmails
      try
        options =
          from: opts.mail.from
          to: email
          subject: opts.mail.subjectadd
          text: rendered
        mailer = getMailer()
        mailer.sendMail options, (err, res) ->
          if err?
            console.log err
          else
            console.log 'Message sent: ' + res.message
      catch e
        console.log 'Error sending user mail' + e.message
        console.log e
        return cb new Error("Error sending user mail: #{e.message}")
    cb null, true
  else
    cb null, false


resetPassword = (name, cb) =>
  e, user = users.findOne! { name: name }
  if user?
    pass = randpass()
    hash = passwordHash.generate pass
    change = { $set: { passhash: hash } }
    users.update { name: name }, change
    rendered = mustache.render opts.mail.bodyreset, user
    if opts.sendEmails
      try
        options =
          from: opts.mail.from
          to: user.email
          subject: opts.mail.subjectreset
          text: rendered
        mailer = getMailer()
        mailer.sendMail options, (err, res) ->
          if err?
            console.log err
          else
            console.log 'Message sent: ' + res.message
          cb true
      catch e
        console.log 'Error sending user mail' + e.message
        console.log e
    cb true


updatePassword = (username, oldpass, newpass, cb) =>
  if not checkPassword! username, oldpass
    cb false
  else
    hash = passwordHash.generate newpass
    change = { $set: { passhash: hash } }
    users.update { name: username }, change
    cb true

checkPassword = (username, pass, cb) =>
  e, user = users.findOne! { name: username }
  if user?
    cb passwordHash.verify pass, user.passhash
  else
    cb false

exports.opts = opts
exports.config = config
exports.add = add
exports.checkExists = checkExists
exports.resetPassword = resetPassword
exports.updatePassword = updatePassword
exports.checkPassword = checkPassword
exports.addNoEmail = addNoEmail
exports.users = users

