/*
O predicado eventosSemSalas/1 encontra IDs de eventos sem salas. Sendo eventosSemSalas(EventosSemSala)
true, se EventosSemSala for uma lista ordenada de IDs de eventos sem sala, sem IDs repetidos.
*/
eventosSemSalas(EventosSemSala) :- findall(ID, evento(ID, _, _, _, semSala), EventosSemSala).

/*
O predicado eventosSemSalasDiaSemana/2 encontra IDs de eventos sem salas dum dia da semana.
Sendo eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) true, se EventosSemSala for uma
lista ordenada de IDs de eventos sem sala, sem IDs repetidos, dum dia de semana DiaDaSemana.
*/
eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) :-
    findall(ID, (evento(ID, _, _, _, semSala), horario(ID, DiaDaSemana, _, _, _, _)), EventosSemSala).

/*
O predicado eventosSemSalasPeriodo/2 encontra IDs de eventos sem salas dum periodo. Sendo
eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala) true, se EventosSemSala for uma lista
ordenada de IDs de eventos sem sala, sem IDs repetidos, dos periodos duma lista ListaPeriodos.
*/
eventosSemSalasPeriodo([], []).
eventosSemSalasPeriodo([Periodo | RestoListaPeriodos], EventosSemSala) :-
    findall(ID,(evento(ID, _, _, _, semSala), eventoSemestral(Periodo, PeriodoSemestre),
    horario(ID, _, _, _, _, PeriodoSemestre)), EventosSemSalasDumPeriodo), !,
    eventosSemSalasPeriodo(RestoListaPeriodos, MaisEventosSemSala),
    append([EventosSemSalasDumPeriodo, MaisEventosSemSala], EventosSemSalasPeriodos),
    sort(EventosSemSalasPeriodos, EventosSemSala).

% O predicado eventoSemestral/2, ou eventoSemestral(Periodo, Periodos), associa
% o periodo Periodo ao respetivo semestre, devolvendo-os no periodo PeriodoSemestre.
eventoSemestral(Periodo, PeriodoSemestre) :-
    Periodo == p1, member(PeriodoSemestre, [Periodo, p1_2]);
    Periodo == p2, member(PeriodoSemestre, [Periodo, p1_2]);
    Periodo == p3, member(PeriodoSemestre, [Periodo, p3_4]);
    Periodo == p4, member(PeriodoSemestre, [Periodo, p3_4]).

/*
O predicado organizaEventos/3 encontra e ordena os IDs de eventos em duns do mesmo. Sendo
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) true, se EventosNoPeriodo for uma
lista ordenada de IDs de eventos duma lista ListaEventos, sem IDs repetidos, dum periodo Periodo.
*/
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) :-
    organizaEventosDesordenado(ListaEventos, Periodo, EventosNoPeriodoDesordenados),
    sort(EventosNoPeriodoDesordenados, EventosNoPeriodo).

% O predicado organizaEventosDesordenado/3, ou organizaEventos(ListaEventos, Periodo, EventosNoPeriodoDesordenados),
% encontra IDs de eventos duma lista ListaEventos em duns do mesmo periodo
% Periodo, organizando-os numa lista desordenada EventosNoPeriodoDesordenados.
organizaEventosDesordenado([], _, []).
organizaEventosDesordenado([Evento | RestoListaEventos], Periodo, [Evento | EventosNoPeriodo]) :-
    eventoSemestral(Periodo, PeriodoSemestre), horario(Evento, _, _, _, _, PeriodoSemestre), !,
    organizaEventosDesordenado(RestoListaEventos, Periodo, EventosNoPeriodo).
organizaEventosDesordenado([_ | RestoListaEventos], Periodo, EventosNoPeriodo) :-
    organizaEventosDesordenado(RestoListaEventos, Periodo, EventosNoPeriodo).

/*
O predicado eventosMenoresQue/2 encontra IDs de eventos com um dado limite maximo de duracao.
Sendo eventosMenoresQue(Duracao, ListaEventosMenoresQue) true, se ListaEventosMenoresQue for uma
lista ordenada de IDs de eventos, sem IDs repetidos, de duracao menor ou igual a duracao duma Duracao.
*/
eventosMenoresQue(Duracao, ListaEventosMenoresQue) :-
    findall(ID, (horario(ID, _, _, _, Duracoes, _), Duracoes =< Duracao), ListaEventosMenoresQue).

/*
O predicado eventosMenoresQueBool/2 verifica se um evento tem um dado limite maximo de duracao. Sendo
eventosMenoresQueBool(ID, Duracao) true, se o evento identificado pelo ID tiver duracao menor ou igual a duracao duma Duracao.
*/
eventosMenoresQueBool(ID, Duracao) :- horario(ID, _, _, _, Duracoes, _), Duracoes =< Duracao.
