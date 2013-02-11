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
   * @author Ian Martins
   */

package redis;

import neko.net.Socket;
import neko.net.Host;
// TODO expire, expireat, ttl, sort
// skipped select, move, flushdb, flushall, save, auth, backgroundsave, lastsave, shutdown, info, slaveof

class TestRedis extends haxe.unit.TestCase
{
    // shared database object to use for all tests
    private var db : Redis;

    // connect and clear the db, use index 10 for tests
    override public function setup()
    {
        db = new Redis("localhost");
        db.select(10);
        db.flushdb();
    }

    // close connection
    override public function tearDown()
    {
        db.quit();
    }

    private function sorted(arr :Array<String>)
    {
        arr.sort(function(a,b) return (a<b) ? -1 : (b<a) ? 1 : 0);
        return arr;
    }

    // ------------------------ general

    public function testPing()
    {
        assertTrue(db.ping());
    }

    public function testDbSize()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertEquals(2, db.dbsize());
        assertTrue(db.set("key3", "val3"));
        assertEquals(3, db.dbsize());
    }  

    // ------------------------ keys

    public function testSetExistsGetDel()
    {
        assertFalse(db.exists("somekey"));
        assertTrue(db.set("somekey", "a value"));
        assertEquals("a value", db.get("somekey"));
        assertEquals(1, db.del(["somekey"]));
        assertFalse(db.exists("somekey"));
        assertEquals(null, db.get("somekey"));
    }

    public function testKeys()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.sadd("key2", ["val2"]));
        assertEquals(1, db.lpush("list", "val3"));
        assertEquals("[key1,key2]", Std.string(sorted(db.keys("*key*"))));
    }

    public function testRandomKey()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        var ret = db.randomkey();
        assertTrue(ret == "key1" || ret == "key2");
    }

    public function testRename()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertTrue(db.rename("key1", "key2"));
        assertEquals("val1", db.get("key2"));
    }  

    public function testRenameSafely()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertFalse(db.renamenx("key1", "key2"));
        assertTrue(db.renamenx("key1", "key3"));
        assertEquals("val2", db.get("key2"));
        assertEquals("val1", db.get("key3"));
    }  

    public function testType()
    {
        assertTrue(db.set("key", "val1"));
        assertTrue(db.sadd("set", ["val2"]));
        assertEquals(1, db.lpush("list", "val3"));
        assertEquals("string", db.type("key"));
        assertEquals("set", db.type("set"));
        assertEquals("list", db.type("list"));
    }

    // ------------------------ strings

    public function testAppend()
    {
        assertTrue(db.set("key1", "hello"));
        assertTrue(db.append("key1", " world"));
        assertEquals("hello world", db.get("key1"));
    }

    public function testDecrement()
    {
        assertTrue(db.set("key1", "10"));
        assertEquals(9, db.decr("key1"));
        assertEquals(8, db.decr("key1"));
    }

    public function testDecrementBy()
    {
        assertTrue(db.set("key1", "10"));
        assertEquals(8, db.decrby("key1", 2));
        assertEquals(5, db.decrby("key1", 3));
    }

    public function testBinarySetGet()
    {
        assertTrue(db.set("somekey", "a\r\nmultiline\r\nvalue"));
        assertEquals("a\r\nmultiline\r\nvalue", db.get("somekey"));
    }

    public function testGetRange()
    {
        assertTrue(db.set("key1", "some string"));
        assertEquals("string", db.getrange("key1", 5, -1));
    }

    public function testGetSet()
    {
        assertTrue(db.set("key1", "val1"));
        assertEquals("val1", db.getset("key1", "val2"));
        assertEquals("val2", db.get("key1"));
    }

    public function testIncrement()
    {
        assertTrue(db.set("key1", "1"));
        assertEquals(2, db.incr("key1"));
        assertEquals(3, db.incr("key1"));
    }

    public function testIncrementBy()
    {
        assertTrue(db.set("key1", "1"));
        assertEquals(3, db.incrby("key1", 2));
        assertEquals(6, db.incrby("key1", 3));
    }

    public function testIncrementByFloat()
    {
        assertTrue(db.set("key1", "1.2"));
        assertEquals(3.3, db.incrbyfloat("key1", 2.1));
        assertEquals(6.6, db.incrbyfloat("key1", 3.3));
    }

    public function testMultiGet()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertTrue(db.set("key3", "val3"));
        assertEquals("[val1,val2,val3]", Std.string(db.mget(["key1", "key2", "key3"])));
    }

    public function testMultiSet()
    {
        var fields = new Hash<String>();
        fields.set("key1", "val1");
        fields.set("key2", "val2");
        fields.set("key3", "val3");
        assertTrue(db.mset(fields));
        assertEquals("val1", db.get("key1"));
        assertEquals("val2", db.get("key2"));
        assertEquals("val3", db.get("key3"));
    }

    public function testMultiSetSafely()
    {
        assertTrue(db.set("key2", "value"));
        var fields = new Hash<String>();
        fields.set("key1", "val1");
        fields.set("key2", "val2");
        fields.set("key3", "val3");
        assertFalse(db.msetnx(fields));
        assertFalse(db.exists("key1"));
        assertEquals("value", db.get("key2"));
        assertFalse(db.exists("key3"));
    }

    public function testSet()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key1", "val2"));
        assertEquals("val2", db.get("key1"));
    }

    public function testSetSafely()
    {
        assertTrue(db.set("key1", "val1"));
        assertFalse(db.setnx("key1", "val2"));
        assertEquals("val1", db.get("key1"));
    }

    public function testSetRange()
    {
        assertTrue(db.set("key1", "car"));
        assertEquals(4, db.setrange("key1", 2, "se"));
        assertEquals("case", db.get("key1"));
    }

    public function testStrlen()
    {
        assertTrue(db.set("key1", "car"));
        assertTrue(db.set("key2", "boat"));
        assertEquals(3, db.strlen("key1"));
        assertEquals(4, db.strlen("key2"));
    }

    // ------------------------ hash

    public function testHashSetGet()
    {
        assertTrue(db.hset("key1", "field1", "val1"));
        assertEquals("val1", db.hget("key1", "field1"));
    }

    public function testHashSetSafely()
    {
        assertTrue(db.hsetnx("key1", "field1", "val1"));
        assertFalse(db.hsetnx("key1", "field1", "val2"));
        assertEquals("val1", db.hget("key1", "field1"));
    }

    public function testHashMultiSetGet()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        assertTrue(db.hmset("key1", fields));
        assertEquals("[val1,val2]", Std.string(db.hmget("key1", ["field1", "field2"])));
    }

    public function testHashIncrementBy()
    {
        assertTrue(db.hset("key1", "field1", "1"));
        assertEquals(3, db.hincrby("key1", "field1", 2));
        assertEquals("3", db.hget("key1", "field1"));
    }

    public function testHashIncrementByFloat()
    {
        assertTrue(db.hset("key1", "field1", "1.1"));
        assertEquals(3.2, db.hincrbyfloat("key1", "field1", 2.1));
        assertEquals("3.2", db.hget("key1", "field1"));
    }

    public function testHashExists()
    {
        assertTrue(db.hset("key1", "field1", "1"));
        assertTrue(db.hexists("key1", "field1"));
    }

    public function testHashDelete()
    {
        assertTrue(db.hset("key1", "field1", "1"));
        assertTrue(db.hexists("key1", "field1"));
        assertTrue(db.hdel("key1", "field1"));
        assertFalse(db.hexists("key1", "field1"));
    }

    public function testHashLength()
    {
        assertTrue(db.hset("key1", "field1", "1"));
        assertEquals(1, db.hlen("key1"));
        assertTrue(db.hset("key1", "field2", "2"));
        assertEquals(2, db.hlen("key1"));
        assertTrue(db.hdel("key1", "field1"));
        assertEquals(1, db.hlen("key1"));
    }

    public function testHashKeys()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hmset("key1", fields));
        assertEquals("[field2,field1,field3]", Std.string(db.hkeys("key1")));
    }

    public function testHashValues()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hmset("key1", fields));
        assertEquals("[val2,val1,val3]", Std.string(db.hvals("key1")));
    }

    public function testHashGetAll()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hmset("key1", fields));
        assertEquals("{field2 => val2, field1 => val1, field3 => val3}", Std.string(db.hgetall("key1")));
    }

    // ------------------------ lists

    public function testListsRightPushLengthRange()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals(3, db.llen("key1"));
        assertEquals("[1,2,3]", Std.string(db.lrange("key1", 0, 3)));
    }

    public function testListsLeftPushLengthRange()
    {
        assertEquals(1, db.lpush("key1", "1"));
        assertEquals(2, db.lpush("key1", "2"));
        assertEquals(3, db.lpush("key1", "3"));
        assertEquals(3, db.llen("key1"));
        assertEquals("[3,2,1]", Std.string(db.lrange("key1", 0, 3)));
    }

    public function testListsTrim()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertTrue(db.ltrim("key1", 1, 2));
        assertEquals(2, db.llen("key1"));
        assertEquals("[2,3]", Std.string(db.lrange("key1", 0, 1)));
    }

    public function testListsIndex()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals("1", db.lindex("key1", 0));
        assertEquals("2", db.lindex("key1", 1));
        assertEquals("3", db.lindex("key1", 2));
    }

    public function testListsSet()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertTrue(db.lset("key1", 1, "new"));
        assertEquals("[1,new,3]", Std.string(db.lrange("key1", 0, 2)));
    }

    public function testListsRemove()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals(1, db.lrem("key1", 1, "2"));
        assertEquals("[1,3]", Std.string(db.lrange("key1", 0, 1)));
    }


    public function testListsLeftPop()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals("1", db.lpop("key1"));
        assertEquals("[2,3]", Std.string(db.lrange("key1", 0, 1)));
    }

    public function testListsRightPop()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals("3", db.rpop("key1"));
        assertEquals("[1,2]", Std.string(db.lrange("key1", 0, 1)));
    }

    public function testListsRightPopLeftPush()
    {
        assertEquals(1, db.rpush("key1", "1"));
        assertEquals(2, db.rpush("key1", "2"));
        assertEquals(3, db.rpush("key1", "3"));
        assertEquals(1, db.rpush("key2", "a"));
        assertEquals(2, db.rpush("key2", "b"));
        assertEquals(3, db.rpush("key2", "c"));
        assertEquals("3", db.rpoplpush("key1", "key2"));
        assertEquals("[1,2]", Std.string(db.lrange("key1", 0, 1)));
        assertEquals("[3,a,b,c]", Std.string(db.lrange("key2", 0, 3)));
    }

    // ------------------------ sets

    public function testSetsAddCountMembers()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertFalse(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertEquals(2, db.scard("key1"));
        assertEquals("[val1,val2]", Std.string(sorted(db.smembers("key1"))));
    }

    public function testSetsRemove()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key1", ["val3"]));
        assertEquals(3, db.scard("key1"));
        assertTrue(db.srem("key1", "val2"));
        assertEquals(2, db.scard("key1"));
        assertEquals("[val1,val3]", Std.string(sorted(db.smembers("key1"))));
    }

    public function testSetsPop()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        var ret = db.spop("key1");
        assertTrue(ret == "val1" || ret == "val2");
        ret = db.spop("key1");
        assertTrue(ret == "val1" || ret == "val2");
        assertEquals(null, db.spop("key1"));
    }

    public function testSetsMove()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["vala"]));
        assertTrue(db.sadd("key2", ["valb"]));
        assertTrue(db.smove("key1", "key2", "val1"));
        assertEquals("[val2]", Std.string(sorted(db.smembers("key1"))));
        assertEquals("[val1,vala,valb]", Std.string(sorted(db.smembers("key2"))));
    }

    public function testSetsIsMember()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sismember("key1", "val1"));
        assertTrue(db.sismember("key1", "val2"));
        assertFalse(db.sismember("key1", "val3"));
    }

    public function testSetsIntersect()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertEquals("[val1]", Std.string(sorted(db.sinter(["key1", "key2"]))));
    }

    public function testSetsIntersectStore()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertTrue(db.sinterstore("key3", ["key1", "key2"]));
        assertEquals("[val1]", Std.string(sorted(db.smembers("key3"))));
    }

    public function testSetsUnion()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertEquals("[val1,val2,val3]", Std.string(sorted(db.sunion(["key1", "key2"]))));
    }

    public function testSetsUnionStore()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertTrue(db.sunionstore("key3", ["key1", "key2"]));
        assertEquals("[val1,val2,val3]", Std.string(sorted(db.smembers("key3"))));
    }

    public function testSetsDifference()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertEquals("[val2]", Std.string(sorted(db.sdiff(["key1", "key2"]))));
    }

    public function testSetsDifferenceStore()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        assertTrue(db.sadd("key2", ["val1"]));
        assertTrue(db.sadd("key2", ["val3"]));
        assertTrue(db.sdiffstore("key3", ["key1", "key2"]));
        assertEquals("[val2]", Std.string(sorted(db.smembers("key3"))));
    }

    public function testSetsRandomMember()
    {
        assertTrue(db.sadd("key1", ["val1"]));
        assertTrue(db.sadd("key1", ["val2"]));
        var ret = db.srandmember("key1");
        assertTrue(ret == "val1" || ret == "val2");
    }

    // sorted set

    public function testSortedSetsAddCard()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertEquals(3, db.zcard("key1"));
        assertEquals("[val1,val2,val3]", Std.string(db.zrange("key1", 0, 2)));
    }

    public function testSortedSetsAddCount()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertEquals(2, db.zcount("key1", "1", "2"));
    }

    public function testSortedSetsRemove()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertTrue(db.zrem("key1", "val1"));
        assertEquals(2, db.zcount("key1", "1", "3"));
        assertEquals("[val2,val3]", Std.string(db.zrange("key1", 0, 1)));
    }

    public function testSortedSetsIncrementBy()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertEquals(4.0, db.zincrby("key1", 3, "val1"));
        assertEquals("[val2,val3,val1]", Std.string(db.zrange("key1", 0, 2)));
    }

    public function testSortedSetsRank()
    {
        var members = new Hash<Float>();
        members.set("val2", 1.2);
        members.set("val1", 1.1);
        members.set("val3", 1.3);
        assertTrue(db.zadd("key1", members));
        assertEquals(0, db.zrank("key1", "val1"));
        assertEquals(1, db.zrank("key1", "val2"));
        assertEquals(2, db.zrank("key1", "val3"));
    }

    public function testSortedSetsRevRank()
    {
        var members = new Hash<Float>();
        members.set("val2", 1.2);
        members.set("val1", 1.1);
        members.set("val3", 1.3);
        assertTrue(db.zadd("key1", members));
        assertEquals(2, db.zrevrank("key1", "val1"));
        assertEquals(1, db.zrevrank("key1", "val2"));
        assertEquals(0, db.zrevrank("key1", "val3"));
    }

    public function testSortedSetsReverseRange()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertEquals("[val3,val2,val1]", Std.string(db.zrevrange("key1", 0, 2)));
    }

    public function testSortedSetsRangeByScore()
    {
        var members = new Hash<Float>();
        members.set("val2", 2.1);
        members.set("val1", 1.2);
        members.set("val3", 3.3);
        assertTrue(db.zadd("key1", members));
        assertEquals("[val2,val3]", Std.string(db.zrangebyscore("key1", "2", "4")));
    }

    public function testSortedSetsScore()
    {
        var members = new Hash<Float>();
        members.set("val2", 2.1);
        members.set("val1", 1.1);
        members.set("val3", 3.1);
        assertTrue(db.zadd("key1", members));
        assertEquals(1.1, db.zscore("key1", "val1"));
        assertEquals(2.1, db.zscore("key1", "val2"));
        assertEquals(3.1, db.zscore("key1", "val3"));
    }

    public function testSortedSetsRemoveRangeByRank()
    {
        var members = new Hash<Float>();
        members.set("val2", 2.1);
        members.set("val1", 1.1);
        members.set("val5", 3.2);
        members.set("val3", 3.0);
        members.set("val4", 3.1);
        assertTrue(db.zadd("key1", members));
        assertEquals(3, db.zremrangebyrank("key1", 1, 3));
        assertEquals("[val1,val5]", Std.string(db.zrange("key1", 0, -1)));
    }

    public function testSortedSetsRemoveByScore()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        assertEquals(2, db.zremrangebyscore("key1", "2", "3"));
        assertEquals("[val1]", Std.string(db.zrange("key1", 0, 1)));
    }

    public function testSortedSetsUnionStore()
    {
        var members = new Hash<Float>();
        members.set("val2a", 2);
        members.set("val1a", 1);
        members.set("val3a", 3);
        assertTrue(db.zadd("key1", members));
        members = new Hash<Float>();
        members.set("val2b", 5);
        members.set("val1b", 4);
        members.set("val3b", 6);
        assertTrue(db.zadd("key2", members));
        assertEquals(6, db.zunionstore("result", ["key1", "key2"]));
        assertEquals("[val1a,val2a,val3a,val1b,val2b,val3b]", Std.string(db.zrange("result", 0, -1)));
    }

    public function testSortedSetsUnionStoreAggMax()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        members = new Hash<Float>();
        members.set("val2", 5);
        members.set("val1", 4);
        members.set("val3", 6);
        assertTrue(db.zadd("key2", members));
        assertEquals(3, db.zunionstore("result", ["key1", "key2"], null, "max"));
        assertEquals("[val1,val2,val3]", Std.string(db.zrange("result", 0, -1)));
    }

    public function testSortedSetsIntersectStore()
    {
        var members = new Hash<Float>();
        members.set("val2", 2);
        members.set("val1", 1);
        members.set("val3", 3);
        assertTrue(db.zadd("key1", members));
        members = new Hash<Float>();
        members.set("val3", 5);
        members.set("val2", 4);
        members.set("val4", 6);
        assertTrue(db.zadd("key2", members));
        assertEquals(2, db.zinterstore("result", ["key1", "key2"]));
        assertEquals("[val2,val3]", Std.string(db.zrange("result", 0, -1)));
    }

    // sort

    public function testSortWordsFwdRev()
    {
        assertEquals(1, db.lpush("key1", "val2"));
        assertEquals(2, db.lpush("key1", "val1"));
        assertEquals(3, db.lpush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.lrange("key1", 0, -1)));
        assertEquals("[val1,val2,val3]", Std.string(db.sort("key1", null, null, null, null, null, true)));
        assertEquals("[val3,val2,val1]", Std.string(db.sort("key1", null, null, null, null, false, true)));
    }

    public function testSortNums()
    {
        assertEquals(1, db.lpush("key1", "1.23"));
        assertEquals(2, db.lpush("key1", "1.01"));
        assertEquals(3, db.lpush("key1", "2.11"));
        assertEquals("[2.11,1.01,1.23]", Std.string(db.lrange("key1", 0, -1)));
        assertEquals("[2.11,1.23,1.01]", Std.string(db.sort("key1", null, null, null, null, false, false)));
    }

    public function testSortLimit()
    {
        assertEquals(1, db.lpush("key1", "val2"));
        assertEquals(2, db.lpush("key1", "val1"));
        assertEquals(3, db.lpush("key1", "val5"));
        assertEquals(4, db.lpush("key1", "val3"));
        assertEquals("[val3,val5,val1,val2]", Std.string(db.lrange("key1", 0, -1)));
        assertEquals("[val2,val3]", Std.string(db.sort("key1", null, 1, 2, null, null, true)));
    }

    public function testSortByExternalKeys()
    {
        assertTrue(db.set("w_val1", "1"));
        assertTrue(db.set("w_val2", "2"));
        assertTrue(db.set("w_val3", "3"));
        assertEquals(1, db.lpush("key1", "val2"));
        assertEquals(2, db.lpush("key1", "val1"));
        assertEquals(3, db.lpush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.lrange("key1", 0, -1)));
        assertEquals("[val1,val2,val3]", Std.string(db.sort("key1", "w_*", null, null, null, null, true)));
    }

    public function testSortStore()
    {
        assertEquals(1, db.lpush("key1", "val2"));
        assertEquals(2, db.lpush("key1", "val1"));
        assertEquals(3, db.lpush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.lrange("key1", 0, -1)));
        assertEquals(3, db.sort("key1", null, null, null, null, null, true, "key2"));
        assertEquals("[val1,val2,val3]", Std.string(db.lrange("key2", 0, -1)));
    }
}
