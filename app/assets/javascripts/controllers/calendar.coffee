'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$state", "$uibModal", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig', 'trainingsPromise', 'machinesPromise',
($scope, $state, $uibModal, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig, trainingsPromise, machinesPromise) ->


  ### PRIVATE STATIC CONSTANTS ###
  currentMachineEvent = null
  machinesPromise.forEach((m) -> m.checked = true)
  trainingsPromise.forEach((t) -> t.checked = true)


  ### PUBLIC SCOPE ###

  ## List of trainings
  $scope.trainings = trainingsPromise

  ## List of machines
  $scope.machines = machinesPromise

  ## variable for filter event
  $scope.evt = true

  ## variable for show/hidden slot no dispo
  $scope.dispo = true

  ## add availabilities source to event sources
  $scope.eventSources = []

  ## filter availabilities if have change
  $scope.filterAvailabilities = ->
    $scope.filter =
      trainings: $scope.isSelectAll('trainings')
      machines: $scope.isSelectAll('machines')
    $scope.calendarConfig.events = availabilitySourceUrl()

  ## check all formation/machine is select in filter
  $scope.isSelectAll = (type) ->
    $scope[type].length == $scope[type].filter((t) -> t.checked).length

  ## a variable for formation/machine checkbox is or not checked
  $scope.filter =
    trainings: $scope.isSelectAll('trainings')
    machines: $scope.isSelectAll('machines')

  ## toggle to select all formation/machine
  $scope.toggleFilter = (type) ->
    $scope[type].forEach((t) -> t.checked = $scope.filter[type])
    $scope.filterAvailabilities()


  ### PRIVATE SCOPE ###

  calendarEventClickCb = (event, jsEvent, view) ->
    ## current calendar object
    calendar = uiCalendarConfig.calendars.calendar
    if event.available_type == 'machines'
      currentMachineEvent = event
      calendar.fullCalendar('changeView', 'agendaDay')
      calendar.fullCalendar('gotoDate', event.start)
    else
      if event.available_type == 'event'
        $state.go('app.public.events_show', {id: event.event_id})
      else if event.available_type == 'training'
        $state.go('app.public.training_show', {id: event.training_id})
      else
        $state.go('app.public.machines_show', {id: event.machine_id})

  ## agendaDay view: disable slotEventOverlap
  ## agendaWeek view: enable slotEventOverlap
  toggleSlotEventOverlap = (view) ->
    # set defaultView, because when we change slotEventOverlap
    # ui-calendar will trigger rerender calendar
    $scope.calendarConfig.defaultView = view.type
    today = if currentMachineEvent then currentMachineEvent.start else moment().utc().startOf('day')
    if today > view.start and today < view.end and today != view.start
      $scope.calendarConfig.defaultDate = today
    else
      $scope.calendarConfig.defaultDate = view.start
    if view.type == 'agendaDay'
      $scope.calendarConfig.slotEventOverlap = false
    else
      $scope.calendarConfig.slotEventOverlap = true

  ## function is called when calendar view is rendered or changed
  viewRenderCb = (view, element) ->
    toggleSlotEventOverlap(view)
    if view.type == 'agendaDay'
      # get availabilties by 1 day for show machine slots
      uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents')

  eventRenderCb = (event, element) ->
    if event.tags.length > 0
      html = ''
      for tag in event.tags
        html += "<span class='label label-success text-white'>#{tag.name}</span> "
      element.find('.fc-title').append("<br/>"+html)
    return

  getFilter = ->
    t = $scope.trainings.filter((t) -> t.checked).map((t) -> t.id)
    m = $scope.machines.filter((m) -> m.checked).map((m) -> m.id)
    {t: t, m: m, evt: $scope.evt, dispo: $scope.dispo}

  availabilitySourceUrl = ->
    "/api/availabilities/public?#{$.param(getFilter())}"

  initialize = ->
    ## fullCalendar (v2) configuration
    $scope.calendarConfig = CalendarConfig
      events: availabilitySourceUrl()
      slotEventOverlap: true
      header:
        left: 'month agendaWeek agendaDay'
        center: 'title'
        right: 'today prev,next'
      minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss'))
      maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss'))
      eventClick: (event, jsEvent, view)->
        calendarEventClickCb(event, jsEvent, view)
      viewRender: (view, element) ->
        viewRenderCb(view, element)
      eventRender: (event, element, view) ->
        eventRenderCb(event, element)




  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]
