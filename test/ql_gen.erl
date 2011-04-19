%%%-------------------------------------------------------------------
%%% @author Samuel Rivas <samuel.rivas@lambdastream.com>
%%% @author Carlos Varela <carlos.varela.paz@gmail.com>
%%% @copyright (C) 2009, Samuel Rivas
%%% @copyright (C) 2011, Carlos Varela
%%% @doc Some generators for QuickCheck
%%% @version {@vsn}, {@date} {@time}
%%%
%%% @type gen().
%%% A QuickCheck generator
%%%
%%% @end
%%% Created : 16 Jul 2009 by Samuel Rivas <samuel.rivas@lambdastream.com>
%%% TESTING This module is tested by ql_gen_eqc
%%%-------------------------------------------------------------------
-module(ql_gen).

-export([int_list/0, non_empty_list/1, non_empty_int_list/0, list_pos/1,
         small_letter/0, big_letter/0, setish_list/1, non_empty_setish_list/1,
         in_intervals/1, printable/0, string/0, atom/0, file_name/0,
         erlang_identifier/0, list_with_duplicates/1, permutation/1,
         setish_vector/2, non_empty_string/0, string/1, char_list/0,
	 char_list/1, escaped_xml_string/0, list_of_size/2]).

-include_lib("eqc/include/eqc.hrl").

%%--------------------------------------------------------------------
%% @doc Generate a list of generator of size 'Size'
%% @spec list_of_size(int(), gen()) -> [gen()]
%% @end
%%--------------------------------------------------------------------
list_of_size(Size, Gen) ->
    lists:map(
      fun(_) ->
              Gen
      end, lists:seq(1,Size)).

%%--------------------------------------------------------------------
%% @doc A simple shortcut to eqc_gen:list(eqc_gen:int())
%% @spec int_list() -> gen()
%% @end
%%--------------------------------------------------------------------
int_list() ->
    eqc_gen:list(eqc_gen:int()).

%%--------------------------------------------------------------------
%% @doc Generates a non empty list of elements generated by `Gen.'
%% @spec non_empty_list(gen()) -> gen()
%% @end
%%--------------------------------------------------------------------
non_empty_list(Gen) ->
    ?LET(Element, Gen, [Element | eqc_gen:list(Gen)]).

%%--------------------------------------------------------------------
%% @doc Generates a non empty list of integers
%% @spec non_empty_int_list() -> gen()
%% @end
%%--------------------------------------------------------------------
non_empty_int_list()->
    non_empty_list(eqc_gen:int()).

%%--------------------------------------------------------------------
%% @doc Generates a position in `L.'
%%
%% I.e. generates an integer between 1 and `length(L),' both included.
%% @spec list_pos([term() | [term()]]) -> gen()
%% @end
%%--------------------------------------------------------------------
list_pos(L = [_|_]) ->
    eqc_gen:choose(1, length(L)).

%%--------------------------------------------------------------------
%% @doc Generates a character ranging from a to z (included)
%% @spec small_letter() -> gen()
%% @end
%%--------------------------------------------------------------------
small_letter() ->
    eqc_gen:choose($a, $z).

%%--------------------------------------------------------------------
%% @doc Generates a character ranging from A to Z (included)
%% @spec big_letter() -> gen()
%% @end
%%--------------------------------------------------------------------
big_letter() ->
    eqc_gen:choose($A, $Z).

%%--------------------------------------------------------------------
%% @doc Generates a printable character.
%%
%% Printable characters are thoes in the ranges 8..13, 27, and 32..126
%% @spec printable() -> gen()
%% @end
%%--------------------------------------------------------------------
printable() ->
    in_intervals([{32, 126}, {8, 13}, {27, 27}]).

%%--------------------------------------------------------------------
%% @doc Generates a XML valid character.
%% 
%% Valid characters are 9, 10, 13 and 32..126
%% NOTE: Character 13 is valid (\r) but it's not correctly
%% parsed by xmerl (turns it into \n, so it's currently out of
%% the boundaries of this generator
%% @spec xml_printable() -> gen()
%% @end
%%--------------------------------------------------------------------
xml_printable() ->
    in_intervals([{9, 9}, {10,10}, {32, 126}]).


%%--------------------------------------------------------------------
%% @doc Generates a string
%%
%% This is the same as `eqc_gen:list(printable()).'
%% @spec string() -> gen()
%% @end
%%--------------------------------------------------------------------
string() ->
    eqc_gen:list(printable()).

%%--------------------------------------------------------------------
%% @doc Generates an xml string with valid characters
%%
%% This is the same as `eqc_gen:list(xml_printable())'
%% @spec xml_string() -> gen()
%% @end
%%--------------------------------------------------------------------
xml_string() ->
    eqc_gen:list(xml_printable()).

%%--------------------------------------------------------------------
%% @doc Generates an escaped string for XML
%% @spec escaped_xml_string() -> gen()
%% @end
%%--------------------------------------------------------------------
escaped_xml_string() ->
    ?LET(String, xml_string(),
	 lists:flatten([escape_char_xml(A)||A<-String])).
      
%%--------------------------------------------------------------------
%% @doc Generates a non empty string
%%
%% This is the same as `non_empty_list(printable()).'
%% @spec non_empty_string() -> gen()
%% @end
%%--------------------------------------------------------------------
non_empty_string() ->
    non_empty_list(printable()).

%%--------------------------------------------------------------------
%% @doc Generates an atom
%%
%% This is roughly the same as `list_to_atom(string()).'
%% @spec atom() -> gen()
%% @end
%%--------------------------------------------------------------------
atom() ->
    ?LET(S, eqc_gen:list(printable()), list_to_atom(S)).

%%--------------------------------------------------------------------
%% @doc Generates a list, without duplicates, of elements generated by `G.'
%% @spec setish_list(gen()) -> gen()
%% @end
%%--------------------------------------------------------------------
setish_list(Gen) ->
    ?LET(L, eqc_gen:list(Gen), remove_duplicates(L)).

%%--------------------------------------------------------------------
%% @doc Generates an integer from one of the closed intervals in the list.
%%
%% For shirking, first intervals are considered smaller, so is first elements of
%% the interval.
%% @spec in_intervals([{int(), int()}]) -> gen()
%% @end
%%--------------------------------------------------------------------
in_intervals(Intervals) ->
    eqc_gen:elements(lists:flatten([lists:seq(A, B) || {A, B} <- Intervals])).

%%--------------------------------------------------------------------
%% @doc Generates a non-empty list, without duplicates, of elements generated by
%% `G.'
%% @spec non_empty_setish_list(gen()) -> gen()
%% @end
%%--------------------------------------------------------------------
non_empty_setish_list(Gen) ->
    ?LET(L, non_empty_list(Gen), remove_duplicates(L)).

%%--------------------------------------------------------------------
%% @doc Generates a valid file name
%% @spec file_name() -> gen()
%% @end
%%--------------------------------------------------------------------
file_name() ->
    ?SUCHTHAT(
       Name, non_empty_list(in_intervals([{$0, $~}, {32, $.}])),
       Name =/= "." andalso Name =/= "..").

%%--------------------------------------------------------------------
%% @doc Generates a valid erlang identifier
%% @spec erlang_identifier() -> gen()
%% @end
%%--------------------------------------------------------------------
erlang_identifier() ->
    ?LET(
       First, ql_gen:small_letter(),
       ?LET(
          L, eqc_gen:list(eqc_gen:frequency([{1, $_},
                                             {5, ql_gen:small_letter()}])),
          [First | L])).

%%--------------------------------------------------------------------
%% @doc Generates a list with duplicates.
%%
%% Note that this generator doesn't generate []
%% @spec list_with_duplicates(gen()) -> gen()
%% @end
%%--------------------------------------------------------------------
list_with_duplicates(G) ->
    ?LET(
       L, non_empty_list(G),
       ?LET(
	  Dups, non_empty_list(eqc_gen:elements(L)),
	  permutation(L ++ Dups))).

%%--------------------------------------------------------------------
%% @doc Generates a permutation of the elements of `L.'
%% @spec permutation([term()]) -> gen()
%% @end
%%--------------------------------------------------------------------
permutation([]) ->
    [];
permutation(L) ->
    ?LET(E, eqc_gen:elements(L), [E | permutation(lists:delete(E, L))]).

%%--------------------------------------------------------------------
%% @doc Generates a N elements list without duplicates of elements from `G.'
%%
%% Note that `Gen' must be able to generate at least `N' different elements.
%% @spec setish_vector(int(), gen()) -> gen()
%% @end
%%--------------------------------------------------------------------
setish_vector(N, Gen) ->
    ?LET(V, setish_vector(N, Gen, []), permutation(V)).

setish_vector(0, _Gen, _) ->
    [];
setish_vector(N, Gen, Acc) ->
    ?LET(
       X, ?SUCHTHAT(X, Gen, not lists:member(X, Acc)),
       [X | setish_vector(N - 1, Gen, [X|Acc])]).

%%--------------------------------------------------------------------
%% @doc Generates a string of chars from `CharList'
%%
%% A list generator of `string/0' rarely generates duplicates, often needs
%% more than 1000 tests. Using `string/1' with a reduced char set, generates
%% this duplicates.
%%
%% @see char_list/0
%% @see char_list/1
%% @spec string([char()]) -> gen()
%% @end
%%--------------------------------------------------------------------
string(CharList) ->
    eqc_gen:list(eqc_gen:oneof(CharList)).

%%--------------------------------------------------------------------
%% @doc Generates a list of printable characters
%%
%% @spec char_list() -> gen()
%% @end
%%--------------------------------------------------------------------
char_list() ->
    ql_gen:non_empty_list(ql_gen:printable()).

%%--------------------------------------------------------------------
%% @doc Generates a list with `N' different printable characters
%%
%% @spec char_list(int()) -> gen()
%% @end
%%--------------------------------------------------------------------
char_list(N) ->
    ql_gen:setish_vector(N, ql_gen:printable()).
%%%-------------------------------------------------------------------
%%% Internals
%%%-------------------------------------------------------------------
remove_duplicates(L) ->
    lstd_lists:remove_duplicates(L).

%%--------------------------------------------------------------------
%% @private
%% @doc Transform a character into its internal XML representation
%% @spec escape_char_xml(char()) -> string()
%% @end
%%--------------------------------------------------------------------
escape_char_xml($<) ->
    "&lt;";
escape_char_xml($>) ->
    "&gt;";
escape_char_xml($&) ->
    "&amp;";
escape_char_xml($") ->
    "&quot;";
escape_char_xml($') ->
    "&apos;";
escape_char_xml(X) ->
    [X].

