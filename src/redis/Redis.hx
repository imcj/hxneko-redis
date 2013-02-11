/**
   Copyright (c) 2010-2013 SoybeanSoft, Ian Martins

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use,
   copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following
   conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.
   *
   * haXe/Neko RedisAPI
   * @author Guntur Sarwohadi
   * modified by Ian Martins
   */

package redis;

import haxe.Int32;
import neko.net.Host;
import neko.net.Socket;
using StringTools;

enum SlaveConfig
{
	THostPort(host :String, port :Int);
	TNoOne;
}

/*
 * client library for accessing a redis key value store.
 * documentation at http://redis.io/commands
 * not implemented: transactions, publish/subscribe, MONITOR, CONFIG
 */
class Redis 
{
    private var protocol :RedisProtocol;
	
	private static inline var EOL :String = "\r\n";
	private static inline var OK :String = "OK";
	private static inline var PONG :String = "PONG";
	
	public function new(?host :String = "localhost", ?port :Int = 6379, ?timeout :Float = 100) 
	{
		try
		{
			var socket = new Socket();
			socket.setTimeout(timeout);
			socket.connect(new Host(host), port);
			protocol = new RedisProtocol(socket.input, socket.output);
		}
		catch (ex : String)
		{
			throw new RedisError("-ERR unable to open connection");
		}
	}
	
    // ------------------------ keys

	public function del(keys :Array<String>) :Int
	{
		protocol.sendMultiBulkCommand("DEL", keys);
		return protocol.receiveInt();
	}

	public function dump(keys :Array<String>) :Void
	{
        throw "not implemented";
	}

	public function exists(key :String) :Bool
	{
		protocol.sendMultiBulkCommand("EXISTS", [key]);
		return protocol.receiveInt() == 1;
	}

	public function expire(key :String, seconds :Int) :Bool
	{
		protocol.sendMultiBulkCommand("EXPIRE", [key, Std.string(seconds)]);
		return protocol.receiveInt() == 1;
	}

	public function expireat(key :String, timestamp :String) :Bool
	{
		protocol.sendMultiBulkCommand("EXPIREAT", [key, timestamp]);
		return protocol.receiveInt() == 1;
	}

	public function keys(pattern :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("KEYS", [pattern]);
		return protocol.receiveMultiBulk();
	}

    public function migrate(host, port, key, destinationdb, timeout) :Void
	{
        throw "not implemented";
	}

	public function move(key :String, db :Int) :Bool
	{
		protocol.sendMultiBulkCommand("MOVE", [key, Std.string(db)]);
		return protocol.receiveInt() == 1;
	}

    public function object() :Void
	{
        throw "not implemented";
	}

    public function persist(key :String) :Void
	{
        throw "not implemented";
	}

    public function pexpire(key :String, milliseconds :Int) :Void
	{
        throw "not implemented";
	}

    public function pexpireat(key :String, timestamp :String) :Void
	{
        throw "not implemented";
	}

	public function pttl(key :String) :Void
	{
        throw "not implemented";
	}

	public function randomkey() :String
	{
		protocol.sendMultiBulkCommand("RANDOMKEY", []);
		return protocol.receiveBulk();
	}

	public function rename(key :String, newkey :String) :Bool
	{
		if (key == newkey)
			throw new RedisError("-ERR Key names must not match");
		protocol.sendMultiBulkCommand("RENAME", [key, newkey]);
		return protocol.receiveSingleLine() == OK;
	}

	public function renamenx(key :String, newkey :String) :Bool
	{
		if (key == newkey)
			throw new RedisError("-ERR Key names must not match");
		protocol.sendMultiBulkCommand("RENAMENX", [key, newkey]);
		return protocol.receiveInt() > 0;
	}

	public function restore() :Void
	{
        throw "not implemented";
	}

	public function ttl(key :String) :Int
	{
		protocol.sendMultiBulkCommand("TTL", [key]);
		return protocol.receiveInt();
	}

	public function type(key :String) :String
	{
		protocol.sendMultiBulkCommand("TYPE", [key]);
		return protocol.receiveSingleLine();
	}

    // ------------------------ strings

	public function append(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("APPEND", [key, value]);
		return protocol.receiveInt() > 0;
	}
	
    public function bitcount(key :String, ?start :Int, ?end :Int)
	{
        throw "not implemented";
	}

    public function bitop(operation, destkey, keys)
	{
        throw "not implemented";
	}

	public function decr(key :String) :Int
	{
		protocol.sendMultiBulkCommand("DECR", [key]);
		return protocol.receiveInt();
	}
	
	public function decrby(key :String, decrement :Int) :Int
	{
		protocol.sendMultiBulkCommand("DECRBY", [key, Std.string(decrement)]);
		return protocol.receiveInt();
	}
	
	public function get(key :String) :String
	{
		protocol.sendMultiBulkCommand("GET", [key]);
		return protocol.receiveBulk();
	}
	
	public function getbit(key :String) :Void
	{
        throw "not implemented";
	}
	
	public function getrange(key :String, start :Int, end :Int) :String
	{
		protocol.sendMultiBulkCommand("GETRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveBulk();
	}

	public function getset(key :String, value :String) :String
	{
		protocol.sendMultiBulkCommand("GETSET", [key, value]);
		return protocol.receiveBulk();
	}
	
	public function incr(key :String) :Int
	{
		protocol.sendMultiBulkCommand("INCR", [key]);
		return protocol.receiveInt();
	}
	
	public function incrby(key :String, increment :Int) :Int
	{
		protocol.sendMultiBulkCommand("INCRBY", [key, Std.string(increment)]);
		return protocol.receiveInt();
	}
	
	public function incrbyfloat(key :String, increment :Float) :Float
	{
		protocol.sendMultiBulkCommand("INCRBYFLOAT", [key, Std.string(increment)]);
		return Std.parseFloat(protocol.receiveBulk());
	}
	
	public function mget(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("MGET", keys);
		return protocol.receiveMultiBulk();
	}
	
    // pass keys and values in a hash
	public function mset(keysvals :Hash<String>) :Bool
	{
		var params = new Array<String>();
		for( kk in keysvals.keys() )
		{
			params.push(kk);
			params.push(keysvals.get(kk));
		}
		protocol.sendMultiBulkCommand("MSET", params);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function msetnx(keysvals :Hash<String>) :Bool
	{
		var params = new Array<String>();
		for( kk in keysvals.keys() )
		{
			params.push(kk);
			params.push(keysvals.get(kk));
		}
		protocol.sendMultiBulkCommand("MSETNX", params);
		return protocol.receiveSingleLine() == OK;
	}
	
    public function psetex(key :String, milliseconds :Int, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("SETEX", [key, Std.string(milliseconds), value]);
		return protocol.receiveSingleLine() == OK;
	}

	public function set(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("SET", [key, value]);
		return protocol.receiveSingleLine() == OK;
	}

    public function setbit(key :String, offset :Int, value :Bool)
	{
        throw "not implemented";
	}

	public function setex(key :String, seconds :Int, value :String)
	{
		protocol.sendMultiBulkCommand("SETEX", [key, Std.string(seconds), value]);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function setnx(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("SETNX", [key, value]);
		return protocol.receiveInt() > 0;
	}
	
    public function setrange(key :String, offset :Int, value :String) :Int
	{
        protocol.sendMultiBulkCommand("SETRANGE", [key, Std.string(offset), value]);
		return protocol.receiveInt();
	}

    public function strlen(key :String) :Int
	{
        protocol.sendMultiBulkCommand("STRLEN", [key]);
		return protocol.receiveInt();
	}

    // ------------------------ hash

	public function hdel(key :String, field :String) :Bool
	{
		protocol.sendMultiBulkCommand("HDEL", [key, field]);
		return protocol.receiveInt() > 0;
	}

	public function hexists(key :String, field :String) :Bool
	{
		protocol.sendMultiBulkCommand("HEXISTS", [key, field]);
		return protocol.receiveInt() > 0;
	}

	public function hget(key :String, field :String) :String
	{
		protocol.sendMultiBulkCommand("HGET", [key, field]);
		return protocol.receiveBulk();
	}

	public function hgetall(key :String) :Hash<String>
	{
		protocol.sendMultiBulkCommand("HGETALL", [key]);
		var all = protocol.receiveMultiBulk();
		var ret = new Hash<String>();
		while( all.length > 0 )
            ret.set(all.shift(), all.shift());
		return ret;
	}

	public function hincrby(key :String, field :String, increment :Int) :Int
	{
		protocol.sendMultiBulkCommand("HINCRBY", [key, field, Std.string(increment)]);
		return protocol.receiveInt();
	}

	public function hincrbyfloat(key :String, field :String, increment :Float) :Float
	{
		protocol.sendMultiBulkCommand("HINCRBYFLOAT", [key, field, Std.string(increment)]);
		return Std.parseFloat(protocol.receiveBulk());
	}

	public function hkeys(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("HKEYS", [key]);
		return protocol.receiveMultiBulk();
	}

	public function hlen(key :String) :Int
	{
		protocol.sendMultiBulkCommand("HLEN", [key]);
		return protocol.receiveInt();
	}

	public function hmget(key :String, fields :Array<String>) :Array<String>
	{
		var params = fields.copy();
		params.unshift(key);
		protocol.sendMultiBulkCommand("HMGET", params);
		return protocol.receiveMultiBulk();
	}

	public function hmset(key :String, fields :Hash<String>) :Bool
	{
		var params = new Array<String>();
		params.push(key);
		for( kk in fields.keys() )
		{
			params.push(kk);
			params.push(fields.get(kk));
		}
		protocol.sendMultiBulkCommand("HMSET", params);
		return protocol.receiveSingleLine() == OK;
	}

	public function hset(key :String, field :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("HSET", [key, field, value]);
		return protocol.receiveInt() > 0;
	}
	
	public function hsetnx(key :String, field :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("HSETNX", [key, field, value]);
		return protocol.receiveInt() > 0;
	}

	public function hvals(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("HVALS", [key]);
		return protocol.receiveMultiBulk();
	}

    // ------------------------ lists

	public function blpop(key :String, seconds :Int) :String
	{
		protocol.sendMultiBulkCommand("BLPOP", [key, Std.string(seconds)]);
		return protocol.receiveBulk();
	}
	
	public function brpop(key :String, seconds :Int) :String
	{
		protocol.sendMultiBulkCommand("BRPOP", [key, Std.string(seconds)]);
		return protocol.receiveBulk();
	}
	
	public function brpoppush(key :String, destination :String, seconds :Int) :String
	{
		protocol.sendMultiBulkCommand("BRPOPPUSH", [key, destination, Std.string(seconds)]);
		return protocol.receiveBulk();
	}
	
	public function lindex(key :String, index :Int) :String
	{
		protocol.sendMultiBulkCommand("LINDEX", [key, Std.string(index)]);
		return protocol.receiveBulk();
	}
	
	public function llen(key :String) :Int
	{
		protocol.sendMultiBulkCommand("LLEN", [key]);
		return protocol.receiveInt();
	}
	
	public function lpop(key :String) :String
	{
		protocol.sendMultiBulkCommand("LPOP", [key]);
		return protocol.receiveBulk();
	}
	
	public function lpush(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("LPUSH", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	public function lpushx(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("LPUSHX", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	public function lrange(key :String, start :Int, end :Int) :Array<String>
	{
		protocol.sendMultiBulkCommand("LRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}
	
	public function lrem(key :String, count :Int, value :String) :Int
	{
		protocol.sendMultiBulkCommand("LREM", [key, Std.string(count), value]);
		return protocol.receiveInt();
	}
	
	public function lset(key :String, index :Int, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("LSET", [key, Std.string(index), value]);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function ltrim(key :String, start :Int, end :Int) :Bool
	{
		protocol.sendMultiBulkCommand("LTRIM", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function rpop(key :String) :String
	{
		protocol.sendMultiBulkCommand("RPOP", [key]);
		return protocol.receiveBulk();
	}
	
	public function rpoplpush(source :String, destination :String) :String
	{
		protocol.sendMultiBulkCommand("RPOPLPUSH", [source, destination]);
		return protocol.receiveBulk();
	}
	
	public function rpush(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("RPUSH", [key, Std.string(value)]);
		return protocol.receiveInt();
	}

	public function rpushx(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("RPUSHX", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
    // ------------------------ sets

	public function sadd(key :String, members :Array<String>) :Bool
	{
		var params = members.copy();
		params.unshift(key);
		protocol.sendMultiBulkCommand("SADD", params);
		return protocol.receiveInt() > 0;
	}
	
	public function scard(key :String) :Int
	{
		protocol.sendMultiBulkCommand("SCARD", [key]);
		return protocol.receiveInt();
	}
	
	public function sdiff(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SDIFF", keys);
		return protocol.receiveMultiBulk();
	}
	
	public function sdiffstore(destination :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(destination);
		protocol.sendMultiBulkCommand("SDIFFSTORE", params);
		return protocol.receiveInt() > 0;
	}

	public function sinter(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SINTER", keys);
		return protocol.receiveMultiBulk();
	}
	
	public function sinterstore(destination :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(destination);
		protocol.sendMultiBulkCommand("SINTERSTORE", params);
		return protocol.receiveInt() > 0;
	}

	public function sismember(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SISMEMBER", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	public function smembers(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("SMEMBERS", [key]);
		return protocol.receiveMultiBulk();
	}
	
	public function smove(source :String, destination :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SMOVE", [source, destination, member]);
		return protocol.receiveInt() > 0;
	}
	
	public function spop(key :String) :String
	{
		protocol.sendMultiBulkCommand("SPOP", [key]);
		return protocol.receiveBulk();
	}

	public function srandmember(key :String) :String 
	{
		protocol.sendMultiBulkCommand("SRANDMEMBER", [key]);
		return protocol.receiveBulk();
	}
	
	public function srem(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SREM", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	public function sunion(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SUNION", keys);
		return protocol.receiveMultiBulk();
	}
	
	public function sunionstore(destination :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(destination);
		protocol.sendMultiBulkCommand("SUNIONSTORE", params);
		return protocol.receiveInt() > 0;
	}
	
    // ------------------------ sorted sets

    // membersscores is member -> score
	public function zadd(key :String, membersscores :Hash<Float>) :Bool
	{
        var params = [key];
        for( key in membersscores.keys() )
        {
            params.push(Std.string(membersscores.get(key)));
            params.push(key);
        }
		protocol.sendMultiBulkCommand("ZADD", params);
		return protocol.receiveInt() > 0;
	}
	
	public function zcard(key :String) :Int
	{
		protocol.sendMultiBulkCommand("ZCARD", [key]);
		return protocol.receiveInt();
	}
	
	public function zcount(key :String, min :String, max :String) :Int
	{
		protocol.sendMultiBulkCommand("ZCOUNT", [key, min, max]);
		return protocol.receiveInt();
	}
	
	public function zincrby(key :String, increment :Float, member :String) :Float
	{
		protocol.sendMultiBulkCommand("ZINCRBY", [key, Std.string(increment), member]);
		return Std.parseFloat(protocol.receiveBulk());
	}

	public function zinterstore(destination :String, keys :Array<String>, ?weights :Array<Float>, ?aggregate :String) :Int
	{
		var params = keys.copy();
		params.unshift(Std.string(keys.length));
		params.unshift(destination);
		if( weights != null )
		{
			params.push("WEIGHTS");
			for( ww in weights )
				params.push(Std.string(ww));
		}
		if( aggregate != null )
		{
			params.push("AGGREGATE");
			params.push(aggregate);
		}
		protocol.sendMultiBulkCommand("ZINTERSTORE", params);
		return protocol.receiveInt();
	}

	public function zrange(key :String, start :Int, end :Int, ?withScores :Bool = false) :Array<String>
	{
        if( withScores )
            protocol.sendMultiBulkCommand("ZRANGE", [key, Std.string(start), Std.string(end), "WITHSCORES"]);
        else
            protocol.sendMultiBulkCommand("ZRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}

	public function zrangebyscore(key :String, min :String, max :String, ?offset :Int, ?count :Int) :Array<String>
	{
        if( count != null )
            protocol.sendMultiBulkCommand("ZRANGEBYSCORE", [key, min, max, "LIMIT", Std.string(offset), Std.string(count)]);
        else
            protocol.sendMultiBulkCommand("ZRANGEBYSCORE", [key, min, max]);
		return protocol.receiveMultiBulk();
	}

	public function zrank(key :String, member :String) :Int
	{
		protocol.sendMultiBulkCommand("ZRANK", [key, member]);
		return protocol.receiveInt();
	}

	public function zrem(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("ZREM", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	public function zremrangebyrank(key :String, start :Int, end :Int) :Int
	{
		protocol.sendMultiBulkCommand("ZREMRANGEBYRANK", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveInt();
	}
	
	public function zremrangebyscore(key :String, min :String, max :String) :Int
	{
		protocol.sendMultiBulkCommand("ZREMRANGEBYSCORE", [key, min, max]);
		return protocol.receiveInt();
	}
	
	public function zrevrange(key :String, start :Int, end :Int, ?withScores :Bool = false) :Array<String>
	{
        if( withScores )
            protocol.sendMultiBulkCommand("ZREVRANGE", [key, Std.string(start), Std.string(end), "WITHSCORES"]);
        else
            protocol.sendMultiBulkCommand("ZREVRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}
	
	public function zrevrangebyscore(key :String, max :String, min :String, ?withScores :Bool = false, ?offset :Int, ?count :Int) :Array<String>
	{
        var params = [key, max, min];
        if( withScores )
            params.push("WITHSCORES");
        if( offset != null )
        {
            params.push("LIMIT");
            params.push(Std.string(offset));
            params.push(Std.string(count));
        }
        protocol.sendMultiBulkCommand("ZREVRANGE", params);
		return protocol.receiveMultiBulk();
	}
	
	public function zrevrank(key :String, member :String) :Int
	{
		protocol.sendMultiBulkCommand("ZREVRANK", [key, member]);
		return protocol.receiveInt();
	}
	
	public function zscore(key :String, member :String) :Float
	{
		protocol.sendMultiBulkCommand("ZSCORE", [key, member]);
		return Std.parseFloat(protocol.receiveBulk());
	}

	public function zunionstore(destination :String, keys :Array<String>, ?weights :Array<Float>, ?aggregate :String) :Int
	{
		var params = keys.copy();
		params.unshift(Std.string(keys.length));
		params.unshift(destination);
		if( weights != null )
		{
			params.push("WEIGHTS");
			for( ww in weights )
				params.push(Std.string(ww));
		}
		if( aggregate != null )
		{
			params.push("AGGREGATE");
			params.push(aggregate);
		}
		protocol.sendMultiBulkCommand("ZUNIONSTORE", params);
		return protocol.receiveInt();
	}

    // ------------------------ pub sub

    public function discard() :Void
    {
        throw "not implemented";
    }

    public function psubscribe() :Void
    {
        throw "not implemented";
    }

    public function publish() :Void
    {
        throw "not implemented";
    }

    public function punsubscribe() :Void
    {
        throw "not implemented";
    }

    public function subscribe() :Void
    {
        throw "not implemented";
    }

    public function unsubscribe() :Void
    {
        throw "not implemented";
    }

    // ------------------------ transactions

    public function exec() :Void
    {
        throw "not implemented";
    }

    public function multi() :Void
    {
        throw "not implemented";
    }

    public function unwatch() :Void
    {
        throw "not implemented";
    }

    public function watch() :Void
    {
        throw "not implemented";
    }

    // ------------------------ scripting

    public function eval() :Void
    {
        throw "not implemented";
    }

    public function evalsha() :Void
    {
        throw "not implemented";
    }

    public function scriptexists() :Void
    {
        throw "not implemented";
    }

    public function scriptflush() :Void
    {
        throw "not implemented";
    }

    public function scriptkill() :Void
    {
        throw "not implemented";
    }

    public function scriptload() :Void
    {
        throw "not implemented";
    }

    // ------------------------ sort

	public function sort(key :String, ?byPattern :String, ?start :Int = 0, ?end :Int = 0, ?getPattern :String, ?isAscending :Bool = true, ?isAlpha :Bool = false, ?dstKey :String) :Dynamic
	{
		var params = [key];
		
		if (byPattern != null)
        {
			params.push("BY");
            params.push(byPattern);
        }
		
		if (end > 0)
        {
			params.push("LIMIT");
            params.push(Std.string(start));
            params.push(Std.string(end));
        }
		
		if (getPattern != null)
        {
			params.push("GET");
            params.push(getPattern);
        }
		
		if (!isAscending)
			params.push("DESC");
		
		if (isAlpha)
			params.push("ALPHA");
		
		if (dstKey != null)
        {
			params.push("STORE");
            params.push(dstKey);
        }
		
		protocol.sendMultiBulkCommand("SORT", params);

		if (dstKey == null)
            return protocol.receiveMultiBulk();
		else
            return protocol.receiveInt();
	}
	
    // ------------------------ connection

	public function auth(password :String) :Bool
	{
		protocol.sendMultiBulkCommand("AUTH", [password]);
		return protocol.receiveSingleLine() == OK;
	}

	public function ping() :Bool
	{
		protocol.sendMultiBulkCommand("PING", []);
		return protocol.receiveSingleLine() == PONG;
	}
	
	public function quit() :Void
	{
		protocol.sendMultiBulkCommand("QUIT", []);
	}

	public function select(index :Int) :Bool
	{
		protocol.sendMultiBulkCommand("SELECT", [Std.string(index)]);
		return protocol.receiveSingleLine() == OK;
	}
	
	
    // ------------------------ server

	public function bgrewriteaof() :Bool
	{
		protocol.sendMultiBulkCommand("BGREWRITEAOF", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function bgsave() :Bool
	{
		protocol.sendMultiBulkCommand("BGSAVE", []);
		return protocol.receiveSingleLine() == OK;
	}
	
    public function clientkill() :Void
    {
        throw "not implemented";
    }

    public function clientlist() :Void
    {
        throw "not implemented";
    }

    public function clientgetname() :Void
    {
        throw "not implemented";
    }

    public function clientsetname() :Void
    {
        throw "not implemented";
    }

    public function configget() :Void
    {
        throw "not implemented";
    }

    public function configset() :Void
    {
        throw "not implemented";
    }

    public function configresetstat() :Void
    {
        throw "not implemented";
    }

	public function dbsize() :Int
	{
		protocol.sendMultiBulkCommand("DBSIZE", []);
		return protocol.receiveInt();
	}
	
	public function debugobject() :Void
	{
        throw "not implemented";
	}
	
	public function debugsetfault() :Void
	{
        throw "not implemented";
	}
	
    public function echo() :Void
    {
        throw "not implemented";
    }

	public function flushall() :Bool
	{
		protocol.sendMultiBulkCommand("FLUSHALL", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function flushdb() :Bool
	{
		protocol.sendMultiBulkCommand("FLUSHDB", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function info(?section) :String
	{
        var param = (section==null) ? [] : [section];
		protocol.sendMultiBulkCommand("INFO", param);
		return protocol.receiveBulk();
	}
	
	public function lastsave() :Int
	{
		protocol.sendMultiBulkCommand("LASTSAVE", []);
		return protocol.receiveInt();
	}
	
    public function monitor() :Void
    {
        throw "not implemented";
    }

	public function save() :Bool
	{
		protocol.sendMultiBulkCommand("SAVE", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	public function shutdown() :Void
	{
		protocol.sendMultiBulkCommand("SHUTDOWN", []);
	}
	
	public function slaveof(config :SlaveConfig) :Bool
	{
		var param :Array<String>;
		switch(config)
		{
        case THostPort(host, port):
            param = [host, Std.string(port)];
			
        case TNoOne:
            param = ["no one"];
		}
		protocol.sendMultiBulkCommand("SLAVEOF", param);
		return protocol.receiveSingleLine() == OK;
	}

    public function slowlog() :Void
    {
        throw "not implemented";
    }

    public function sync() :Void
    {
        throw "not implemented";
    }

    public function time() :Void
    {
        throw "not implemented";
    }
}
