define [ "utils"
       , "hotkeys"
       , "text!tpl/screens/case.html"
       , "text!tpl/fields/form.html"
       , "lib/ws"
       , "lib/idents"
       , "model/utils"
       , "model/main"
       , "components/contract"
       ],
  (utils, hotkeys, tpl, Flds, WS, idents, mu, main, Contract) ->
    ActionResult = idents.idents "ActionResult"
    utils.build_global_fn 'pickPartnerBlip', ['map']

    flds =  $('<div/>').append($(Flds))
    # Case view (renders to #left, #center and #right as well)
    setupCaseMain = (viewName, args) -> setupCaseModel viewName, args

    setupCaseModel = (viewName, args) ->
      kaze = {}
      # Bootstrap case data to load proper view for Case model
      # depending on the program
      if args.id
        $.bgetJSON "/_/Case/#{args.id}", (rsp) -> kaze = rsp

      kvm = main.modelSetup("Case") viewName, args,
                         permEl       : "case-permissions"
                         focusClass   : "focusable"
                         slotsee      : ["case-number",
                                         "case-program-description",
                                         "case-car-description"]
                         groupsForest : "center"
                         defaultGroup : "default-case"
                         modelArg     : "ctr:#{kaze.program}"

      # TODO The server should notify the client about new actions
      # appearing in the case instead of explicit subscription
      kvm["caseStatusSync"]?.subscribe (nv) ->
        if !nv
          kvm['renderActions']?()

      ctx = {fields: (f for f in kvm._meta.model.fields when f.meta?.required)}
      setupCommentsHandler kvm

      Contract.setup "contract", kvm

      # Render service picker
      #
      # We use Bootstrap's glyphs if "icon" key is set in dictionary
      # entry.
      $("#service-picker-container").html(
        Mustache.render(
          $(flds).find("#service-picker-template").html(),
            {dictionary: utils.newComputedDict("iconizedServiceTypes")
            ,drop: 'up'
            }))

      hotkeys.setup()
      kvm = global.viewsWare[viewName].knockVM

      # True if any of of required fields are missing a value
      do (kvm) ->
        if global.Usermeta
          kvm['abandonedServices'] = ko.observable(
            global.Usermeta.abandonedServices().filter (s) -> `s.caseId == args.id`)
          global.Usermeta.abandonedServices.subscribe (svcs) ->
            kvm.abandonedServices(svcs.filter (s) -> `s.caseId == args.id`)
        else
          kvm['abandonedServices'] = ko.observable []


        kvm['hasMissingRequireds'] = ko.computed ->
          # Check if any of required fields in a viewmodel is missing
          checkVM = (vm) ->
            nots = (i for i of vm when /.*Not$/.test i)
            _.any nots, (e) -> vm[e]()
          # Early case-only check
          disable = checkVM kvm
          # Check all services too
          for r, svm of kvm['servicesReference']()
            disable ||= checkVM svm
          disable || kvm.abandonedServices().length > 0
        # Show a list of empty required fields
        ko.applyBindings(kvm, el("empty-fields"))

      setupHistory kvm
      setupDiagTree kvm

      kvm['renderActions'] = -> renderActions(kvm)
      kvm['renderActions']()

      # make colored services and actions a little bit nicer
      $('.accordion-toggle:has(> .alert)').css 'padding', 0

      $(".status-btn-tooltip").tooltip()

      # scroll to service if we have its id in url
      if args.svc
        services = global.viewsWare["case-form"].knockVM.servicesReference()
        for s in services
          if String(s.id()) == args.svc
            $("##{s._meta.model.viewName}-head").collapse('show')
            leftTop = $("#left").scrollTop()
            svcTop = $("##{s._meta.model.viewName}-group").offset().top
            $("#left").animate {scrollTop: leftTop + svcTop - 40}, 1000

    setupDiagTree = (kvm) ->
      watchLocalStorage = (e) ->
        if e.key == "DiagTree/#{kvm.id()}/newSvc"
          window.localStorage.removeItem(e.key)
          window.location.reload()

      kvm._showDiag = ->
        window.addEventListener("storage", watchLocalStorage, false)
        win = window.open "#diag/show/#{kvm.id()}", '_blank'
        win.focus()
      kvm._startDiag = ->
        opts =
          type: 'POST'
          url: "/_/DiagHistory"
          data: JSON.stringify {caseId: parseInt(kvm.id())}
        $.ajax(opts).done ->
          window.addEventListener("storage", watchLocalStorage, false)
          kvm._canStartDiag false
          kvm._canProceedDiag true
          win = window.open "#diag/show/#{kvm.id()}", '_blank'
          win.focus()

      refreshDiagTree = ->
        $.getJSON "/diag/info/#{kvm.id()}", (res) ->
          kvm._canDiag(res.root != null)
          kvm._canStartDiag(!res.started)
          kvm._canProceedDiag(res.started && !res.ended)
          kvm._canShowDiag(res.started && res.ended)

      refreshDiagTree()
      kvm.subprogramSync.subscribe (nv) ->
        if !nv
          refreshDiagTree()


    # History pane
    setupHistory = (kvm) ->
      historyDatetimeFormat = "dd.MM.yyyy HH:mm:ss"
      historyLimit = 30
      kvm['lookBackInHistory'] = ->
        historyLimit += 30
        refreshHistory()

      refreshHistory = ->
        $.getJSON "/caseHistory/#{kvm.id()}?limit=#{historyLimit}", (res) ->
          kvm['endOfHistory'](res.length < historyLimit)
          kvm['historyItems'].removeAll()

          # List of service id's for colorizing actions
          svcs =
            _.map kvm.services()?.split(','),
              (s) -> parseInt s.split(':')?[1]

          # scan items in reverse order and set cumulative partner delays
          partnerDelays = {}
          for i in [].concat(res).reverse()
            json = i[2]
            if json.type == 'partnerDelay'
              if !partnerDelays[json.serviceid]
                partnerDelays[json.serviceid] = 0
              partnerDelays[json.serviceid] += json.delayminutes
              json.delayminutes = partnerDelays[json.serviceid]

          # Process every history item
          for i in res
            json = i[2]

            if json.tasks
              # We expect `isChecked` field to be present in each task,
              # but is is not always the case due to the bug fixed in
              # b0e4ce19b330cfafa05ba33a92234f24bd6bfe65
              json.tasks.forEach((task) -> task.isChecked = !!task.isChecked)

            if json.aeinterlocutors?
              json.aeinterlocutors =
                _.map(json.aeinterlocutors, utils.internalToDisplayed).
                  join(", ")
            color = ko.observable(
              if json.serviceid?
                utils.palette[svcs.indexOf(json.serviceid) %
                  utils.palette.length]
              else
                null)

            if json.delayminutes
              hours = String(Math.floor(json.delayminutes / 60))
              minutes = String(json.delayminutes % 60)
              if hours.length < 2
                hours = '0' + hours
              if minutes.length < 2
                minutes = '0' + minutes
              json.delayminutes = hours + ':' + minutes

            dts = new Date(i[0]).toString historyDatetimeFormat
            item =
              datetime: dts
              who: i[1]
              json: json
              color: color
            item.visible = ko.computed(showHistoryItem item)
            kvm['historyItems'].push item


      showHistoryItem = (i) ->
        ->
          if i.json.type == 'action' && not kvm.histShowActi()
            return false
          if i.json.type == 'comment' && not kvm.histShowComm()
            return false
          if i.json.type == 'partnerCancel' && not kvm.histShowCanc()
            return false
          if i.json.type == 'partnerDelay' && not kvm.histShowDelay()
            return false
          if (i.json.type == 'call' || i.json.type == 'avayaEvent') && not kvm.histShowCall()
            return false

          filterVal = kvm['historyFilter']()
          matchesFilter = (s) ->
            _.isEmpty(filterVal) || (new RegExp(filterVal, "i")).test(s)
          return _.any([i.who, i.datetime].concat(_.values(i.json)), matchesFilter)

      kvm['refreshHistory'] = refreshHistory
      kvm['contact_phone1']?.subscribe refreshHistory

    # Case comments/chat
    setupCommentsHandler = (kvm) ->
      legId = "Case:#{kvm.id()}"
      if window.location.protocol == "https:"
        chatUrl = "wss://#{location.hostname}:#{location.port}/chat/#{legId}"
      else
        chatUrl = "ws://#{location.hostname}:#{location.port}/chat/#{legId}"

      chatNotify = (message, className) ->
        $.notify message, {className: className || 'info', autoHide: false}

      brDict = utils.newModelDict "BusinessRole"

      chatWs = new WS chatUrl
      kvm['chatWs'] = chatWs
      chatWs.onmessage = (raw) ->
        msg = JSON.parse raw.data
        if msg.youAreNotAlone
          for usr in msg.youAreNotAlone
            um = global.dictionaries.users?.byId[usr.id]
            if um
              note = "Оператор #{um.label} работает с кейсом"
              chatNotify note, "error"
          return
        who = msg.user || msg.joined || msg.left
        if who.id == global.user.id
          return
        if who.id
          $.getJSON "/_/Usermeta/#{who.id}", (um) ->
            note = "Оператор #{um.login}"
            if msg.msg
              note += " оставил сообщение: #{msg.msg}"
              chatNotify note
              kvm['refreshHistory']?()
            else
              if um.realName
                note += " (#{um.realName})"
              if um.workPhoneSuffix
                note += ", доб. #{um.workPhoneSuffix}"
              note += ", IP #{who.ip}"
              if um.businessRole
                note += " с ролью #{brDict.getLab(um.businessRole)}"
              if msg.joined
                note += " вошёл в кейс"
                chatNotify note, "error"
              if msg.left
                note += " вышел с кейса"
                chatNotify note, "success"

      # Write new comment to case and send it via WS too
      $("#case-comments-b").on 'click', ->
        i = $("#case-comments-i")
        comment = i.val()
        return if _.isEmpty comment
        opts =
          type: "POST"
          url: "/_/CaseComment"
          data: JSON.stringify {caseId: parseInt(kvm.id()), comment: comment}
        $.ajax(opts).done( -> kvm['refreshHistory']?() && chatWs.send comment)
        i.val("")

    # Manually re-render a list of case actions
    #
    # TODO Implement this as a read trigger for Case.actions EF with
    # WS subscription to action list updates
    renderActions = (kvm) ->
      caseId = kvm.id()
      refCounter = 0

      mkSubname = -> "case-#{caseId}-actions-view-#{refCounter++}"
      subclass = "case-#{caseId}-actions-views"

      # Top-level container for action elements
      cont = $("#case-actions-list")

      # TODO Add garbage collection
      # $(".#{subclass}").each((i, e) ->
      #   main.cleanupKVM global.viewsWare[e.id].knockVM)
      cont.children().remove()
      cont.spin('large')

      # Pick reference template
      tpl = flds.find("#actions-reference-template").html()

      # Flush old actionsList
      if kvm['actionsList']?
        kvm['actionsList'].removeAll()

      $.getJSON "/backoffice/caseActions/#{caseId}", (aids) ->
        for aid in aids
          # Generate reference container
          view = mkSubname()
          box = Mustache.render tpl,
            refView: view
            refClass: subclass
          cont.append box
          avm = main.modelSetup("Action") view, {id: aid},
            slotsee: [view + "-link"]
            parent: kvm
          # Redirect to backoffice when action result changes
          avm["resultSync"]?.subscribe (nv) ->
            # Don't redirect to backoffice if action result was set with
            # 'anotherPSA' button
            if !nv && avm.result__ != ActionResult.needAnotherService
              window.location.hash = "back"
          avm["result"]?.subscribe (res) ->
            avm.result__ = res
          # There's no guarantee who renders first (services or
          # actions), try to set up an observable from here
          if not kvm['actionsList']?
            kvm['actionsList'] = ko.observableArray()
          kvm['actionsList'].push avm
          if avm["type"]() == global.idents("ActionType").accident && avm["myAction"]()
            if global.CTIPanel
              global.CTIPanel.instaDial kvm["contact_phone1"]()
              window.alert "Внимание: кейс от системы e-call, \
                производится набор номера клиента, возьмите трубку"
          # Disable action results if any of required case fields is
          # not set
          do (avm) ->
            avm.resultDisabled kvm['hasMissingRequireds']()
            kvm['hasMissingRequireds'].subscribe (dis) ->
              avm.resultDisabled?(dis)
        cont.spin false
      kvm['refreshHistory']?()

    # Top-level wrapper for storeService
    addService = (name) ->
      kvm = global.viewsWare["case-form"].knockVM
      modelArg = "ctr:#{kvm.program()}"
      mu.addReference kvm,
        'services',
        {modelName : name, options:
          newStyle: true
          parentField: 'parentId'
          modelArg: modelArg
          hooks: ['*']},
        (k) ->
          e = $('#' + k['view'])
          e.parent().prev()[0]?.scrollIntoView()
          e.find('input')[0]?.focus()
          # make colored service a little bit nicer even if it is just created
          $('.accordion-toggle:has(> .alert)').css 'padding', 0
          $(".status-btn-tooltip").tooltip()
          $("##{k['view']}-head").collapse 'show'
          global.Usermeta?.updateAbandonedServices()

    utils.build_global_fn 'addService', ['screens/case']


    removeCaseMain = ->
      global.viewsWare["case-form"].knockVM['chatWs']?.close()
      $("body").off "change.input"
      $('.navbar').css "-webkit-transform", ""


    { constructor       : setupCaseMain
    , destructor        : removeCaseMain
    , template          : tpl
    , addService        : addService
    }
