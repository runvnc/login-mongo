#This is actually ToffeeScript
bcrypt = require 'bcrypt'
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
    bodyadd: "Username: {{name}}"
    bodyreset: "Username: {{name}}"
    subjectreset: 'Password reset'
    mailer: 'sendmail'
  collection: 'users'
  sendEmails: true

smtp = nodemailer.createTransport "Sendmail", "/usr/sbin/sendmail"

getMailer = ->
  if opts.mail?.mailer isnt 'sendmail'
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
    err, hash = bcrypt.hash! pass, 8
    users.insert! { email, name, passhash: hash }
    cb?()
  else
    cb?()

add = (email, name, pass, cb) =>
  existing = checkExists! email
  if not checkExists! email
    try
      err, hash = bcrypt.hash! pass, 8
      newuser = { email, name, passhash: hash }
      e2, val = users.insert! newuser
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
    catch e
      console.log 'There was an error'
      console.log e
      return cb new Error("Error creating user: #{e.message}"), false

  else
    cb null, false
  null

resetPassword = (name, cb) =>
  e, user = users.findOne! { name: name }
  if user?
    pass = randpass()
    err, hash = bcrypt.hash! pass, 8
    change = { $set: { passhash: hash } }
    users.update! { name: name }, change
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
          cb pass
      catch e
        console.log 'Error sending user mail' + e.message
        console.log e
    cb pass
  null


updatePassword = (username, oldpass, newpass, cb) =>
  if not checkPassword! username, oldpass
    cb false
  else
    err, hash = bcrypt.hash! newpass, 8
    change = { $set: { passhash: hash } }
    users.update { name: username }, change
    cb true

checkPassword = (username, pass, cb) =>
  e, user = users.findOne! { name: username }
  if user?
    er, res = bcrypt.compare! pass, user.passhash
    cb res
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

