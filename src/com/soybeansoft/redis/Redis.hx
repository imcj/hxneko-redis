/**
 * ...
 * @author Guntur Sarwohadi
 */

package com.soybeansoft.redis;

import haxe.Int32;
import neko.net.Host;
import neko.net.Socket;

class Redis 
{
	private var socket:Socket;
	
	private static inline var EOL:String = "\r\n";
	private static inline var OK:String = "OK";
	
	private static inline var DATA:String = "data";
	
	public static inline var TYPE_NONE:String = "none";
	public static inline var TYPE_STRING:String = "string";
	public static inline var TYPE_LIST:String = "list";
	public static inline var TYPE_SET:String = "set";
	public static inline var TYPE_ZSET:String = "zset";
	public static inline var TYPE_HASH:String = "hash";
	
	public function new(?host:String = "localhost", ?port:Int = 6379, ?timeout:Float = 100) 
	{
		socket = new Socket();
		socket.setTimeout(timeout);
		socket.connect(new Host(host), port);
	}
	
	/*
	 * ===================================
	 * PUBLICS
	 * ===================================
	 */
	
	 /**
	  * Test if the specified key exists. The command returns true if the key exists, otherwise false is returned.
	  * @param	key
	  * @return
	  */
	public function exists(key:String):Bool
	{
		var value:Dynamic = writeData("EXISTS " + key + EOL);
		return (Reflect.field(value, DATA) == 1)? true : false;
	}
	
	/**
	 * Remove the specified keys. If a given key does not exist no operation is performed for this key. The commnad returns the number of keys removed.
	 * @param	key
	 * @return
	 */
	public function delete(key:String):Int
	{
		var value:Dynamic = writeData("DEL " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the type of the value stored at key in form of a string. The type can be one of "none", "string", "list", "set". "none" is returned if the key does not exist.
	 * @param	key
	 * @return
	 */
	public function type(key:String):String
	{
		var value:Dynamic = writeData("TYPE " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Returns all the keys matching the glob-style pattern as space separated strings. For example if you have in the database the keys "foo" and "foobar" the command "KEYS foo*" will return "foo foobar".
	 * Glob style patterns examples:
	 * - h?llo will match hello hallo hhllo
	 * - h*llo will match hllo heeeello
	 * - h[ae]llo will match hello and hallo, but not hillo
	 * Use \ to escape special chars if you want to match them verbatim.
	 * @param	pattern
	 * @return
	 */
	public function keys(pattern:String):Dynamic
	{
		var value:Dynamic = writeData("KEYS " + pattern + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return a randomly selected key from the currently selected DB.
	 * @return
	 */
	public function randomKey():String
	{
		var value:Dynamic = writeData("RANDOMKEY" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Atomically renames the key oldkey to newkey. If the source and destination name are the same an error is returned. If newkey already exists it is overwritten.
	 * @param	oldKey
	 * @param	newKey
	 * @return
	 */
	public function rename(oldKey:String, newKey:String):Bool
	{
		if (oldKey == newKey)
			return throw "Please re-enter keys: oldKey has to be different than newKey";
		
		var value:Dynamic = writeData("RENAME " + oldKey + " " + newKey + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Rename oldkey into newkey but fails if the destination key newkey already exists.
	 * @param	oldkey
	 * @param	newKey
	 * @return
	 */
	public function renameSafely(oldKey:String, newKey:String):Bool
	{
		if (oldKey == newKey)
			return throw "Please re-enter keys: oldKey has to be different than newKey";
		
		var value:Dynamic = writeData("RENAMENX " + oldKey + " " + newKey + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the number of keys in the currently selected database.
	 * @return
	 */
	public function dbSize():Int
	{
		var value:Dynamic = writeData("DBSIZE" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Set a timeout on the specified key. After the timeout the key will be automatically delete by the server. A key with an associated timeout is said to be volatile in Redis terminology.
	 * @param	key
	 * @return
	 */
	public function expire(key:String, seconds:Int):Bool
	{
		var value:Dynamic = writeData("EXPIRE " + key + " " + Std.string(seconds) + EOL);
		return (Reflect.field(value, DATA) == 1)? true : false;
	}
	
	/**
	 * Works exctly like 'expire' but instead to get the number of seconds representing the Time To Live of the key as a second argument (that is a relative way of specifing the TTL), it takes an absolute one in the form of a UNIX timestamp (Number of seconds elapsed since 1 Gen 1970).
	 * @param	key
	 * @return
	 */
	public function expireAt(key:String, unixTime:Int):Bool
	{
		var value:Dynamic = writeData("EXPIREAT " + key + " " + Std.string(unixTime) + EOL);
		return (Reflect.field(value, DATA) == 1)? true : false;
	}
	
	/**
	 * The TTL command returns the remaining time to live in seconds of a key that has an EXPIRE set.
	 * @param	key
	 * @return
	 */
	public function ttl(key:String):Int
	{
		var value:Dynamic = writeData("TTL " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Select the DB with having the specified zero-based numeric index. For default every new client connection is automatically selected to DB 0.
	 * @param	index
	 * @return
	 */
	public function select(index:Int):String
	{
		var value:Dynamic = writeData("SELECT " + Std.string(index) + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Move the specified key from the currently selected DB to the specified destination DB.
	 * @param	key
	 * @param	dbIndex
	 * @return
	 */
	public function move(key:String, dbIndex:Int):Bool
	{
		var value:Dynamic = writeData("MOVE " + key + " " + Std.string(dbIndex) + EOL);
		return (Reflect.field(value, DATA) == 1)? true : false;
	}
	
	/**
	 * Delete all the keys of the currently selected DB. This command never fails.
	 * @return
	 */
	public function flushDB():String
	{
		var value:Dynamic = writeData("FLUSHDB" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Delete all the keys of all the existing databases, not just the currently selected one. This command never fails.
	 * @return
	 */
	public function flushAll():String
	{
		var value:Dynamic = writeData("FLUSHALL" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Set the string value as value of the key. The string can't be longer than 1073741824 bytes (1 GB).
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function set(key:String, value:String):Bool
	{
		var value:Dynamic = writeData("SET " + key + " " + Std.string(value.length) + EOL + value + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Get the value of the specified key. If the key does not exist the special value 'nil' is returned. If the value stored at key is not a string an error is returned because GET can only handle string values.
	 * @param	key
	 * @return
	 */
	public function get(key:String):String
	{
		var value:Dynamic = writeData("GET " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * GETSET is an atomic set this value and return the old value command. Set key to the string value and return the old value stored at key. The string can't be longer than 1073741824 bytes (1 GB).
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function getSet(key:String, value:String):String
	{
		var value:Dynamic = writeData("GETSET " + key + " " + value + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Get the values of all the specified keys. If one or more keys dont exist or is not of type String, a 'nil' value is returned instead of the value of the specified key, but the operation never fails.
	 * @param	keys
	 * @return
	 */
	public function multiGet(keys:Array<String>):Array<Dynamic>
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("MGET" + buffer.toString() + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * SETNX works exactly like SET with the only difference that if the key already exists no operation is performed.
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function setSafely(key:String, value:String):Bool
	{
		var value:Dynamic = writeData("SETNX " + key + " " + Std.string(value.length) + EOL + value + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * Set the the respective keys to the respective values. MSET will replace oldvalues with new values.
	 * @param	keys
	 * @return
	 */
	public function multiSet(keys:Array<String>):Bool
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("MSET" + buffer.toString() + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Set the the respective keys to the respective values. MSETNX will not perform any operation at alleven if just a single key already exists.
	 * @param	keys
	 * @return
	 */
	public function multiSetSafely(keys:Array<String>):Bool
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("MSETNX" + buffer.toString() + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Increment or decrement the number stored at key by one. If the key doesnot exist or contains a value of a wrong type, set the key to thevalue of "0" before to perform the increment or decrement operation.
	 * INCRBY and DECRBY work just like INCR and DECR but instead toincrement/decrement by 1 the increment/decrement is integer.
	 * INCR commands are limited to 64 bit signed integers.
	 * @param	key
	 * @return
	 */
	public function increment(key:String):Int
	{
		var value:Dynamic = writeData("INCR " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Increment or decrement the number stored at key by one. If the key doesnot exist or contains a value of a wrong type, set the key to thevalue of "0" before to perform the increment or decrement operation.
	 * INCRBY and DECRBY work just like INCR and DECR but instead toincrement/decrement by 1 the increment/decrement is integer.
	 * INCR commands are limited to 64 bit signed integers.
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function incrementBy(key:String, value:Int):Int
	{
		var value:Dynamic = writeData("INCRBY " + key + " " + Std.string(value) + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Increment or decrement the number stored at key by one. If the key doesnot exist or contains a value of a wrong type, set the key to thevalue of "0" before to perform the increment or decrement operation.
	 * INCRBY and DECRBY work just like INCR and DECR but instead toincrement/decrement by 1 the increment/decrement is integer.
	 * INCR commands are limited to 64 bit signed integers.
	 * @param	key
	 * @return
	 */
	public function decrement(key:String):Int
	{
		var value:Dynamic = writeData("DECR " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Increment or decrement the number stored at key by one. If the key doesnot exist or contains a value of a wrong type, set the key to thevalue of "0" before to perform the increment or decrement operation.
	 * INCRBY and DECRBY work just like INCR and DECR but instead toincrement/decrement by 1 the increment/decrement is integer.
	 * INCR commands are limited to 64 bit signed integers.
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function decrementBy(key:String, value:Int):Int
	{
		var value:Dynamic = writeData("DECRBY " + key + " " + Std.string(value) + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Add the string value to the head of the liststored at key. If the key does not exist an empty list is created just beforethe append operation. If the key exists but is not a List an erroris returned.
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function listsRightPush(key:String, value:String):Bool
	{
		var value:Dynamic = writeData("RPUSH " + key + " " + Std.string(value.length) + EOL + value + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Add the string value to the tail of the liststored at key. If the key does not exist an empty list is created just beforethe append operation. If the key exists but is not a List an erroris returned.
	 * @param	key
	 * @param	value
	 * @return
	 */
	public function listsLeftPush(key:String, value:String):Bool
	{
		var value:Dynamic = writeData("LPUSH " + key + " " + Std.string(value.length) + EOL + value + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the length of the list stored at the specified key. If thekey does not exist zero is returned (the same behaviour as forempty lists). If the value stored at key is not a list an error is returned.
	 * @param	key
	 * @return
	 */
	public function listsLength(key:String):Int
	{
		var value:Dynamic = writeData("LLEN " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the specified elements of the list stored at the specifiedkey. Start and end are zero-based indexes. 0 is the first elementof the list (the list head), 1 the next element and so on.
	 * _start_ and end can also be negative numbers indicating offsetsfrom the end of the list. For example -1 is the last element ofthe list, -2 the penultimate element and so on.
	 * Indexes out of range will not produce an error: if start is overthe end of the list, or start > end, an empty list is returned.If end is over the end of the list Redis will threat it just likethe last element of the list.
	 * @param	key
	 * @param	start
	 * @param	end
	 * @return
	 */
	public function listsRange(key:String, start:Int, end:Int):Array<Dynamic>
	{
		var value:Dynamic = writeData("LRANGE " + key + " " + Std.string(start) + " " + Std.string(end) + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Trim an existing list so that it will contain only the specifiedrange of elements specified. Start and end are zero-based indexes.0 is the first element of the list (the list head), 1 the next elementand so on.
	 * _start_ and end can also be negative numbers indicating offsetsfrom the end of the list. For example -1 is the last element ofthe list, -2 the penultimate element and so on.
	 * Indexes out of range will not produce an error: if start is overthe end of the list, or start > end, an empty list is left as value.If end over the end of the list Redis will threat it just likethe last element of the list.
	 * @param	key
	 * @param	start
	 * @param	end
	 * @return
	 */
	public function listsTrim(key:String, start:Int, end:Int):Bool
	{
		var value:Dynamic = writeData("LTRIM " + key + " " + Std.string(start) + " " + Std.string(end) + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the specified element of the list stored at the specifiedkey. 0 is the first element, 1 the second and so on. Negative indexesare supported, for example -1 is the last element, -2 the penultimateand so on.
	 * If the value stored at key is not of list type an error is returned.If the index is out of range an empty string is returned.
	 * @param	key
	 * @param	index
	 * @return
	 */
	public function listsIndex(key:String, index:Int):String
	{
		var value:Dynamic = writeData("LINDEX " + key + " " + Std.string(index) + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Set the list element at index (see LINDEX for information about the_index_ argument) with the new value. Out of range indexes willgenerate an error. Note that setting the first or last elements ofthe list is O(1).
	 * @param	key
	 * @param	index
	 * @param	value
	 * @return
	 */
	public function listsSet(key:String, index:Int, value:String):Bool
	{
		var value:Dynamic = writeData("LSET " + key + " " + Std.string(index) + " " + Std.string(value.length) + EOL + value + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Remove the first count occurrences of the value element from the list.If count is zero all the elements are removed. If count is negativeelements are removed from tail to head, instead to go from head to tailthat is the normal behaviour. So for example LREM with count -2 and_hello_ as value to remove against the list (a,b,c,hello,x,hello,hello) willlave the list (a,b,c,hello,x). The number of removed elements is returnedas an integer, see below for more information about the returned value.Note that non existing keys are considered like empty lists by LREM, so LREMagainst non existing keys will always return 0.
	 * @param	key
	 * @param	count
	 * @param	value
	 * @return
	 */
	public function listsRemove(key:String, count:Int, value:String):Int
	{
		var value:Dynamic = writeData("LREM " + key + " " + Std.string(count) + " " + Std.string(value.length) + EOL + value + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Atomically return and remove the first (LPOP) elementof the list. For example if the list contains the elements "a","b","c" LPOPwill return "a" and the list will become "b","c".
	 * If the key does not exist or the list is already empty the specialvalue 'nil' is returned.
	 * @param	key
	 * @return
	 */
	public function listsLeftPop(key:String):String
	{
		var value:Dynamic = writeData("LPOP " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Atomically return and remove the last (RPOP) elementof the list. For example if the list contains the elements "a","b","c" LPOPwill return "a" and the list will become "b","c".
	 * If the key does not exist or the list is already empty the specialvalue 'nil' is returned.
	 * @param	key
	 * @return
	 */
	public function listsRightPop(key:String):String
	{
		var value:Dynamic = writeData("RPOP " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Atomically return and remove the last (tail) element of the srckey list,and push the element as the first (head) element of the dstkey list. Forexample if the source list contains the elements "a","b","c" and thedestination list contains the elements "foo","bar" after an RPOPLPUSH commandthe content of the two lists will be "a","b" and "c","foo","bar".
	 * @param	sourceList
	 * @param	distList
	 * @return
	 */
	public function listsRightPopLeftPush(srcList:String, distList:String):String
	{
		var value:Dynamic = writeData("RPOPLPUSH " + srcList + " " + distList + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Add the specified member to the set value stored at key. If memberis already a member of the set no operation is performed. If keydoes not exist a new set with the specified member as sole member iscreated. If the key exists but does not hold a set value an error isreturned.
	 * @param	key
	 * @param	member
	 * @return
	 */
	public function setsAdd(key:String, member:String):Bool
	{
		var value:Dynamic = writeData("SADD " + key + " " + Std.string(member.length) + EOL + member + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * Remove the specified member from the set value stored at key. If_member_ was not a member of the set no operation is performed. If keydoes not hold a set value an error is returned.
	 * @param	key
	 * @param	member
	 * @return
	 */
	public function setsRemove(key:String, member:String):Bool
	{
		var value:Dynamic = writeData("SREM " + key + " " + Std.string(member.length) + EOL + member + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * Remove a random element from a Set returning it as return value.If the Set is empty or the key does not exist, a nil object is returned.
	 * @param	key
	 * @return
	 */
	public function setsPop(key:String):String
	{
		var value:Dynamic = writeData("SPOP " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Move the specifided member from the set at srckey to the set at dstkey.This operation is atomic, in every given moment the element will appear tobe in the source or destination set for accessing clients.
	 * @param	srcKey
	 * @param	distKey
	 * @param	member
	 * @return
	 */
	public function setsMove(srcKey:String, distKey:String, member:String):Int
	{
		var value:Dynamic = writeData("SMOVE " + srcKey + " " + distKey + " " + Std.string(member.length) + EOL + member + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the set cardinality (number of elements). If the key does notexist 0 is returned, like for empty sets.
	 * @param	key
	 * @return
	 */
	public function setsCount(key:String):Int
	{
		var value:Dynamic = writeData("SCARD " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return 1 if member is a member of the set stored at key, otherwise0 is returned.
	 * @param	key
	 * @param	member
	 * @return
	 */
	public function setsHasMember(key:String, member:String):Bool
	{
		var value:Dynamic = writeData("SISMEMBER " + key + " " + Std.string(member.length) + EOL + member + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * Return the members of a set resulting from the intersection of all thesets hold at the specified keys. Like in LRANGE the result is sent tothe client as a multi-bulk reply (see the protocol specification formore information). If just a single key is specified, then this commandproduces the same result as SMEMBERS. Actually SMEMBERS is just syntaxsugar for SINTERSECT.
	 * @param	keys
	 * @return
	 */
	public function setsIntersect(keys:Array<String>):Array<Dynamic>
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SINTER " + buffer.toString() + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * This commnad works exactly like SINTER but instead of being returned the resulting set is sotred as dstkey.
	 * @param	distKey
	 * @param	keys
	 * @return
	 */
	public function setsIntersectStore(distKey:String, keys:Array<String>):Bool
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SINTERSTORE " + distKey + buffer.toString() + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the members of a set resulting from the union of all thesets hold at the specified keys. Like in LRANGE the result is sent tothe client as a multi-bulk reply (see the protocol specification formore information). If just a single key is specified, then this commandproduces the same result as SMEMBERS.
	 * Non existing keys are considered like empty sets.
	 * @param	keys
	 * @return
	 */
	public function setsUnion(keys:Array<String>):Array<Dynamic>
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SUNION " + buffer.toString() + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * This command works exactly like SUNION but instead of being returned the resulting set is stored as dstkey. Any existing value in dstkey will be over-written.
	 * @param	distKey
	 * @param	keys
	 * @return
	 */
	public function setsUnionStore(distKey:String, keys:Array<String>):Bool
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SUNIONSTORE " + distKey + buffer.toString() + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the members of a set resulting from the difference between the firstset provided and all the successive sets.
	 * @param	keys
	 * @return
	 */
	public function setsDifference(keys:Array<String>):Array<Dynamic>
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SDIFF " + buffer.toString() + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * This command works exactly like SDIFF but instead of being returned the resulting set is stored in dstkey.
	 * @param	distKey
	 * @param	keys
	 * @return
	 */
	public function setsDifferenceStore(distKey:String, keys:Array<String>):Bool
	{
		var buffer:StringBuf = new StringBuf();
		for (key in keys)
		{
			buffer.add(" " + key);
		}
		var value:Dynamic = writeData("SDIFFSTORE " + distKey + buffer.toString() + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return all the members (elements) of the set value stored at key. This is just syntax glue for SINTERSECT.
	 * @param	key
	 * @return
	 */
	public function setsMembers(key:String):Array<Dynamic>
	{
		var value:Dynamic = writeData("SMEMBERS " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return a random element from a Set, without removing the element. If the Set is empty or the key does not exist, a nil object is returned.
	 * @param	key
	 * @return
	 */
	public function setsRandomMember(key:String):String 
	{
		var value:Dynamic = writeData("SRANDMEMBER " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Add the specified member having the specifeid score to the sortedset stored at key. If member is already a member of the sorted setthe score is updated, and the element reinserted in the right position toensure sorting. If key does not exist a new sorted set with the specified_member_ as sole member is crated. If the key exists but does not hold asorted set value an error is returned.
	 * @param	key
	 * @param	score	
	 * @param	member
	 * @return	Bool	true if new element is added, false if the element was already a member of the sorted set and the score was updated
	 */
	public function sortedSetsAdd(key:String, score:Int, member:String):Bool
	{
		var value:Dynamic = writeData("ZADD " + key + " " + Std.string(score) + " " + Std.string(member.length) + EOL + member + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * Remove the specified member from the sorted set value stored at key. If_member_ was not a member of the set no operation is performed. If keydoes not not hold a set value an error is returned.
	 * @param	key
	 * @param	member
	 * @return	Bool	true if the new element was removed, false if the new element was not a member of the set
	 */
	public function sortedSetsRemove(key:String, member:String):Bool
	{
		var value:Dynamic = writeData("ZREM " + key + " " + Std.string(member.length) + EOL + member + EOL);
		return (Reflect.field(value, DATA) > 0)? true : false;
	}
	
	/**
	 * If member already exists in the sorted set adds the increment to its scoreand updates the position of the element in the sorted set accordingly.If member does not already exist in the sorted set it is added with_increment_ as score (that is, like if the previous score was virtually zero).If key does not exist a new sorted set with the specified_member_ as sole member is crated. If the key exists but does not hold asorted set value an error is returned.
	 * @param	key
	 * @param	increment
	 * @param	member
	 * @return
	 */
	public function sortedSetsIncrementBy(key:String, increment:Int, member:String):Int
	{
		var value:Dynamic = writeData("ZINCRBY " + key + " " + Std.string(increment) + " " + Std.string(member.length) + EOL + member + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the specified elements of the sorted set at the specifiedkey. The elements are considered sorted from the lowerest to the highestscore when using ZRANGE, and in the reverse order when using ZREVRANGE.Start and end are zero-based indexes. 0 is the first elementof the sorted set (the one with the lowerest score when using ZRANGE), 1the next element by score and so on.
	 * _start_ and end can also be negative numbers indicating offsetsfrom the end of the sorted set. For example -1 is the last element ofthe sorted set, -2 the penultimate element and so on.
	 * Indexes out of range will not produce an error: if start is overthe end of the sorted set, or start > end, an empty list is returned.If end is over the end of the sorted set Redis will threat it just likethe last element of the sorted set.
	 * It's possible to pass the WITHSCORES option to the command in order to return notonly the values but also the scores of the elements. Redis will return the dataas a single list composed of value1,score1,value2,score2,...,valueN,scoreN but clientlibraries are free to return a more appropriate data type (what we think is thatthe best return type for this command is a Array of two-elements Array / Tuple inorder to preserve sorting).
	 * @param	key
	 * @param	start
	 * @param	end
	 * @return
	 */
	public function sortedSetsRange(key:String, start:Int, end:Int, ?withScores:Bool = false):Array<Dynamic>
	{
		var value:Dynamic = writeData("ZRANGE " + key + " " + Std.string(start) + " " + Std.string(end) + ((withScores)? "WITHSCORES" : "") + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the specified elements of the sorted set at the specifiedkey. The elements are considered sorted from the lowerest to the highestscore when using ZRANGE, and in the reverse order when using ZREVRANGE.Start and end are zero-based indexes. 0 is the first elementof the sorted set (the one with the lowerest score when using ZRANGE), 1the next element by score and so on.
	 * _start_ and end can also be negative numbers indicating offsetsfrom the end of the sorted set. For example -1 is the last element ofthe sorted set, -2 the penultimate element and so on.
	 * Indexes out of range will not produce an error: if start is overthe end of the sorted set, or start > end, an empty list is returned.If end is over the end of the sorted set Redis will threat it just likethe last element of the sorted set.
	 * It's possible to pass the WITHSCORES option to the command in order to return notonly the values but also the scores of the elements. Redis will return the dataas a single list composed of value1,score1,value2,score2,...,valueN,scoreN but clientlibraries are free to return a more appropriate data type (what we think is thatthe best return type for this command is a Array of two-elements Array / Tuple inorder to preserve sorting).
	 * @param	key
	 * @param	start
	 * @param	end
	 * @return
	 */
	public function sortedSetsReverseRange(key:String, start:Int, end:Int, ?withScores:Bool = false):Array<Dynamic>
	{
		var value:Dynamic = writeData("ZREVRANGE " + key + " " + Std.string(start) + " " + Std.string(end) + ((withScores)? "WITHSCORES" : "") + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the all the elements in the sorted set at key with a score between_min_ and max (including elements with score equal to min or max).
	 * The elements having the same score are returned sorted lexicographically asASCII strings (this follows from a property of Redis sorted sets and does notinvolve further computation).
	 * Using the optional LIMIT it's possible to get only a range of the matchingelements in an SQL-alike way. Note that if offset is large the commandsneeds to traverse the list for offset elements and this adds up to theO(M) figure.
	 * @param	key
	 * @param	min
	 * @param	max
	 * @param	?offset
	 * @param	?count
	 * @return
	 */
	public function sortedSetsRangeByScore(key:String, min:Int, max:Int, ?offset:Int = 0, ?count:Int = 0):Array<Dynamic>
	{
		var value:Dynamic = writeData("ZRANGEBYSCORE " + key + " " + Std.string(min) + " " + Std.string(max) + ((count > 0)? "LIMIT " + Std.string(offset) + " " + Std.string(count) : "") + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the sorted set cardinality (number of elements). If the key does notexist 0 is returned, like for empty sorted sets.
	 * @param	key
	 * @return	Int	the number of elements in sorted sets.
	 */
	public function sortedSetsCount(key:String):Int
	{
		var value:Dynamic = writeData("ZCARD " + key + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Return the score of the specified element of the sorted set at key.If the specified element does not exist in the sorted set, or the keydoes not exist at all, a special 'nil' value is returned.
	 * @param	key
	 * @param	member
	 * @return	Int	the score
	 */
	public function sortedSetsScore(key:String, member:String):Int
	{
		var value:Dynamic = writeData("ZSCORE " + key + " " + Std.string(member.length) + EOL + member + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Remove all the elements in the sorted set at key with a score between_min_ and max (including elements with score equal to min or max).
	 * @param	key
	 * @param	min
	 * @param	max
	 * @return	Int	the number of elements removed
	 */
	public function sortedSetsRemoveRangeByScore(key:String, min:Int, max:Int):Int
	{
		var value:Dynamic = writeData("ZREMRANGEBYSCORE " + key + " " + Std.string(min) + " " + Std.string(max) + EOL);
		return Reflect.field(value, DATA);
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
	public function sort(key:String, ?byPattern:String = "", ?start:Int = 0, ?end:Int = 0, ?getPattern:String = "", ?isAscending:Bool = true, ?isAlpha:Bool = false, ?distKey:String = ""):Array<Dynamic>
	{
		var sb:StringBuf = new StringBuf();
		
		if (byPattern != "")
			sb.add(" BY " + byPattern);
		
		if (end > 0)
			sb.add(" LIMIT " + Std.string(start) + " " + Std.string(end));
		
		if (getPattern != "")
			sb.add(" GET " + getPattern);
		
		if (!isAscending)
			sb.add(" DESC");
		
		if (isAlpha)
			sb.add(" ALPHA");
		
		if (distKey != "")
			sb.add(" STORE " + distKey);
		
		var value:Dynamic = writeData("SORT " + key + sb.toString() + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Save the DB on disk. The server hangs while the saving is notcompleted, no connection is served in the meanwhile. An OK code is returned when the DB was fully stored in disk.
	 * @return
	 */
	public function save():Bool
	{
		var value:Dynamic = writeData("SAVE" + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Save the DB in background. The OK code is immediately returned.Redis forks, the parent continues to server the clients, the childsaves the DB on disk then exit. A client my be able to check if theoperation succeeded using the LASTSAVE command.
	 * @return
	 */
	public function backgroundSave():Bool
	{
		var value:Dynamic = writeData("BGSAVE" + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Return the UNIX TIME of the last DB save executed with success.A client may check if a BGSAVE command succeeded reading the LASTSAVEvalue, then issuing a BGSAVE command and checking at regular intervalsevery N seconds if LASTSAVE changed.
	 * @return
	 */
	public function lastSave():Int
	{
		var value:Dynamic = writeData("LASTSAVE" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * Stop all the clients, save the DB, then quit the server. This commandsmakes sure that the DB is switched off without the lost of any data.This is not guaranteed if the client uses simply "SAVE" and then"QUIT" because other clients may alter the DB data between the twocommands.
	 */
	public function shutdown():Void
	{
		var value:Dynamic = writeData("SHUTDOWN" + EOL);
		if (Reflect.hasField(value, DATA))
			throw "ERROR while shutdown: " + Reflect.field(value, DATA);
	}
	
	/**
	 * BGREWRITEAOF rewrites the Append Only File in background when it gets toobig. The Redis Append Only File is a Journal, so every operation modifyingthe dataset is logged in the Append Only File (and replayed at startup).This means that the Append Only File always grows. In order to rebuildits content the BGREWRITEAOF creates a new version of the append only filestarting directly form the dataset in memory in order to guarantee thegeneration of the minimal number of commands needed to rebuild the database.
	 * @return
	 */
	public function backgroundRewriteAppendOnlyFile():Bool
	{
		var value:Dynamic = writeData("BGREWRITEAOF" + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * The info command returns different information and statistics about the server in an format that's simple to parse by computers and easy to red by huamns.
	 * @return
	 */
	public function info():Array<Dynamic>
	{
		var value:Dynamic = writeData("INFO" + EOL);
		return Reflect.field(value, DATA);
	}
	
	/**
	 * The SLAVEOF command can change the replication settings of a slave on the fly.If a Redis server is arleady acting as slave, the command SLAVEOF NO ONEwill turn off the replicaiton turning the Redis server into a MASTER.In the proper form SLAVEOF hostname port will make the server a slave of thespecific server listening at the specified hostname and port.
	 * If a server is already a slave of some master, SLAVEOF hostname port willstop the replication against the old server and start the synchrnonizationagainst the new one discarding the old dataset.
	 * The form SLAVEOF no one will stop replication turning the server into aMASTER but will not discard the replication. So if the old master stop workingit is possible to turn the slave into a master and set the application touse the new master in read/write. Later when the other Redis server will befixed it can be configured in order to work as slave.
	 * @param	config
	 * @return
	 */
	public function slaveOf(config:SlaveConfig):Bool
	{
		var param:String;
		switch(config)
		{
			case THostPort(host, port):
				param = " " + host + " " + Std.string(port);
			
			case TNoOne:
				param = " no one";
		}
		var value:Dynamic = writeData("SLAVEOF" + param + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/**
	 * Ask the server to silently close the connection.
	 */
	public function quit():Void
	{
		writeData("QUIT" + EOL);
	}
	
	/**
	 * Request for authentication in a password protected Redis server.A Redis server can be instructed to require a password before to allow clientsto issue commands. This is done using the requirepass directive in theRedis configuration file.
	 * If the password given by the client is correct the server replies withan OK status code reply and starts accepting commands from the client.Otherwise an error is returned and the clients needs to try a new password.Note that for the high performance nature of Redis it is possible to trya lot of passwords in parallel in very short time, so make sure to generatea strong and very long password so that this attack is infeasible.
	 * @param	password
	 * @return
	 */
	public function auth(password:String):Bool
	{
		var value:Dynamic = writeData("AUTH " + password + EOL);
		return (Reflect.field(value, DATA) == OK)? true : false;
	}
	
	/*
	 * ===================================
	 * PRIVATES
	 * ===================================
	 */
	
	/**
	 * Basic write data to socket
	 * @param	value
	 * @return
	 */
	private function writeData(value:String):Dynamic
	{
		socket.output.writeString(value);
		return readData();
	}
	
	/**
	 * Basic read data from socket
	 * @return
	 */
	private function readData():Dynamic
	{
		var body:Dynamic = { };
		var array:Array<Dynamic> = [];
		var count:Int;
		
		var head:String = read();
		/* check for bulk response */
		if (head.indexOf("$") > -1)
		{
			count = Std.parseInt(head.substr(1));
			if (count > -1)
			{
				var data:String = "";
				do
				{
					data = read();
					array.push(data);
					count -= data.length;
					
					/* not sure if this is bullet-proof, but works for now */
					if (count <= 0 || (count > 0 && data.length == 0))
						break;
				}
				while (true);
				
				Reflect.setField(body, DATA, array);
			}
			else
			{
				Reflect.setField(body, DATA, TYPE_NONE);
			}
		}
		/* check for multi bulk response */
		else if (head.indexOf("*") > -1)
		{
			count = Std.parseInt(head.substr(1));
			if (count > -1)
			{
				array = [];
				for (i in 0...(count * 2))
				{
					var f:String = read();
					if(f.indexOf("$") == -1)
						array.push(f);
				}
				Reflect.setField(body, DATA, array);
			}
			else
			{
				Reflect.setField(body, DATA, TYPE_NONE);
			}
		}
		/* error response */
		else if (head.indexOf("-") > -1)
		{
			Reflect.setField(body, DATA, "[ERROR] " + head.substr(1));
		}
		/* string response */
		else if (head.indexOf("+") > -1)
		{
			Reflect.setField(body, DATA, head.substr(1));
		}
		/* int response */
		else if (head.indexOf(":") > -1)
		{
			Reflect.setField(body, DATA, Std.parseInt(head.substr(1)));
		}
		
		return body;
	}
	
	/**
	 * Primitive read from socket input.
	 * Finds the delimiter and return the results.
	 * @return
	 */
	private function read():String
	{
		var result:StringBuf = new StringBuf();
		do
		{
			var i:Int = socket.input.readByte();
			var c:String = String.fromCharCode(i);
			if (c == "\n")
				break;
			else
				if (c != "\r")
					result.add(c);
		}
		while (true);
		return result.toString();
	}
}

enum SlaveConfig
{
	THostPort(host:String, port:Int);
	TNoOne;
}