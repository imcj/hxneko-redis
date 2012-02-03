/**
 Copyright (c) 2010 SoybeanSoft

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
 * 
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
	
	/*
	 * ===================================
	 * PUBLICS
	 * ===================================
	 */
	
	 /**
	  * Test the connection.
	  * @return true if redis responds
	  */
	public function ping() :Bool
	{
		protocol.sendMultiBulkCommand("PING", []);
		return protocol.receiveSingleLine() == PONG;
	}
	
	 /**
	  * Test if the specified key exists.
	  * @param	key the key to look for
	  * @return	true if the key exists
	  */
	public function exists(key :String) :Bool
	{
		protocol.sendMultiBulkCommand("EXISTS", [key]);
		return protocol.receiveInt() == 1;
	}
	
	/**
	 * Remove the specified keys. If a given key does not exist no operation is performed.
	 * @param	key the key to remove
	 * @return	the number of keys removed
	 */
	public function delete(keys :Array<String>) :Int
	{
		protocol.sendMultiBulkCommand("DEL", keys);
		return protocol.receiveInt();
	}
	
	/**
	 * Get the type of the value stored at key in form of a string. The type can be one of
	 * "none", "string", "list", "set". "none" is returned if the key does not exist.
	 * @param	key the key to check
	 * @return	the type of the value stored at "key"
	 */
	public function type(key :String) :String
	{
		protocol.sendMultiBulkCommand("TYPE", [key]);
		return protocol.receiveSingleLine();
	}
	
	/**
	 * Returns all the keys matching the glob-style pattern as space separated strings. For
	 * example if you have in the database the keys "foo" and "foobar" the command "KEYS foo*"
	 * will return "foo foobar".
	 * Glob style patterns examples:
	 * - h?llo will match hello hallo hhllo
	 * - h*llo will match hllo heeeello
	 * - h[ae]llo will match hello and hallo, but not hillo
	 * Use \ to escape special chars if you want to match them verbatim.
	 * @param	pattern a regex-like pattern
	 * @return	all keys in db that match "pattern"
	 */
	public function keys(pattern :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("KEYS", [pattern]);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * Get a randomly selected key from the currently selected DB.
	 * @return a random key from the db
	 */
	public function randomKey() :String
	{
		protocol.sendMultiBulkCommand("RANDOMKEY", []);
		return protocol.receiveBulk();
	}
	
	/**
	 * Atomically renames the key oldKey to newKey. If the source and destination name are the
	 * same an exception is thrown. If newkey already exists it is overwritten.
	 * @param	oldKey existing key
	 * @param	newKey new key name
	 * @return	true
	 */
	public function rename(oldKey :String, newKey :String) :Bool
	{
		if (oldKey == newKey)
			throw new RedisError("-ERR Key names must not match");
		
		protocol.sendMultiBulkCommand("RENAME", [oldKey, newKey]);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Rename oldkey into newKey but fails if the destination key newKey already exists.
	 * @param	oldkey existing key
	 * @param	newKey new key name
	 * @return	true for success
	 */
	public function renameSafely(oldKey :String, newKey :String) :Bool
	{
		if (oldKey == newKey)
			throw new RedisError("-ERR Key names must not match");
		
		protocol.sendMultiBulkCommand("RENAMENX", [oldKey, newKey]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return the total number of keys in the currently selected database.
	 * @return number of keys in db
	 */
	public function dbSize() :Int
	{
		protocol.sendMultiBulkCommand("DBSIZE", []);
		return protocol.receiveInt();
	}
	
	/**
	 * Set a timeout on the specified key. After the timeout the key will be automatically
	 * delete by the server. A key with an associated timeout is said to be volatile in Redis
	 * terminology.
	 * @param	key the key to modify
	 * @return	true on success
	 */
	public function expire(key :String, seconds :Int) :Bool
	{
		protocol.sendMultiBulkCommand("EXPIRE", [key, Std.string(seconds)]);
		return protocol.receiveInt() == 1;
	}
	
	/**
	 * Works exctly like 'expire' but instead to get the number of seconds representing the Time
	 * To Live of the key as a second argument (that is a relative way of specifing the TTL), it
	 * takes an absolute one in the form of a UNIX timestamp (Number of seconds elapsed since 1
	 * Gen 1970).
	 * @param	key the key to modify
	 * @return	true on success
	 */
	public function expireAt(key :String, unixTime :Int) :Bool
	{
		protocol.sendMultiBulkCommand("EXPIREAT", [key, Std.string(unixTime)]);
		return protocol.receiveInt() == 1;
	}
	
	/**
	 * The TTL command returns the remaining time to live in seconds of a key that has an EXPIRE
	 * set.
	 * @param	key the key to modify
	 * @return	true on success
	 */
	public function ttl(key :String) :Int
	{
		protocol.sendMultiBulkCommand("TTL", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Select the DB with having the specified zero-based numeric index. For default every new
	 * client connection is automatically selected to DB 0.
	 * @param	index db num to select
	 * @return	true on success
	 */
	public function select(index :Int) :Bool
	{
		protocol.sendMultiBulkCommand("SELECT", [Std.string(index)]);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Move the specified key from the currently selected DB to the specified destination DB.
	 * @param	key the key to move
	 * @param	dbIndex the db to move "key" to
	 * @return	true on success
	 */
	public function move(key :String, dbIndex :Int) :Bool
	{
		protocol.sendMultiBulkCommand("MOVE", [key, Std.string(dbIndex)]);
		return protocol.receiveInt() == 1;
	}
	
	/**
	 * Delete all the keys of the currently selected DB. This command never fails.
	 * @return	true
	 */
	public function flushDB() :Bool
	{
		protocol.sendMultiBulkCommand("FLUSHDB", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Delete all the keys of all the existing databases, not just the currently selected
	 * one. This command never fails.
	 * @return	true
	 */
	public function flushAll() :Bool
	{
		protocol.sendMultiBulkCommand("FLUSHALL", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Set the "key" to "value". "value" can't be longer than 1073741824 bytes (1 GB).
	 * @param	key the key to modify
	 * @param	value the new value
	 * @return	true on success
	 */
	public function set(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("SET", [key, value]);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Get the value of "key". If the key does not exist null is returned. If "key" does not
	 * exist an exception is thrown.
	 * @param	key the key to access
	 * @return	the value at "key"
	 */
	public function get(key :String) :String
	{
		protocol.sendMultiBulkCommand("GET", [key]);
		return protocol.receiveBulk();
	}
	
	/**
	 * GETSET is an atomic command to set "key" to "value" and return the old value.  "value"
	 * can't be longer than 1073741824 bytes (1 GB).
	 * @param	key the key to modify
	 * @param	value the new value
	 * @return	the old value at "key"
	 */
	public function getSet(key :String, value :String) :String
	{
		protocol.sendMultiBulkCommand("GETSET", [key, value]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Get the values of all the specified keys. If one or more keys dont exist or is not of
	 * type String, null is returned instead of the value of the specified key, but the
	 * operation never fails.
	 * @param	keys array of keys to retrieve
	 * @return	array of values
	 */
	public function multiGet(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("MGET", keys);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * works exactly like "set" with the only difference that if the key already exists no
	 * operation is performed.
	 * @param	key key to modify
	 * @param	value new value
	 * @return	true on success
	 */
	public function setSafely(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("SETNX", [key, value]);
		return protocol.receiveInt() > 0;
	}
	

	/**
	 * The same as "set" and "expire" atomically.
	 * @param	key key to modify
	 * @param	value new value
	 * @param	seconds the number of seconds before the key expires
	 * @return	true on success
	 */
	public function setExpire(key :String, value :String, seconds :Int)
	{
		protocol.sendMultiBulkCommand("SETEX", [key, Std.string(seconds), value]);
		return protocol.receiveSingleLine() == OK;
	}

	/**
	 * Set the the respective keys to the respective values. MSET will replace oldvalues with
	 * new values.
	 * @param	keys array of keys to set
	 * @return	true on success
	 */
	public function multiSet(keys :Hash<String>) :Bool
	{
		var params = new Array<String>();
		for( kk in keys.keys() )
		{
			params.push(kk);
			params.push(keys.get(kk));
		}
		protocol.sendMultiBulkCommand("MSET", params);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Set the the respective keys to the respective values, without overwriting existing
	 * values.  It will not perform any operation at alleven if just a single key already
	 * exists.
	 * @param	keys array of keys to set
	 * @return	true on success
	 */
	public function multiSetSafely(keys :Hash<String>) :Bool
	{
		var params = new Array<String>();
		for( kk in keys.keys() )
		{
			params.push(kk);
			params.push(keys.get(kk));
		}
		protocol.sendMultiBulkCommand("MSETNX", params);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Increment the number stored at key by one. If the key does not exist or contains a value
	 * of a wrong type, set the key to the value of "0" before the increment or decrement
	 * operation is performed. limited to 64 bit signed integers.
	 * @param	key key to modify
	 * @return	new value of "key"
	 */
	public function increment(key :String) :Int
	{
		protocol.sendMultiBulkCommand("INCR", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Increment the number stored at key by "value". If the key doesnot exist or contains a
	 * value of a wrong type, set the key to thevalue of "0" before to perform the increment or
	 * decrement operation.  limited to 64 bit signed integers.
	 * @param	key key to modify
	 * @param	value amount to increment by
	 * @return	new value of "key"
	 */
	public function incrementBy(key :String, value :Int) :Int
	{
		protocol.sendMultiBulkCommand("INCRBY", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	/**
	 * Decrement the number stored at key by one. If the key does not exist or contains a value
	 * of a wrong type, set the key to the value of "0" before the increment or decrement
	 * operation is performed. limited to 64 bit signed integers.
	 * @param	key key to modify
	 * @return	new value of "key"
	 */
	public function decrement(key :String) :Int
	{
		protocol.sendMultiBulkCommand("DECR", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Decrement the number stored at key by "value". If the key doesnot exist or contains a
	 * value of a wrong type, set the key to thevalue of "0" before to perform the increment or
	 * decrement operation.  limited to 64 bit signed integers.
	 * @param	key key to modify
	 * @param	value amount to increment by
	 * @return	new value of "key"
	 */
	public function decrementBy(key :String, value :Int) :Int
	{
		protocol.sendMultiBulkCommand("DECRBY", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	/**
	 * If the key already exists and is a string, this command appends the provided value at the
	 * end of the string. If the key does not exist it is created and set as an empty string, so
	 * "append" will be very similar to "set" in this special case.
	 * @param	key the key to modify
	 * @param	value the string to append
	 * @return	true on success
	 */
	public function append(key :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("APPEND", [key, value]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return a subset of the string from offset start to offset end (both offsets are
	 * inclusive). Negative offsets can be used in order to provide an offset starting from the
	 * end of the string. So -1 means the last char, -2 the previous and so forth.  The
	 * function handles out of range requests the same as a -1.
	 * @param	key the key to modify
	 * @param	start the first character
	 * @param	last the last character
	 * @return	the requested substring
	 */
	public function substr(key :String, start :Int, end :Int) :String
	{
		protocol.sendMultiBulkCommand("SUBSTR", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Add the string value to the head of the list stored at key. If the key does not exist an
	 * empty list is created just before the append operation. If the key exists but is not a
	 * List an exception is thrown.
	 * @param	key the key containing the list
	 * @param	value the value to add to the list
	 * @return	the new length of the list at "key"
	 */
	public function listsRightPush(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("RPUSH", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	/**
	 * Add the string value to the tail of the liststored at key. If the key does not exist an
	 * empty list is created just beforethe append operation. If the key exists but is not a
	 * List an exception is returned.
	 * @param	key the key containing the list
	 * @param	value the value to add to the list
	 * @return	the new length of the list at "key"
	 */
	public function listsLeftPush(key :String, value :String) :Int
	{
		protocol.sendMultiBulkCommand("LPUSH", [key, Std.string(value)]);
		return protocol.receiveInt();
	}
	
	/**
	 * Return the length of the list stored at the specified key. If thekey does not exist zero
	 * is returned (the same behaviour as forempty lists). If the value stored at key is not a
	 * list an exception is thrown.
	 * @param	key the key containing the list
	 * @return	the length of the list
	 */
	public function listsLength(key :String) :Int
	{
		protocol.sendMultiBulkCommand("LLEN", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Return the specified elements of the list stored at "key". "Start" and "end" are
	 * zero-based indexes. 0 is the first elementof the list (the list head), 1 the next element
	 * and so on.  "start" and "end" can also be negative numbers indicating offsetsfrom the end
	 * of the list. For example -1 is the last element ofthe list, -2 the previous element and
	 * so on.  Indexes out of range will not produce an error: if "start" is past the end of the
	 * list, or "start" > "end", an empty list is returned.  If "end" is over the end of the
	 * list Redis will threat it just like the last element of the list.
	 * @param	key the key containing the list
	 * @param	start the index of the first element to return
	 * @param	end the index of the last element to return
	 * @return	the specified elements from the list
	 */
	public function listsRange(key :String, start :Int, end :Int) :Array<String>
	{
		protocol.sendMultiBulkCommand("LRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * Trim an existing list so that it will contain only the specified range of elements.
	 * "Start" and "end" are zero-based indexes. 0 is the first elementof the list (the list
	 * head), 1 the next element and so on.  "start" and "end" can also be negative numbers
	 * indicating offsetsfrom the end of the list. For example -1 is the last element ofthe
	 * list, -2 the previous element and so on.  Indexes out of range will not produce an error:
	 * if "start" is past the end of the list, or "start" > "end", an empty list is returned.
	 * If "end" is over the end of the list Redis will threat it just like the last element of
	 * the list.
	 * @param	key the key containing the list
	 * @param	start the index of the first element
	 * @param	end the index of the last element
	 * @return	true on success
	 */
	public function listsTrim(key :String, start :Int, end :Int) :Bool
	{
		protocol.sendMultiBulkCommand("LTRIM", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Return the specified element of the list stored at the specifiedkey. 0 is the first
	 * element, 1 the second and so on. Negative indexes are supported, for example -1 is the
	 * last element, -2 the previous and so on.  If the value stored at key is not of list type
	 * an exception is thrown.  If the index is out of range null is returned.
	 * @param	key the key containing the list
	 * @param	index the index to get
	 * @return	the element at "index" of "key"
	 */
	public function listsIndex(key :String, index :Int) :String
	{
		protocol.sendMultiBulkCommand("LINDEX", [key, Std.string(index)]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Set the list element at "index" to "value". An exception is thrown if the index is out of
	 * range. Note that setting the first or last elements of the list is O(1).
	 * @param	key the key containing the list
	 * @param	index the index to modify
	 * @param	value the new value
	 * @return	true on success
	 */
	public function listsSet(key :String, index :Int, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("LSET", [key, Std.string(index), value]);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Remove the first "count" occurrences of "value" from the list. If count is zero all
	 * matching elements are removed. If count is negative elements are removed from tail to
	 * head. For example, count="-2", value="hello", list=(a,b,c,hello,x,hello,hello) will
	 * result in the list (a,b,c,hello,x). The number of removed elements is returned.  Note
	 * that non-existing keys are considered like empty lists by LREM, so LREM against non
	 * existing keys will always return 0.
	 * @param	key the key containing the list
	 * @param	count max number of elements to remove
	 * @param	value the value to remove from the list
	 * @return	number of elements removed
	 */
	public function listsRemove(key :String, count :Int, value :String) :Int
	{
		protocol.sendMultiBulkCommand("LREM", [key, Std.string(count), value]);
		return protocol.receiveInt();
	}
	
	/**
	 * Atomically return and remove the first element of the list. For example, if the list
	 * contains the elements "a","b","c" this will return "a" and the list will become "b","c".
	 * If the key does not exist or the list is already empty null is returned.
	 * @param	key the key containing the list
	 * @return	the first element of the list
	 */
	public function listsLeftPop(key :String) :String
	{
		protocol.sendMultiBulkCommand("LPOP", [key]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Atomically return and remove the last element of the list. For example if the list
	 * contains the elements "a","b","c" this will return "c" and the list will become "a","b".
	 * If the key does not exist or the list is already empty null is returned.
	 * @param	key the key containing the list
	 * @return	the last element of the list
	 */
	public function listsRightPop(key :String) :String
	{
		protocol.sendMultiBulkCommand("RPOP", [key]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Blocking version of "listsLeftPop".  waits "seconds" if key doesn't exist.  returns null
	 * after timeout.
	 * @param	key the key containing the list
	 * @param	seconds timeout duration. zero=forever.
	 * @return	the last element of the list
	 */
	public function listsBlockingLeftPop(key :String, seconds :Int) :String
	{
		protocol.sendMultiBulkCommand("BLPOP", [key, Std.string(seconds)]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Blocking version of "listsRightPop".  waits "seconds" if key doesn't exist.  returns null
	 * after timeout.
	 * @param	key the key containing the list
	 * @param	seconds timeout duration. zero=forever.
	 * @return	the last element of the list
	 */
	public function listsBlockingRightPop(key :String, seconds :Int) :String
	{
		protocol.sendMultiBulkCommand("BRPOP", [key, Std.string(seconds)]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Atomically return and remove the last (tail) element of the srcKey list, and push the
	 * element as the first (head) element of the dstKey list. For example, if the source list
	 * contains the elements "a","b","c" and the destination list contains the elements
	 * "y","z" after an RPOPLPUSH command the content of the two lists will be "a","b" and
	 * "c","y","z", respectively.
	 * @param	srcKey key of list to remove from
	 * @param	dstKey key to list to push to
	 * @return	the element that was moved
	 */
	public function listsRightPopLeftPush(srcList :String, dstList :String) :String
	{
		protocol.sendMultiBulkCommand("RPOPLPUSH", [srcList, dstList]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Add "member" to the set at "key". If "key" already contains "member", no operation is
	 * performed. If key does not exist a new set containing "member" is created. If the key
	 * exists but does not hold a set value an exception is thrown.
	 * @param	key the key containing the set
	 * @param	member the new value
	 * @return	true on success
	 */
	public function setsAdd(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SADD", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Remove "member" from the set at "key". If "key" didn't contain "member" no operation is
	 * performed. If key does not hold a set value an exception is thrown.
	 * @param	key the key containing the set
	 * @param	member to remove
	 * @return	true on success
	 */
	public function setsRemove(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SREM", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return and remove a random element from a set. If the Set is empty or the key does not
	 * exist, null is returned.
	 * @param	key the key containing the set
	 * @return	a random element from "key"
	 */
	public function setsPop(key :String) :String
	{
		protocol.sendMultiBulkCommand("SPOP", [key]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Atomically move "member" from the set at "srcKey" to the set at "dstKey".
	 * @param	srcKey key of set to remove "member"
	 * @param	distKey key of set to add "member"
	 * @param	member member to move
	 * @return	true on success
	 */
	public function setsMove(srcKey :String, dstKey :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SMOVE", [srcKey, dstKey, member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return the set cardinality (number of elements). If the key does not exist 0 is returned,
	 * like for empty sets.
	 * @param	key the key containing the set
	 * @return	number of elements in set
	 */
	public function setsCount(key :String) :Int
	{
		protocol.sendMultiBulkCommand("SCARD", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Check for a member in a set.
	 * @param	key the key containing the set
	 * @param	member member to look for
	 * @return	true if set "key" has "member"
	 */
	public function setsHasMember(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("SISMEMBER", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return the members of a set resulting from the intersection of all the sets at the
	 * specified keys. If just a single key is specified, then this command produces the same
	 * result as setsMembers.
	 * @param	keys array of keys to sets
	 * @return	elements that are members of all specified sets
	 */
	public function setsIntersect(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SINTER", keys);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * This command works exactly like setsIntersect but instead of being returned the resulting set is
	 * stored in dstKey.
	 * @param	distKey key to store result
	 * @param	keys array of keys to sets
	 * @return	elements that are members of all specified sets
	 */
	public function setsIntersectStore(dstKey :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(dstKey);
		protocol.sendMultiBulkCommand("SINTERSTORE", params);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return the members of a set resulting from the union of all specified sets.  If just a
	 * single key is specified, then this commandproduces the same result as setsMembers.  Non
	 * existing keys are considered like empty sets.
	 * @param	keys array of keys to sets
	 * @return	elements that are members of any of the specified sets
	 */
	public function setsUnion(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SUNION", keys);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * This command works exactly like setsUnion but instead of being returned the resulting set
	 * is stored as dstKey. Any existing value in dstKey will be overwritten.
	 * @param	distKey key to store result
	 * @param	keys array of keys to sets
	 * @return	true on success
	 */
	public function setsUnionStore(dstKey :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(dstKey);
		protocol.sendMultiBulkCommand("SUNIONSTORE", params);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return the members of a set resulting from the difference between the first set provided
	 * and all the successive sets.
	 * @param	keys array of keys to sets
	 * @return	elements that are only in the first set
	 */
	public function setsDifference(keys :Array<String>) :Array<String>
	{
		protocol.sendMultiBulkCommand("SDIFF", keys);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * This command works exactly like setsDifference but instead of being returned the
	 * resulting set is stored in dstkey.
	 * @param	distKey key to store result
	 * @param	keys array of keys to sets
	 * @return	true on success
	 */
	public function setsDifferenceStore(dstKey :String, keys :Array<String>) :Bool
	{
		var params = keys.copy();
		params.unshift(dstKey);
		protocol.sendMultiBulkCommand("SDIFFSTORE", params);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Return all the elements of the set value stored at key.
	 * @param	key the key containing the set
	 * @return	all members of the set
	 */
	public function setsMembers(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("SMEMBERS", [key]);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * Return a random element from a set, without removing the element. If the set is empty or
	 * the key does not exist, null is returned.
	 * @param	key the key containing the set
	 * @return	a random element from the set
	 */
	public function setsRandomMember(key :String) :String 
	{
		protocol.sendMultiBulkCommand("SRANDMEMBER", [key]);
		return protocol.receiveBulk();
	}
	
	/**
	 * Add the specified member with the specifeid score to the sortedset at "key". If the set
	 * already contains "member" the score is updated. If "key" does not exist a new sortedset
	 * with the specified "member" as sole member is created. If "key" exists but does not
	 * hold asorted set value an exception is thrown.
	 * @param	key the key containing the set
	 * @param	score the score of the new member
	 * @param	member the new member
	 * @return	true if new element is added
	 */
	public function sortedSetsAdd(key :String, score :Float, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("ZADD", [key, Std.string(score), member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Remove the specified member from the sorted set value at "key". If "member" was not a
	 * member of the set no operation is performed. If key does not not hold a set value an
	 * exception is thrown.
	 * @param	key the key containing the set
	 * @param	member the member to remove
	 * @return	true if the new element was removed
	 */
	public function sortedSetsRemove(key :String, member :String) :Bool
	{
		protocol.sendMultiBulkCommand("ZREM", [key, member]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * If member already exists in the sortedset, adds "increment" to its score and updates the
	 * position of the element in the sorted set accordingly. If "member" does not already exist
	 * in the sorted set it is added with "increment" as score (that is, like if the previous
	 * score was zero). If key does not exist a new sorted set with the specified "member" as
	 * sole member is created. If the key exists but does not hold asorted set value an
	 * exception is thrown.
	 * @param	key the key containing the set
	 * @param	increment the amount to increment the score
	 * @param	member the member to modify
	 * @return	the new score
	 */
	public function sortedSetsIncrementBy(key :String, increment :Float, member :String) :Float
	{
		protocol.sendMultiBulkCommand("ZINCRBY", [key, Std.string(increment), member]);
		return Std.parseFloat(protocol.receiveBulk());
	}
	
	/**
	 * returns the rank of the member in the sorted set, with scores ordered from low to high.
	 * When the given member does not exist in the sorted set, the special value 'nil' is
	 * returned. The returned rank (or index) of the member is 0-based for both commands.
	 * @param	key the key to access
	 * @param	member the set member to check
	 * @return	the rank of the specified member
	 */
	public function sortedSetsRank(key :String, member :String) :Int
	{
		protocol.sendMultiBulkCommand("ZRANK", [key, member]);
		return protocol.receiveInt();
	}

	/**
	 * returns the rank of the member in the sorted set counting from the back, with scores
	 * ordered from low to high.  When the given member does not exist in the sorted set, the
	 * special value 'nil' is returned. The returned rank (or index) of the member is 0-based
	 * for both commands.
	 * @param	key the key to access
	 * @param	member the set member to check
	 * @return	the rank of the specified member
	 */
	public function sortedSetsReverseRank(key :String, member :String) :Int
	{
		protocol.sendMultiBulkCommand("ZREVRANK", [key, member]);
		return protocol.receiveInt();
	}

	/**
	 * Return the specified elements of the sorted set at the specified key. The elements are
	 * considered sorted from the lowest to the highest.  Start and end are zero-based
	 * indexes. 0 is the first elementof the sorted set, the next element by score and so on.
	 * "start" and "end" can also be negative numbers indicating offsets from the end of the
	 * sorted set. For example -1 is the last element ofthe sorted set, -2 the previous element
	 * and so on.  Indexes out of range will not produce an error : if "start" is past the end of
	 * the sorted set, or "start" > "end", an empty list is returned. If "end" is over the end
	 * of the sorted set Redis will treat it just like the last element of the sorted set.  It's
	 * possible to pass the WITHSCORES option to the command in order to return not only the
	 * values but also the scores of the elements.
	 * @param	key the key containing the set
	 * @param	start the start index
	 * @param	end the end index
	 * @param	withScores if true, include scores in return value
	 * @return	elements from set in specified range
	 */
	public function sortedSetsRange(key :String, start :Int, end :Int, ?withScores :Bool = false) :Array<String>
	{
        if( withScores )
            protocol.sendMultiBulkCommand("ZRANGE", [key, Std.string(start), Std.string(end), "WITHSCORES"]);
        else
            protocol.sendMultiBulkCommand("ZRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}

	/**
	 * Return the specified elements of the sorted set at the specified key. The elements are
	 * considered sorted from the highest to the lowest.  Start and end are zero-based
	 * indexes. 0 is the first elementof the sorted set, the next element by score and so on.
	 * "start" and "end" can also be negative numbers indicating offsets from the end of the
	 * sorted set. For example -1 is the last element ofthe sorted set, -2 the previous element
	 * and so on.  Indexes out of range will not produce an error: if "start" is past the end of
	 * the sorted set, or "start" > "end", an empty list is returned. If "end" is over the end
	 * of the sorted set Redis will treat it just like the last element of the sorted set.  It's
	 * possible to pass the WITHSCORES option to the command in order to return not only the
	 * values but also the scores of the elements.
	 * @param	key the key containing the set
	 * @param	start the start index
	 * @param	end the end index
	 * @param	withScores if true, include scores in return value
	 * @return	elements from set in specified range
	 */
	public function sortedSetsReverseRange(key :String, start :Int, end :Int, ?withScores :Bool = false) :Array<String>
	{
        if( withScores )
            protocol.sendMultiBulkCommand("ZREVRANGE", [key, Std.string(start), Std.string(end), "WITHSCORES"]);
        else
            protocol.sendMultiBulkCommand("ZREVRANGE", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * Return the all the elements in the sorted set at "key" with a score between "min" and
	 * "max", inclusively.  The elements having the same score are returned sorted
	 * lexicographically as ASCII strings (this follows from a property of Redis sorted sets and
	 * does notinvolve further computation).  Using the optional "limit" it's possible to get only
	 * a range of the matching elements in an SQL-like way.
	 * @param	key the key containing the set
	 * @param	min min score
	 * @param	max max score
	 * @param	?offset offset from the start of the set
	 * @param	?count max number of elements to return
	 * @return	elements from set in specified score range
	 */
	public function sortedSetsRangeByScore(key :String, minScore :Float, maxScore :Float, ?offset :Int = 0, ?count :Int = 0) :Array<String>
	{
        if( count > 0 )
            protocol.sendMultiBulkCommand("ZRANGEBYSCORE", [key, Std.string(minScore), Std.string(maxScore), "LIMIT", Std.string(offset), Std.string(count)]);
        else
            protocol.sendMultiBulkCommand("ZRANGEBYSCORE", [key, Std.string(minScore), Std.string(maxScore)]);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * Return the sorted set cardinality (number of elements). If the key does not exist 0 is
	 * returned, like for empty sorted sets.
	 * @param	key the key containing the set
	 * @return	the number of elements in the set
	 */
	public function sortedSetsCount(key :String) :Int
	{
		protocol.sendMultiBulkCommand("ZCARD", [key]);
		return protocol.receiveInt();
	}
	
	/**
	 * Return the score of the specified element of the sorted set at "key". If the specified
	 * element does not exist in the sorted set, or the key does not exist at all, null is returned.
	 * @param	key the key containing the set
	 * @param	member the member of the set
	 * @return	the member's score
	 */
	public function sortedSetsScore(key :String, member :String) :Float
	{
		protocol.sendMultiBulkCommand("ZSCORE", [key, member]);
		return Std.parseFloat(protocol.receiveBulk());
	}

	/**
	 * Remove all elements in the sorted set at key with rank between "start" and "end". "start"
	 * and "end" are 0-based with rank 0 being the element with the lowest score. Both start and
	 * end can be negative numbers, where they indicate offsets starting at the element with the
	 * highest rank. For example: -1 is the element with the highest score, -2 the element with
	 * the second highest score and so forth.
	 * @param	key the key containing the set
	 * @param	start first element to remove
	 * @param	end last element to remove
	 * @return	number of elements removed
	 */
	public function sortedSetsRemoveRangeByRank(key :String, start :Int, end :Int) :Int
	{
		protocol.sendMultiBulkCommand("ZREMRANGEBYRANK", [key, Std.string(start), Std.string(end)]);
		return protocol.receiveInt();
	}
	
	/**
	 * Remove all the elements in the sorted set at key with a score between "min" and "max",
	 * inclusive.
	 * @param	key the key containing the set
	 * @param	min the min score
	 * @param	max the max score
	 * @return	the number of elements removed
	 */
	public function sortedSetsRemoveRangeByScore(key :String, minScore :Float, maxScore :Float) :Int
	{
		protocol.sendMultiBulkCommand("ZREMRANGEBYSCORE", [key, Std.string(minScore), Std.string(maxScore)]);
		return protocol.receiveInt();
	}
	
	/**
	 * Creates a union of N sorted sets given by keys k1 through kN, and stores it at dstkey.
	 * @param	dstKey the key where the result should be stored
	 * @param	keys array of sorted sets to combine
	 * @param	weights array of weights to apply to each input set
	 * @return	the number of elements in the result set
	 */
	public function sortedSetsUnionStore(dstKey :String, keys :Array<String>, ?weights :Array<Float>, ?aggregate :String) :Int
	{
		var params = keys.copy();
		params.unshift(Std.string(keys.length));
		params.unshift(dstKey);
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

	/**
	 * Creates an intersection of N sorted sets given by keys k1 through kN, and stores it at
	 * dstkey.
	 * @param	dstKey the key where the result should be stored
	 * @param	keys array of sorted sets to combine
	 * @param	weights array of weights to apply to each input set
	 * @return	the number of elements in the result set
	 */
	public function sortedSetsIntersectStore(dstKey :String, keys :Array<String>, ?weights :Array<Float>, ?aggregate :String) :Int
	{
		var params = keys.copy();
		params.unshift(Std.string(keys.length));
		params.unshift(dstKey);
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

	/**
	 * Set the string value of "field" of the hash at "key".
	 * @param	key the key containing the hash
	 * @param	field the field to modify
	 * @param	value the new value
	 * @return	true on success
	 */
	public function hashSet(key :String, field :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("HSET", [key, field, value]);
		return protocol.receiveInt() > 0;
	}
	
	/**
	 * Set the string value of "field" of the hash at "key" if it's not already set.
	 * @param	key the key containing the hash
	 * @param	field the field to modify
	 * @param	value the new value
	 * @return	true on success
	 */
	public function hashSetSafely(key :String, field :String, value :String) :Bool
	{
		protocol.sendMultiBulkCommand("HSETNX", [key, field, value]);
		return protocol.receiveInt() > 0;
	}

	/**
	 * Get the string value of "field" of the hash at "key".
	 * @param	key the key containing the hash
	 * @param	field the field to access
	 * @return	value the value of "field" at "key"
	 */
	public function hashGet(key :String, field :String) :String
	{
		protocol.sendMultiBulkCommand("HGET", [key, field]);
		return protocol.receiveBulk();
	}

	/**
	 * Set values of the "fields" of the hash at "key".
	 * @param	key the key containing the hash
	 * @param	fields hash of field names and values to set
	 * @return	true on success
	 */
	public function hashMultiSet(key :String, fields :Hash<String>) :Bool
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

	/**
	 * Get values of "fields" of the hash at "key".
	 * @param	key the key containing the hash
	 * @param	fields array of field names to access
	 * @return	array of values of "fields" at "key"
	 */
	public function hashMultiGet(key :String, fields :Array<String>) :Array<String>
	{
		var params = fields.copy();
		params.unshift(key);
		protocol.sendMultiBulkCommand("HMGET", params);
		return protocol.receiveMultiBulk();
	}

	/**
	 * Increment the value at "field" of the hash at "key".
	 * @param	key the key containing the hash
	 * @param	field the field to modify
	 * @param	increment the amount to increment
	 * @return	new value
	 */
	public function hashIncrementBy(key :String, field :String, increment :Int) :Int
	{
		protocol.sendMultiBulkCommand("HINCRBY", [key, field, Std.string(increment)]);
		return protocol.receiveInt();
	}

	/**
	 * Returns true if the hash "key" contains "field".
	 * @param	key the key containing the hash
	 * @param	field the field to check
	 * @return	true on success
	 */
	public function hashExists(key :String, field :String) :Bool
	{
		protocol.sendMultiBulkCommand("HEXISTS", [key, field]);
		return protocol.receiveInt() > 0;
	}

	/**
	 * Delete "field" from the hash at "key".
	 * @param	key the key containing the hash
	 * @param	field the field to delete
	 * @return	true on success
	 */
	public function hashDelete(key :String, field :String) :Bool
	{
		protocol.sendMultiBulkCommand("HDEL", [key, field]);
		return protocol.receiveInt() > 0;
	}

	/**
	 * Returns the length of the hash at "key".
	 * @param	key the key containing the hash
	 * @return	number of fields at "key"
	 */
	public function hashLength(key :String) :Int
	{
		protocol.sendMultiBulkCommand("HLEN", [key]);
		return protocol.receiveInt();
	}

	/**
	 * Returns an array of keys of the hash at "key".
	 * @param	key the key containing the hash
	 * @return	array of keys in hash at "key"
	 */
	public function hashKeys(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("HKEYS", [key]);
		return protocol.receiveMultiBulk();
	}

	/**
	 * Returns an array of values of the hash at "key".
	 * @param	key the key containing the hash
	 * @return	array of value in hash at "key"
	 */
	public function hashValues(key :String) :Array<String>
	{
		protocol.sendMultiBulkCommand("HVALS", [key]);
		return protocol.receiveMultiBulk();
	}

	/**
	 * Returns the hash at "key".
	 * @param	key the key containing the hash
	 * @return	hash of keys and values of hash at "key"
	 */
	public function hashGetAll(key :String) :Hash<String>
	{
		protocol.sendMultiBulkCommand("HGETALL", [key]);
		var all = protocol.receiveMultiBulk();
		var ret = new Hash<String>();
		while( all.length > 0 )
		  ret.set(all.shift(), all.shift());
		return ret;
	}

	/**
	 * Sort the elements contained in the List, Set, orSorted Set value at key. By defaultsorting is numeric with elements being compared as double precisionfloating point numbers.
	 * @param	key
	 * @param	?byPattern
	 * @param	?start
	 * @param	?end
	 * @param	?getPattern
	 * @param	?isAscending
	 * @param	?isAlpha
	 * @param	?distKey
	 * @return
	 */
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
	
	/**
	 * Save the DB on disk. The server hangs while the saving is notcompleted, no connection is
	 * served in the meanwhile. An OK code is returned when the DB was fully stored in disk.
	 * @return	true on success
	 */
	public function save() :Bool
	{
		protocol.sendMultiBulkCommand("SAVE", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Save the DB in background. The OK code is immediately returned.Redis forks, the parent
	 * continues to server the clients, the childsaves the DB on disk then exit. A client my be
	 * able to check if theoperation succeeded using the LASTSAVE command.
	 * @return	true on success
	 */
	public function backgroundSave() :Bool
	{
		protocol.sendMultiBulkCommand("BGSAVE", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * Return the UNIX TIME of the last DB save executed with success.A client may check if a
	 * BGSAVE command succeeded reading the LASTSAVEvalue, then issuing a BGSAVE command and
	 * checking at regular intervalsevery N seconds if LASTSAVE changed.
	 * @return	time of last save
	 */
	public function lastSave() :Int
	{
		protocol.sendMultiBulkCommand("LASTSAVE", []);
		return protocol.receiveInt();
	}
	
	/**
	 * Stop all the clients, save the DB, then quit the server. This commandsmakes sure that the
	 * DB is switched off without the lost of any data.This is not guaranteed if the client uses
	 * simply "SAVE" and then"QUIT" because other clients may alter the DB data between the
	 * twocommands.
	 */
	public function shutdown() :Void
	{
		protocol.sendMultiBulkCommand("SHUTDOWN", []);
	}
	
	/**
	 * BGREWRITEAOF rewrites the Append Only File in background when it gets toobig. The Redis
	 * Append Only File is a Journal, so every operation modifyingthe dataset is logged in the
	 * Append Only File (and replayed at startup).This means that the Append Only File always
	 * grows. In order to rebuildits content the BGREWRITEAOF creates a new version of the
	 * append only filestarting directly form the dataset in memory in order to guarantee
	 * thegeneration of the minimal number of commands needed to rebuild the database.
	 * @return	true on success
	 */
	public function backgroundRewriteAppendOnlyFile() :Bool
	{
		protocol.sendMultiBulkCommand("BGREWRITEAOF", []);
		return protocol.receiveSingleLine() == OK;
	}
	
	/**
	 * The info command returns different information and statistics about the server in an
	 * format that's simple to parse by computers and easy to red by huamns.
	 * @return	array containing server info
	 */
	public function info() :Array<String>
	{
		protocol.sendMultiBulkCommand("INFO", []);
		return protocol.receiveMultiBulk();
	}
	
	/**
	 * The SLAVEOF command can change the replication settings of a slave on the fly.If a Redis server is arleady acting as slave, the command SLAVEOF NO ONEwill turn off the replicaiton turning the Redis server into a MASTER.In the proper form SLAVEOF hostname port will make the server a slave of thespecific server listening at the specified hostname and port.
	 * If a server is already a slave of some master, SLAVEOF hostname port willstop the replication against the old server and start the synchrnonizationagainst the new one discarding the old dataset.
	 * The form SLAVEOF no one will stop replication turning the server into aMASTER but will not discard the replication. So if the old master stop workingit is possible to turn the slave into a master and set the application touse the new master in read/write. Later when the other Redis server will befixed it can be configured in order to work as slave.
	 * @param	config
	 * @return	true on success
	 */
	public function slaveOf(config :SlaveConfig) :Bool
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
	
	/**
	 * Ask the server to silently close the connection.
	 */
	public function quit() :Void
	{
		protocol.sendMultiBulkCommand("QUIT", []);
	}
	
	/**
	 * Request for authentication in a password protected Redis server.A Redis server can be
	 * instructed to require a password before to allow clientsto issue commands. This is done
	 * using the requirepass directive in the Redis configuration file.  If the password given by
	 * the client is correct the server replies with an OK status code reply and starts accepting
	 * commands from the client. Otherwise an error is returned and the clients needs to try a
	 * new password. Note that for the high performance nature of Redis it is possible to try a
	 * lot of passwords in parallel in very short time, so make sure to generate a strong and
	 * very long password so that this attack is infeasible.
	 * @param	password password to use
	 * @return	true on success
	 */
	public function auth(password :String) :Bool
	{
		protocol.sendMultiBulkCommand("AUTH", [password]);
		return protocol.receiveSingleLine() == OK;
	}
}
