--- @class hs
local hs = {}

-- Define the hs.audiodevice class with its methods
--- @class hs.audiodevice
--- @field setMuted fun(self: hs.audiodevice, state: boolean): boolean
--- @field muted fun(self: hs.audiodevice): boolean
--- @field volume fun(self: hs.audiodevice): number
--- @field setVolume fun(self: hs.audiodevice, value: number): boolean
--- @field name fun(self: hs.audiodevice): string

---@type hs.application
hs.application = require("hs.application")

---@type hs.alert
hs.alert = require("hs.alert")

---@type hs.appfinder
hs.appfinder = require("hs.appfinder")

---@type hs.applescript
hs.applescript = require("hs.applescript")

-- ---@type hs.audiodevice
--- @type {defaultOutputDevice: fun(): hs.audiodevice, allOutputDevices: fun(): hs.audiodevice[]}
hs.audiodevice = require("hs.audiodevice")

---@type hs.axuielement
hs.axuielement = require("hs.axuielement")

---@type hs.base64
hs.base64 = require("hs.base64")

---@type hs.battery
hs.battery = require("hs.battery")

---@type hs.bonjour
hs.bonjour = require("hs.bonjour")

---@type hs.brightness
hs.brightness = require("hs.brightness")

---@type hs.caffeinate
hs.caffeinate = require("hs.caffeinate")

---@type hs.camera
hs.camera = require("hs.camera")

---@type hs.canvas
hs.canvas = require("hs.canvas")

---@type hs.chooser
hs.chooser = require("hs.chooser")

---@type hs.console
hs.console = require("hs.console")

---@type hs.crash
hs.crash = require("hs.crash")

---@type hs.deezer
hs.deezer = require("hs.deezer")

---@type hs.dialog
hs.dialog = require("hs.dialog")

---@type hs.distributednotifications
hs.distributednotifications = require("hs.distributednotifications")

---@type hs.doc
hs.doc = require("hs.doc")

---@type hs.dockicon
hs.dockicon = require("hs.dockicon")

---@type hs.drawing
hs.drawing = require("hs.drawing")

---@type hs.eventtap
hs.eventtap = require("hs.eventtap")

---@type hs.expose
hs.expose = require("hs.expose")

---@type hs.fnutils
hs.fnutils = require("hs.fnutils")

---@type hs.fs
hs.fs = require("hs.fs")

---@type hs.geometry
hs.geometry = require("hs.geometry")

---@type hs.grid
hs.grid = require("hs.grid")

---@type hs.hash
hs.hash = require("hs.hash")

---@type hs.hid
hs.hid = require("hs.hid")

---@type hs.hints
hs.hints = require("hs.hints")

---@type hs.host
hs.host = require("hs.host")

---@type hs.hotkey
hs.hotkey = require("hs.hotkey")

---@type hs.http
hs.http = require("hs.http")

---@type hs.httpserver
hs.httpserver = require("hs.httpserver")

---@type hs.image
hs.image = require("hs.image")

---@type hs.inspect
hs.inspect = require("hs.inspect")

---@type hs.ipc
hs.ipc = require("hs.ipc")

---@type hs.itunes
hs.itunes = require("hs.itunes")

---@type hs.javascript
hs.javascript = require("hs.javascript")

---@type hs.json
hs.json = require("hs.json")

---@type hs.keycodes
hs.keycodes = require("hs.keycodes")

---@type hs.layout
hs.layout = require("hs.layout")

---@type hs.location
hs.location = require("hs.location")

---@type hs.logger
hs.logger = require("hs.logger")

---@type hs.math
hs.math = require("hs.math")

---@type hs.menubar
hs.menubar = require("hs.menubar")

---@type hs.messages
hs.messages = require("hs.messages")

---@type hs.midi
hs.midi = require("hs.midi")

---@type hs.milight
hs.milight = require("hs.milight")

---@type hs.mjomatic
hs.mjomatic = require("hs.mjomatic")

---@type hs.mouse
hs.mouse = require("hs.mouse")

---@type hs.network
hs.network = require("hs.network")

---@type hs.noises
hs.noises = require("hs.noises")

---@type hs.notify
hs.notify = require("hs.notify")

---@type hs.osascript
hs.osascript = require("hs.osascript")

---@type hs.pasteboard
hs.pasteboard = require("hs.pasteboard")

---@type hs.pathwatcher
hs.pathwatcher = require("hs.pathwatcher")

---@type hs.plist
hs.plist = require("hs.plist")

---@type hs.razer
hs.razer = require("hs.razer")

---@type hs.redshift
hs.redshift = require("hs.redshift")

---@type hs.screen
hs.screen = require("hs.screen")

---@type hs.serial
hs.serial = require("hs.serial")

---@type hs.settings
hs.settings = require("hs.settings")

---@type hs.sharing
hs.sharing = require("hs.sharing")

---@type hs.shortcuts
hs.shortcuts = require("hs.shortcuts")

---@type hs.socket
hs.socket = require("hs.socket")

---@type hs.sound
hs.sound = require("hs.sound")

---@type hs.spaces
hs.spaces = require("hs.spaces")

---@type hs.speech
hs.speech = require("hs.speech")

---@type hs.spoons
hs.spoons = require("hs.spoons")

---@type hs.spotify
hs.spotify = require("hs.spotify")

---@type hs.spotlight
hs.spotlight = require("hs.spotlight")

---@type hs.sqlite3
hs.sqlite3 = require("hs.sqlite3")

---@type hs.streamdeck
hs.streamdeck = require("hs.streamdeck")

---@type hs.styledtext
hs.styledtext = require("hs.styledtext")

---@type hs.tabs
hs.tabs = require("hs.tabs")

---@type hs.tangent
hs.tangent = require("hs.tangent")

---@type hs.task
hs.task = require("hs.task")

---@type hs.timer
hs.timer = require("hs.timer")

---@type hs.uielement
hs.uielement = require("hs.uielement")

---@type hs.urlevent
hs.urlevent = require("hs.urlevent")

---@type hs.usb
hs.usb = require("hs.usb")

---@type hs.utf8
hs.utf8 = require("hs.utf8")

---@type hs.vox
hs.vox = require("hs.vox")

---@type hs.watchable
hs.watchable = require("hs.watchable")

---@type hs.websocket
hs.websocket = require("hs.websocket")

---@type hs.webview
hs.webview = require("hs.webview")

---@type hs.wifi
hs.wifi = require("hs.wifi")

---@type hs.window
hs.window = require("hs.window")

return hs
