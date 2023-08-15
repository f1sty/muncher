-module(muncher_srv).

-behaviour(gen_server).

-export([start_link/1, append/2]).
-export([init/1, handle_call/3, handle_info/2]).

-record(state, {timeout, files = #{}}).

-include_lib("kernel/include/logger.hrl").

-define(TIMEOUT, timer:seconds(10)).

start_link(TimeoutArg) ->
    Timeout =
        case is_integer(TimeoutArg) of
            true ->
                timer:seconds(TimeoutArg);
            false ->
                ?TIMEOUT
        end,
    gen_server:start_link({local, ?MODULE}, ?MODULE, Timeout, []).

init(Timeout) ->
    logger:set_primary_config(level, info),
    {ok, #state{timeout = Timeout}}.

handle_call({append, FilePath, String},
            _From,
            #state{timeout = Timeout, files = Files} = State) ->
    IoDevice =
        case Files of
            #{FilePath := {IoDevice, OldTimer}} ->
                ?LOG_INFO("Append to already opened file: ~s", [FilePath]),
                {ok, cancel} = timer:cancel(OldTimer),
                IoDevice;
            Files ->
                ?LOG_INFO("Open new file and append: ~s", [FilePath]),
                {ok, IoDevice} = file:open(FilePath, [append]),
                IoDevice
        end,
    ok = file:write(IoDevice, String),
    {ok, Timer} = timer:send_after(Timeout, {timeout, FilePath}),
    FilesNew = Files#{FilePath => {IoDevice, Timer}},

    {reply, ok, State#state{files = FilesNew}}.

handle_info({timeout, FilePath}, #state{files = Files} = State) ->
    ?LOG_INFO("Close file due to timeout: ~s", [FilePath]),
    case Files of
        #{FilePath := {IoDevice, _}} ->
            ok = file:close(IoDevice),
            FilesNew = maps:remove(FilePath, Files),

            {noreply, State#state{files = FilesNew}};
        _ ->
            {noreply, State}
    end;
handle_info(_Msg, State) ->
    {noreply, State}.

append(FilePath, String) ->
    gen_server:call(?MODULE, {append, FilePath, ["\n", String]}).
