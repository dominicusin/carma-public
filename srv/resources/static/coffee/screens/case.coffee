define [ "utils"
       , "hotkeys"
       , "text!tpl/screens/case.html"
       , "model/utils"
       , "model/main"
       , "sync/datamap"
       , "dictionaries"
       ],
  (utils, hotkeys, tpl, mu, main, DataMap, Dict) ->
    utils.build_global_fn 'pickPartnerBlip', ['map']

    # Case view (renders to #left, #center and #right as well)
    setupCaseMain = (viewName, args) -> setupCaseModel viewName, args

    setupCaseModel = (viewName, args) ->

      kvm = main.modelSetup("case") viewName, args,
                         permEl       : "case-permissions"
                         focusClass   : "focusable"
                         slotsee      : ["case-number", "case-program-description", "case-car-description"]
                         groupsForest : "center"
                         defaultGroup : "default-case"

      ctx = {fields: (f for f in kvm._meta.model.fields when f.meta?.required)}
      setCommentsHandler()

      # show linked contract if it there
      if kvm["contract"]() then showContract fetchContract kvm["contract"]()

      # change contract view, when user choose another contract
      kvm["contract"].subscribe (id) ->
        if id
          c = fetchContract id
          showContract c
          fillCarParams c, kvm
        else
          hideContract()

      $("#empty-fields-placeholder").html(
          Mustache.render($("#empty-fields-template").html(), ctx))

      ko.applyBindings(kvm, el("empty-fields"))


      # Render service picker
      #
      # We use Bootstrap's glyphs if "icon" key is set in dictionary
      # entry.
      $("#service-picker-container").html(
        Mustache.render(
          $("#service-picker-template").html(),
            {dictionary: global.dictionaries["Services"]
            ,drop: 'up'
            }))

      $("body").on("change.input", ".redirectOnChange", () ->
          setTimeout(( -> window.location.hash = "back"), 500))

      utils.mkDataTable $('#call-searchtable')
      hotkeys.setup()
      kvm = global.viewsWare[viewName].knockVM

      if utils.canReadActions()
        # Disable action results if any of required case fields is not
        # set
        do (kvm) ->
          ko.computed ->
            nots = (i for i of kvm when /.*Not$/.test i)
            if (_.any nots, (e) -> kvm[e]())
              k["resultDisabled"](true)  for k in kvm["actionsReference"]()
            else
              k["resultDisabled"](false) for k in kvm["actionsReference"]()

    setCommentsHandler = ->
      $("#case-comments-b").on 'click', ->
        i = $("#case-comments-i")
        return if _.isEmpty i.val()
        comment =
          date: (new Date()).toString('dd.MM.yyyy HH:mm')
          user: global.user.login
          comment: i.val()
        k = global.viewsWare['case-form'].knockVM
        if _.isEmpty k['comments']()
          k['comments'] [comment]
        else
          k['comments'] k['comments']().concat comment
        i.val("")


    # Top-level wrapper for storeService
    addService = (name) ->
      kvm = global.viewsWare["case-form"].knockVM
      mu.addReference kvm,
                   'services',
                   { modelName : name },
                   (k) ->
                      e = $('#' + k['view'])
                      e.parent().prev()[0].scrollIntoView()
                      e.find('input')[0].focus()

    utils.build_global_fn 'addService', ['screens/case']


    removeCaseMain = ->
      $("body").off "change.input"
      $('.navbar').css "-webkit-transform", ""

    showContract = (contract)->
      if contract.make
        carMakeDict = new Dict.dicts.ModelDict
          dict: 'CarMake'
        contract.make = carMakeDict.getLab contract.make

      if contract.model
        carModelDict = new Dict.dicts.ModelDict
          dict: 'CarModel'
        contract.model = carModelDict.getLab contract.model

      if contract.subprogram
        subprogramDict = new Dict.dicts.ComputedDict(dict: "usermetaPrograms")
        contract.subprogram = subprogramDict.getLab contract.subprogram

      if contract.committer
        usersDict = new Dict.dicts.ModelDict
          dict: 'Usermeta'
          meta:
            dictionaryKey: 'id'
            dictionaryLabel: 'realName'
        contract.committer = usersDict.getLab contract.committer

      contract.isActive = if contract.isActive then "Да" else "Нет"

      if contract.seller
        carSellerDict = new Dict.dicts.ModelDict
          dict: 'Partner'
          meta:
            dictionaryKey: 'id'
            dictionaryLabel: 'name'
        contract.seller = carSellerDict.getLab contract.seller

      model = global.model 'Contract'
      mapper = new DataMap.Mapper(model)
      kvm = main.buildKVM model, {fetched: mapper.s2cObj contract}
      $("#contract").html(
        Mustache.render($("#contract-content-template").html(), {title: "Контракт"}))
      ko.applyBindings(kvm, el("contract-content"))

    hideContract = ->
      $("#contract").empty()

    fetchContract = (id) ->
      JSON.parse ($.bgetJSON "/_/Contract/#{id}").responseText

    fillCarParams = (c, kvm) ->
      unless c.buyDate and kvm.car_buyDate()
        kvm.car_buyDate c.buyDate
      unless c.carClass and kvm.car_class()
        kvm.car_class c.carClass
      unless c.color and kvm.car_color()
        kvm.car_color c.color
      unless c.engineType and kvm.car_engine()
        kvm.car_engine c.engineType
      unless c.engineVolume and kvm.car_liters()
        kvm.car_liters c.engineVolume
      unless c.make and kvm.car_make()
        kvm.car_make c.make
      unless c.makeYear and kvm.car_makeYear()
        kvm.car_makeYear c.makeYear
      unless c.model and kvm.car_model()
        kvm.car_model c.model
      unless c.plateNum and kvm.car_plateNum()
        kvm.car_plateNum c.plateNum
      unless c.seller and kvm.car_seller()
        kvm.car_seller c.seller
      unless c.startMileage and kvm.car_mileage()
        kvm.car_mileage c.startMileage
      unless c.transmission and kvm.car_transmission()
        kvm.car_transmission c.transmission
      unless c.vin and kvm.car_vin()
        kvm.car_vin c.vin

    { constructor       : setupCaseMain
    , destructor        : removeCaseMain
    , template          : tpl
    , addService        : addService
    }
