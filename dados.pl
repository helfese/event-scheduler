% Listas completas.
:- set_prolog_flag(answer_write_options, [max_depth(0)]).

% Bases de conhecimento importadas.
:- ['data.pl'], ['keywords.pl'].

/*
O predicado eventosSemSalas/1 encontra IDs de eventos sem salas. Sendo eventosSemSalas(EventosSemSala)
true, se EventosSemSala for uma lista ordenada de IDs de eventos sem sala, sem IDs repetidos.
*/
roomlessEvents(RoomlessEvent) :- findall(ID, event(ID, _, _, _, NoRoom), RoomlessEvent).

/*
O predicado eventosSemSalasDiaSemana/2 encontra IDs de eventos sem salas dum dia da semana.
Sendo eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) true, se EventosSemSala for uma
lista ordenada de IDs de eventos sem sala, sem IDs repetidos, dum dia de semana DiaDaSemana.
*/
eventsNoRoomWeekday(Weekday, RoomlessEvent) :-
    findall(ID, (event(ID, _, _, _, NoRoom), schedule(ID, Weekday, _, _, _, _)), RoomlessEvent).

/*
O predicado eventosSemSalasPeriodo/2 encontra IDs de eventos sem salas dum periodo. Sendo
eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala) true, se EventosSemSala for uma lista
ordenada de IDs de eventos sem sala, sem IDs repetidos, dos periodos duma lista ListaPeriodos.
*/
eventsNoRoomPeriod([], []).
eventsNoRoomPeriod([Period | OtherPeriods], RoomlessEvent) :-
    findall(ID,(event(ID, _, _, _, NoRoom), eventSemester(Period, PeriodSemester),
    schedule(ID, _, _, _, _, PeriodSemester)), EventsNoRoomPeriod), !,
    eventsNoRoomPeriod(OtherPeriods, MoreRoomlessEvent),
    append([EventsNoRoomPeriod, MoreRoomlessEvent], EventsNoRoomPeriods),
    sort(EventsNoRoomPeriods, RoomlessEvent).

% O predicado eventoSemestral/2, ou eventoSemestral(Periodo, Periodos), associa
% o periodo Periodo ao respetivo semestre, devolvendo-os no periodo PeriodoSemestre.
eventSemester(Period, PeriodSemester) :-
    Period == p1, member(PeriodSemester, [Period, p1_2]);
    Period == p2, member(PeriodSemester, [Period, p1_2]);
    Period == p3, member(PeriodSemester, [Period, p3_4]);
    Period == p4, member(PeriodSemester, [Period, p3_4]).

/*
O predicado organizaEventos/3 encontra e ordena os IDs de eventos em duns do mesmo. Sendo
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) true, se EventosNoPeriodo for uma
lista ordenada de IDs de eventos duma lista ListaEventos, sem IDs repetidos, dum periodo Periodo.
*/
sortEvents(Events, Period, EventsPeriod) :-
    groupEvents(Events, Period, EventsPeriodUnsorted),
    sort(EventsPeriodUnsorted, EventsPeriod).

% O predicado organizaEventosDesordenado/3, ou organizaEventos(ListaEventos, Periodo, EventosNoPeriodoDesordenados),
% encontra IDs de eventos duma lista ListaEventos em duns do mesmo periodo
% Periodo, organizando-os numa lista desordenada EventosNoPeriodoDesordenados.
groupEvents([], _, []).
groupEvents([Event | OtherEvents], Period, [Event | EventsPeriod]) :-
    eventSemester(Period, PeriodSemester), schedule(Event, _, _, _, _, PeriodSemester), !,
    groupEvents(OtherEvents, Period, EventsPeriod).
groupEvents([_ | OtherEvents], Period, EventsPeriod) :-
    groupEvents(OtherEvents, Period, EventsPeriod).

/*
O predicado eventosMenoresQue/2 encontra IDs de eventos com um dado limite maximo de duracao.
Sendo eventosMenoresQue(Duracao, ListaEventosMenoresQue) true, se ListaEventosMenoresQue for uma
lista ordenada de IDs de eventos, sem IDs repetidos, de duracao menor ou igual a duracao duma Duracao.
*/
eventsDurationLess(Duration, EventsDurationLess) :-
    findall(ID, (schedule(ID, _, _, _, Durations, _), Durations =< Duration), EventsDurationLess).

/*
O predicado eventosMenoresQueBool/2 verifica se um evento tem um dado limite maximo de duracao. Sendo
eventosMenoresQueBool(ID, Duracao) true, se o evento identificado pelo ID tiver duracao menor ou igual a duracao duma Duracao.
*/
eventsDurationLessBool(ID, Duration) :- schedule(ID, _, _, _, Durations, _), Durations =< Duration.

/*
O predicado procuraDisciplinas/2 procura as disciplinas dum curso. Sendo procuraDisciplinas(Curso, ListaDisciplinas)
true, se ListaDisciplinas for uma lista ordenada alfabeticamente das disciplinas dum curso Curso.
*/
findClasses(Degree, Classes) :-
    findall(Class,(shift(ID, Degree, _, _), event(ID, Class, _, _, _)), ClassesUnsorted),
    sort(ClassesUnsorted, Classes).

/*
O predicado organizaDisciplinas/3 organiza as disciplinas dum curso por semestre. Sendo
organizaDisciplinas(ListaDisciplinas, Curso, Semestres) true, se Semestres for uma lista com duas listas
ordenadas alfabeticamente de disciplinas semestrais, sem disciplinas repetidas, duma lista ListaDisciplinas
dum curso Curso. Sendo a primeira e a segunda lista do primeiro e do segundo semestre, respetivamente.
*/
groupClasses(Classes, Degree, Semesters) :-
    findClassesSemester(Classes, Degree, Fall, Spring), !, append([[Fall], [Spring]], Semesters).

% O predicado encontraDisciplinasPorSemestre/4, ou organizaDisciplinas(ListaDisciplinas, Curso, Semestre1, Semestre2),
% organiza as disciplinas duma lista ListaDisciplinas dum curso Curso por semestre nas listas ordenadas alfabeticamente de disciplinas
% semestrais Semestre1 e Semestre2, a primeira e a segunda lista do primeiro e do segundo semestre, respetivamente, sem disciplinas repetidas.
findClassesSemester([], _, [], []).
findClassesSemester([Class | OtherClasses], Degree, [Class | Fall], Spring) :-
    event(ID, Class, _, _, _), shift(ID, Degree, _, _),
    member(Periods, [p1, p2, p1_2]), schedule(ID, _, _, _, _, Periods),
    findClassesSemester(OtherClasses, Degree, Fall, Spring).
findClassesSemester([Class | OtherClasses], Degree, Fall, [Class | Spring]) :-
    event(ID, Class, _, _, _), shift(ID, Degree, _, _),
    member(Periods, [p3, p4, p3_4]), schedule(ID, _, _, _, _, Periods),
    findClassesSemester(OtherClasses, Degree, Fall, Spring).

/*
O predicado horasCurso/4 calcula as horais totais dum curso num periodo dum ano. Sendo horasCurso(Periodo, Curso, Ano, TotalHoras)
true, se TotalHoras forem as horas totais dos eventos dum curso Curso num periodo Periodo dum ano Ano.
*/
degreeDuration(Period, Degree, Year, TotalDuration) :-
    findall(ID, shift(ID, Degree, Year, _), EventsTemp), sort(EventsTemp, Events),
    findall(Duration, (member(ID, Events), eventSemester(Period, PeriodSemester),
        schedule(ID, _, _, _, Duration, PeriodSemester)), Durations), !, sum_list(Durations, TotalDuration).

/*
O predicado evolucaoHorasCurso/2 encontra a evolucao das horas totais dum curso a cada periodo de cada ano. Sendo
evolucaoHorasCurso(Curso, Evolucao) true, se Evolucao for uma lista de tuplos da forma (Ano, Periodo, TotalHoras)
ordenada ascendentemente por ano Ano e periodo Periodo e TotalHoras sendo as horas totais dum curso Curso num periodo Periodo dum ano Ano.
*/
degreeDurationChange(Degree, Change) :-
    degreeDurationChanges([1, 2, 3], Degree, Changes), append(Changes, Change).

% O predicado evolucaoHorasCursoPorLista/3, ou evolucaoHorasCursoPorLista([1, 2, 3], Curso, EvolucaoEmListas),
% encontra a evolucao das horas totais dum curso Curso a cada periodo Periodo de um ano Ano, organizando-as
% numa lista de listas de tuplos da forma (Ano, Periodo, TotalHoras) ordenada ascendentemente por ano
% Ano, periodo Periodo e TotalHoras sendo as horas totais dum curso num periodo Periodo dum ano Ano.
degreeDurationChanges([], _, []).
degreeDurationChanges([Year | OtherYears], Degree, [AnnualChanges | OtherAnnualChanges]) :-
    yearDegreeDuration(Degree, Year, YearDurations),
    yearDegreeChanges(Year, YearDurations, Degree, AnnualChanges),
    degreeDurationChanges(OtherYears, Degree, OtherAnnualChanges).

% O predicado horasCursoAnual/3, ou horasCursoAnual(Curso, Ano, ListaTotalHorasAnual), encontra as
% horas totais, organizando-as numa lista ListaTotalHorasAnual, dum curso Curso a cada periodo dum ano Ano.
yearDegreeDuration(Degree, Year, YearDurations) :-
    findall(PeriodDuration, (member(Period, [p1, p2, p3, p4]), degreeDuration(Period, Degree, Year, PeriodDuration)), YearDurations).

% O predicado evolucaoAnual/4, ou evolucaoAnual(Ano, ListaTotalHorasAnual, Curso, EvolucaoAnual),
% organiza a evolucao das horas totais duma lista ListaTotalHorasAnual dum curso Curso por periodo dum ano Ano.
yearDegreeChanges(Year, [P1Duration, P2Duration, P3Duration, P4Duration], _, AnnualChanges) :-
    append([[(Year, p1, P1Duration)], [(Year, p2, P2Duration)],
        [(Year, p3, P3Duration)], [(Year, p4, P4Duration)]], AnnualChanges).

/*
O predicado ocupaSlot/5 calcula as horais sobrepostas entre um evento e um slot. Sendo
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) true, se Horas forem as horas sobrepostas
entre um evento com entre as horas HoraInicioEvento e HoraFimEvento, e um slot entre a horas HoraInicioDada e HoraFimDada.
*/
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

/*
O predicado numHorasOcupadas/6 calcula as horas ocupadas em salas dum tipo num intervalo de tempo num dia de semana dum
periodo. Sendo numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras) true, se SomaHoras forem as
horas ocupadas nas salas do tipo TipoSala, entre as horas HoraInicio e HoraFim, num dia de semana DiaSemana dum periodo Periodo.
*/
reservedDurations(Period, RoomType, Weekday, InitialTime, FinalTime, SumDurations):-
    rooms(RoomType, Rooms),
    findall(Durations, (eventSemester(Period, PeriodSemester), member(Room, Rooms),
        schedule(ID, Weekday, EventStart, EventEnd, _, PeriodSemester),
        event(ID, _, _, _, Room),
        fillSlot(InitialTime, FinalTime, EventStart, EventEnd, Duration)), Durations),
    sum_list(Durations, SumDurations).

/*
O predicado ocupacaoMax/4 calcula as horas possiveis de serem ocupadas em salas dum tipo num
intervalo de tempo. Sendo ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max) true, se Max forem as
horas possiveis de serem ocupadas por salas do tipo TipoSala, entre as horas HoraInicio e HoraFim.
*/
maxCapacity(RoomType, EventStart, EventEnd, Max) :-
    rooms(RoomType, Rooms), length(Rooms, NumRooms), Max is NumRooms * (EventEnd - EventStart).

/*
O predicado percentagem/3, ou percentagem(SomaHoras, Max, Percentagem), calcula a percentagem Percentagem entre as
horas ocupadas SomaHoras e as possiveis Max em salas dum tipo num intervalo de tempo num dia de semana dum periodo.
*/
percentage(SumDurations, Max, Percentage) :- Percentage is (SumDurations / Max) * 100.

/*
O predicado ocupacaoCritica/4 encontra casos de tipos de salas num dia de semana com um dado limite minimo de percentagem
de ocupacao. Sendo ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados) true, se Resultados for uma lista ordenada
de tuplos casosCriticos(DiaSemana, TipoSala, Percentagem) com um dia de semana DiaSemana, um tipo de sala TipoSala e uma
percentagem Percentagem de ocupacao arredondada acima dum valor critico Threshold, entre as horas HoraInicio e HoraFim.
*/
criticalCapacity(EventStart, EventEnd, Threshold, Results) :-
    findall(criticalCases(Weekday, RoomType, PercentageInt), (rooms(RoomType, _), schedule(_, Weekday, _, _, _, Period),
        reservedDurations(Period, RoomType, Weekday, EventStart, EventEnd, SumDurations), maxCapacity(RoomType, EventStart, EventEnd, Max),
        percentage(SumDurations, Max, PercentageFloat), PercentageFloat > Threshold, ceiling(PercentageFloat, PercentageInt)), ResultsAux),
    sort(ResultsAux, Results).
