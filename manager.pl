:- set_prolog_flag(answer_write_options, [max_depth(0)]).

:- ['data.pl'], ['keywords.pl'].

roomlessEvents(RoomlessEvent) :- findall(ID, event(ID, _, _, _, NoRoom), RoomlessEvent).

eventsNoRoomWeekday(Weekday, RoomlessEvent) :-
    findall(ID, (event(ID, _, _, _, NoRoom), schedule(ID, Weekday, _, _, _, _)), RoomlessEvent).

eventsNoRoomPeriod([], []).
eventsNoRoomPeriod([Period | OtherPeriods], RoomlessEvent) :-
    findall(ID,(event(ID, _, _, _, NoRoom), eventSemester(Period, PeriodSemester),
    schedule(ID, _, _, _, _, PeriodSemester)), EventsNoRoomPeriod), !,
    eventsNoRoomPeriod(OtherPeriods, MoreRoomlessEvent),
    append([EventsNoRoomPeriod, MoreRoomlessEvent], EventsNoRoomPeriods),
    sort(EventsNoRoomPeriods, RoomlessEvent).

eventSemester(Period, PeriodSemester) :-
    Period == p1, member(PeriodSemester, [Period, p1_2]);
    Period == p2, member(PeriodSemester, [Period, p1_2]);
    Period == p3, member(PeriodSemester, [Period, p3_4]);
    Period == p4, member(PeriodSemester, [Period, p3_4]).

sortEvents(Events, Period, EventsPeriod) :-
    groupEvents(Events, Period, EventsPeriodUnsorted),
    sort(EventsPeriodUnsorted, EventsPeriod).

groupEvents([], _, []).
groupEvents([Event | OtherEvents], Period, [Event | EventsPeriod]) :-
    eventSemester(Period, PeriodSemester), schedule(Event, _, _, _, _, PeriodSemester), !,
    groupEvents(OtherEvents, Period, EventsPeriod).
groupEvents([_ | OtherEvents], Period, EventsPeriod) :-
    groupEvents(OtherEvents, Period, EventsPeriod).

eventsDurationLess(Duration, EventsDurationLess) :-
    findall(ID, (schedule(ID, _, _, _, Durations, _), Durations =< Duration), EventsDurationLess).

eventsDurationLessBool(ID, Duration) :- schedule(ID, _, _, _, Durations, _), Durations =< Duration.

findClasses(Degree, Classes) :-
    findall(Class,(shift(ID, Degree, _, _), event(ID, Class, _, _, _)), ClassesUnsorted),
    sort(ClassesUnsorted, Classes).

groupClasses(Classes, Degree, Semesters) :-
    findClassesSemester(Classes, Degree, Fall, Spring), !, append([[Fall], [Spring]], Semesters).

findClassesSemester([], _, [], []).
findClassesSemester([Class | OtherClasses], Degree, [Class | Fall], Spring) :-
    event(ID, Class, _, _, _), shift(ID, Degree, _, _),
    member(Periods, [p1, p2, p1_2]), schedule(ID, _, _, _, _, Periods),
    findClassesSemester(OtherClasses, Degree, Fall, Spring).
findClassesSemester([Class | OtherClasses], Degree, Fall, [Class | Spring]) :-
    event(ID, Class, _, _, _), shift(ID, Degree, _, _),
    member(Periods, [p3, p4, p3_4]), schedule(ID, _, _, _, _, Periods),
    findClassesSemester(OtherClasses, Degree, Fall, Spring).

degreeDuration(Period, Degree, Year, TotalDuration) :-
    findall(ID, shift(ID, Degree, Year, _), EventsTemp), sort(EventsTemp, Events),
    findall(Duration, (member(ID, Events), eventSemester(Period, PeriodSemester),
        schedule(ID, _, _, _, Duration, PeriodSemester)), Durations), !, sum_list(Durations, TotalDuration).

degreeDurationChange(Degree, Change) :-
    degreeDurationChanges([1, 2, 3], Degree, Changes), append(Changes, Change).

degreeDurationChanges([], _, []).
degreeDurationChanges([Year | OtherYears], Degree, [AnnualChanges | OtherAnnualChanges]) :-
    yearDegreeDuration(Degree, Year, YearDurations),
    yearDegreeChanges(Year, YearDurations, Degree, AnnualChanges),
    degreeDurationChanges(OtherYears, Degree, OtherAnnualChanges).

yearDegreeDuration(Degree, Year, YearDurations) :-
    findall(PeriodDuration, (member(Period, [p1, p2, p3, p4]), degreeDuration(Period, Degree, Year, PeriodDuration)), YearDurations).

yearDegreeChanges(Year, [P1Duration, P2Duration, P3Duration, P4Duration], _, AnnualChanges) :-
    append([[(Year, p1, P1Duration)], [(Year, p2, P2Duration)],
        [(Year, p3, P3Duration)], [(Year, p4, P4Duration)]], AnnualChanges).

fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration) :-
    InitialTime =< EventStart, FinalTime > EventStart,
    FinalTime =< EventEnd, !, Duration is FinalTime - EventStart.
fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration) :-
    FinalTime >= EventEnd, InitialTime < EventEnd,
    InitialTime > EventStart, !, Duration is EventEnd - InitialTime.
fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration) :-
    InitialTime =< EventStart, FinalTime >= EventEnd, !,
    Duration is EventEnd - EventStart.
fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration) :-
    InitialTime >= EventStart, FinalTime =< EventEnd, !,
    Duration is FinalTime - InitialTime.
fillSlot(InitialTime, FinalTime, EventStart, EventEnd, _) :-
    \+ (FinalTime =< EventStart; InitialTime >= EventEnd).

reservedDurations(Period, RoomType, Weekday, InitialTime, FinalTime, SumDurations):-
    rooms(RoomType, Rooms),
    findall(Durations, (eventSemester(Period, PeriodSemester), member(Room, Rooms),
        schedule(ID, Weekday, EventStart, EventEnd, _, PeriodSemester),
        event(ID, _, _, _, Room),
        fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration)), Durations),
    sum_list(Durations, SumDurations).

maxCapacity(RoomType, EventStart, EventEnd, Max) :-
    rooms(RoomType, Rooms), length(Rooms, NumRooms), Max is NumRooms * (EventEnd - EventStart).

percentage(SumDurations, Max, Percentage) :- Percentage is (SumDurations / Max) * 100.

criticalCapacity(EventStart, EventEnd, Threshold, Results) :-
    findall(criticalCases(Weekday, RoomType, PercentageInt), (rooms(RoomType, _), schedule(_, Weekday, _, _, _, Period),
        reservedDurations(Period, RoomType, Weekday, EventStart, EventEnd, SumDurations), maxCapacity(RoomType, EventStart, EventEnd, Max),
        percentage(SumDurations, Max, PercentageFloat), PercentageFloat > Threshold, ceiling(PercentageFloat, PercentageInt)), ResultsAux),
    sort(ResultsAux, Results).
