-module(mod_pubsub_cache_mnesia).

-include("pubsub.hrl").
-include("jlib.hrl").

-export([start/0, stop/0]).

-export([
         upsert_last_item/4,
         get_last_item/2,
         delete_last_item/2]).

%% ------------------------ Backend start/stop ------------------------

-spec start() -> ok.
start() ->
    create_table().

-spec stop() -> ok.
stop() ->
    ok.

-spec upsert_last_item(Nidx :: mod_pubsub:nodeIdx(),
                 ItemID :: mod_pubsub:itemId(),
                 Publisher::jid:ljid(),
                 Payload::mod_pubsub:payload()) -> ok | {error, Reason :: term()}.
upsert_last_item(Nidx, ItemId, Publisher, Payload) ->
    try mnesia:dirty_write(
        {pubsub_last_item,
        Nidx,
        ItemId,
        {os:timestamp(), jid:to_lower(jid:to_bare(Publisher))},
        Payload}
    ) of
        ok -> ok
    catch
        exit:{aborted, Reason} -> {error, Reason}
    end.

-spec get_last_item(Host :: binary(),
                    Nidx :: mod_pubsub:nodeIdx()) -> [mod_pubsub:pubsubLastItem()] | {error, Reason :: term()}.
get_last_item(_Host, Nidx) ->
    try mnesia:dirty_read({pubsub_last_item, Nidx}) of
        [LastItem] -> {ok, LastItem};
        [] -> {error, no_items}
    catch
        exit:{aborted, Reason} -> {error, Reason}
    end.

-spec delete_last_item(Host :: binary(),
                       Nidx :: mod_pubsub:nodeIdx()) -> ok | {error, Reason :: term()}.
delete_last_item(_Host, Nidx) ->
    try mnesia:dirty_delete({pubsub_last_item, Nidx}) of
        ok -> ok
    catch
        exit:{aborted, Reason} -> {error, Reason}
    end.

%% ------------------------ Helpers ----------------------------

-spec create_table() -> ok | {error, Reason :: term()}.
create_table() ->
    QueryResult = mnesia:create_table(
        pubsub_last_item,
        [
            {ram_copies, [node()]},
            {attributes, record_info(fields, pubsub_last_item)}
        ]),
        mnesia:add_table_copy(pubsub_last_item, node(), ram_copies),
        process_query_result(QueryResult).

process_query_result({atomic, ok}) -> ok;
process_query_result({aborted, {already_exists, pubsub_last_item}}) -> ok;
process_query_result({aborted, Reason}) -> {error, Reason}.
