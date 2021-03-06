define [], ->
  # Remove all content of view and clean up wares.
  #
  # To setup view back again, call
  # screen.views[viewName]($el(viewName), args);
  forgetView = (viewName) ->
    vW = global.viewsWare[viewName]
    # View may have not setup any knockVM (static views like search)
    # FIXME: do we have to release knockvm at all?
    # if not _.isUndefined(vW.knockVM) then kb.vmRelease(vW.knockVM)
    vW = {}
    $el(viewName).empty()

  # Clean up all views on screen and everything.
  forgetScreen = ->
    for name, cs of global.activeScreen?.views when cs.destructor?
      cs.destructor(name)
    forgetView(viewName) for viewName of global.viewsWare
    global.topElement.off()
    window.ReactDOM && window.ReactDOM.unmountComponentAtNode(global.topElement[0])
    ko.cleanNode global.topElement[0]
    global.topElement.empty()
    global.viewsWare = {}
    global.activeScreen = null


  # Render top-level screen template (static)
  #
  # args object is passed further to all view setup functions.
  renderScreen: (screenObj, args) ->
    forgetScreen()
    screen = screenObj.screen
    screen.reload = => @renderScreen(screenObj, args)
    global.activeScreen = screen

    # Highlight the new item in navbar
    $("li.active").removeClass("active")
    $el(screen.name + "-screen-nav").addClass("active")

    rawPartials = if screenObj.partials
        $('.partial').add($(screenObj.partials).siblings(".partial"))
      else
        $('.partial')

    partials = {}
    for p in rawPartials
      partials[$(p).attr('id')] = $(p).html()

    wrappers = screenObj.wrappers?(partials) or {}

    if screen.component
      ReactDOM.render screen.component, global.topElement[0]
    else
      tpl   = screenObj?.template
      tpl ||= $el(screen.template).html()

      unless tpl?
        throw "Template for screen #{screen.name} is not found"

      tpl1 = Mustache.render tpl, wrappers, partials
      global.topElement.html(tpl1)
      # Call setup functions for all views, assuming they will set
      # their viewsWare
      for viewName, cs of screen.views when cs.constructor?
        cs.constructor(viewName, args)

  # Clean up all views on screen and everything.
  forgetScreen: forgetScreen
